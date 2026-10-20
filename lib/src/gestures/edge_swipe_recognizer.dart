import 'package:flutter/foundation.dart' show ValueChanged, VoidCallback;
import 'package:flutter/gestures.dart';

import '../enums/swipe_direction.dart';

/// Returns the directions a drag that starts at `localPosition` may move in.
/// An empty set means the pointer is ignored.
typedef EdgeSwipeDirectionsResolver = Set<SwipeDirection> Function(
  Offset localPosition,
);

/// Recognizes a drag that starts inside an edge zone and moves in one of the
/// directions allowed for that zone.
///
/// Unlike a pan recognizer, it only joins the gesture arena for pointers that
/// land inside a zone, and it gives up as soon as the drag heads in a
/// direction that is not allowed. Scrollables and buttons inside the pages
/// therefore keep working everywhere else.
class EdgeSwipeGestureRecognizer extends OneSequenceGestureRecognizer {
  /// Creates an edge swipe recognizer.
  EdgeSwipeGestureRecognizer({
    super.debugOwner,
    super.supportedDevices,
  });

  /// Decides which directions are allowed for a new pointer.
  EdgeSwipeDirectionsResolver? resolveDirections;

  /// Called when the drag is accepted. Returning `false` cancels it.
  bool Function(SwipeDirection direction)? onStart;

  /// Called with the local delta of each pointer move after [onStart].
  ValueChanged<Offset>? onUpdate;

  /// Called when the pointer is lifted after [onStart].
  ValueChanged<Velocity>? onEnd;

  /// Called when the pointer is cancelled after [onStart].
  VoidCallback? onCancel;

  /// When `true`, the recognizer claims the drag after half the usual touch
  /// slop, so it wins against scrollables inside the edge zone. When `false`,
  /// it waits for twice the touch slop, so scrollables along the same axis
  /// win instead.
  bool prioritize = true;

  int? _pointer;
  Set<SwipeDirection> _allowed = const <SwipeDirection>{};
  Offset _pendingDelta = Offset.zero;
  bool _wonArena = false;
  bool _started = false;
  PointerDeviceKind _kind = PointerDeviceKind.touch;
  VelocityTracker? _velocityTracker;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    if (_pointer != null || resolveDirections == null) return false;
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons != kPrimaryMouseButton) {
      return false;
    }
    if (!super.isPointerAllowed(event)) return false;
    _allowed = resolveDirections!(event.localPosition);
    return _allowed.isNotEmpty;
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _pointer = event.pointer;
    _kind = event.kind;
    _pendingDelta = Offset.zero;
    _wonArena = false;
    _started = false;
    _velocityTracker = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.localPosition);
  }

  double get _slop {
    final slop = computeHitSlop(_kind, gestureSettings);
    return prioritize ? slop / 2 : slop * 2;
  }

  SwipeDirection _dominantDirection(Offset delta) {
    if (delta.dx.abs() > delta.dy.abs()) {
      return delta.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
    }
    return delta.dy > 0 ? SwipeDirection.down : SwipeDirection.up;
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;

    if (event is PointerMoveEvent) {
      _velocityTracker?.addPosition(event.timeStamp, event.localPosition);
      if (_started) {
        onUpdate?.call(event.localDelta);
        return;
      }
      _pendingDelta += event.localDelta;
      if (_pendingDelta.distance <= _slop) return;

      if (_allowed.contains(_dominantDirection(_pendingDelta))) {
        if (_wonArena) {
          _start();
        } else {
          // Accepting synchronously calls [acceptGesture], which starts the
          // drag.
          resolve(GestureDisposition.accepted);
        }
      } else {
        _giveUp();
      }
    } else if (event is PointerUpEvent) {
      if (_started) {
        final velocity = _velocityTracker?.getVelocity() ?? Velocity.zero;
        onEnd?.call(velocity);
      }
      _giveUp();
    } else if (event is PointerCancelEvent) {
      if (_started) onCancel?.call();
      _giveUp();
    }
  }

  void _start() {
    if (_started) return;
    final accepted = onStart?.call(_dominantDirection(_pendingDelta)) ?? false;
    if (!accepted) {
      _giveUp();
      return;
    }
    _started = true;
    // Apply the distance travelled while the slop was being crossed so the
    // page stays under the finger.
    onUpdate?.call(_pendingDelta);
  }

  void _giveUp() {
    final pointer = _pointer;
    if (pointer == null) return;
    if (!_wonArena) resolve(GestureDisposition.rejected);
    stopTrackingPointer(pointer);
  }

  @override
  void acceptGesture(int pointer) {
    if (pointer != _pointer) return;
    _wonArena = true;
    // The arena may also hand us the pointer because every other member gave
    // up; in that case wait until the drag actually crosses the slop.
    if (_pendingDelta.distance > _slop &&
        _allowed.contains(_dominantDirection(_pendingDelta))) {
      _start();
    }
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer != _pointer) return;
    if (_started) onCancel?.call();
    _started = false;
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointer = null;
    _allowed = const <SwipeDirection>{};
    _pendingDelta = Offset.zero;
    _wonArena = false;
    _started = false;
    _velocityTracker = null;
  }

  @override
  String get debugDescription => 'edge swipe';
}
