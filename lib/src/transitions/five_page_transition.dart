import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../enums/page_type.dart';
import '../enums/swipe_direction.dart';

/// Describes one frame of a running page transition.
///
/// Every transition is modelled the same way, whether a side page is being
/// opened or the user is returning to the center page: the *outgoing* page
/// moves away in [direction] while the *incoming* page arrives from the
/// opposite side.
@immutable
class FivePageTransitionDetails {
  /// Creates the description of a transition frame.
  const FivePageTransitionDetails({
    required this.progress,
    required this.direction,
    required this.size,
    required this.from,
    required this.to,
  });

  /// Linear progress of the transition, from `0.0` (only the outgoing page is
  /// visible) to `1.0` (only the incoming page is visible).
  ///
  /// While the user drags, this follows the finger exactly. When the
  /// transition settles, the navigator's `transitionCurve` is applied, so
  /// transitions should not apply another curve to the whole range.
  final double progress;

  /// The direction the content moves in.
  final SwipeDirection direction;

  /// The size of the navigator.
  final Size size;

  /// The page that was active when the transition started (outgoing page).
  final PageType from;

  /// The page the transition is heading to (incoming page).
  final PageType to;

  /// Unit vector of [direction]. The outgoing page moves along this vector,
  /// the incoming page arrives from its opposite.
  Offset get vector => direction.vector;

  /// The width for horizontal transitions, the height for vertical ones.
  double get extent =>
      direction.axis == Axis.horizontal ? size.width : size.height;

  /// Whether the transition returns to the center page.
  bool get isReturning => to == PageType.center;
}

/// Signature used by [FivePageCustomTransition] to wrap a page.
typedef FivePageTransitionWidgetBuilder = Widget Function(
  BuildContext context,
  FivePageTransitionDetails details,
  Widget child,
);

/// Defines how pages animate in a `FivePageNavigator`.
///
/// Use one of the factory constructors, for example
/// `FivePageTransition.cube()`, or extend this class to create your own.
///
/// Implementations must return a widget tree whose *shape* (the widget types
/// and their nesting) does not depend on [FivePageTransitionDetails.progress].
/// Only the values passed to those widgets should change from frame to frame,
/// so the pages are never rebuilt during an animation.
@immutable
abstract class FivePageTransition {
  /// Allows subclasses to have const constructors.
  const FivePageTransition();

  /// Both pages slide together, like a horizontal or vertical `PageView`.
  ///
  /// Optionally fades the incoming page in from [incomingOpacityStart] and
  /// the outgoing page out to [outgoingOpacityEnd].
  const factory FivePageTransition.slide({
    double incomingOpacityStart,
    double outgoingOpacityEnd,
  }) = FivePageSlideTransition;

  /// The incoming page slides over the outgoing page, which moves a fraction
  /// of the distance and dims (iOS-style navigation).
  const factory FivePageTransition.parallax({
    double parallaxFactor,
    double dimOpacity,
    bool showShadow,
  }) = FivePageParallaxTransition;

  /// The incoming page slides over the outgoing page, which stays in place
  /// and dims.
  const factory FivePageTransition.cover({
    double dimOpacity,
    double outgoingScale,
    double borderRadius,
    bool showShadow,
  }) = FivePageCoverTransition;

  /// Like [FivePageTransition.cover], but the outgoing page shrinks and gets
  /// rounded corners, creating a sense of depth.
  const factory FivePageTransition.depth({
    double dimOpacity,
    double outgoingScale,
    double borderRadius,
    bool showShadow,
  }) = FivePageDepthTransition;

  /// The outgoing page slides away and uncovers the incoming page, which
  /// waits underneath.
  const factory FivePageTransition.reveal({
    double dimOpacity,
    double incomingScale,
    bool showShadow,
  }) = FivePageRevealTransition;

  /// The pages cross-fade.
  const factory FivePageTransition.fade() = FivePageFadeTransition;

  /// The Material "fade through" pattern: the outgoing page fades out, then
  /// the incoming page fades and scales in.
  const factory FivePageTransition.fadeThrough({double incomingScaleStart}) =
      FivePageFadeThroughTransition;

  /// The Material "shared axis" pattern: pages fade while sliding a short
  /// distance along the swipe axis.
  const factory FivePageTransition.sharedAxis({double slideDistance}) =
      FivePageSharedAxisTransition;

  /// The incoming page zooms in while the outgoing page zooms out and fades.
  const factory FivePageTransition.zoom({
    double incomingScaleStart,
    double outgoingScaleEnd,
  }) = FivePageZoomTransition;

  /// The incoming page grows from the edge it comes from.
  const factory FivePageTransition.scale({
    double scaleStart,
    double dimOpacity,
  }) = FivePageScaleTransition;

  /// The pages are two faces of a rotating 3D cube.
  const factory FivePageTransition.cube({double perspective}) =
      FivePageCubeTransition;

  /// The pages are the two sides of a card flipping over.
  const factory FivePageTransition.flip({double perspective}) =
      FivePageFlipTransition;

  /// The pages swing in and out around a pivot, like a wheel.
  const factory FivePageTransition.rotate({double angle}) =
      FivePageRotateTransition;

  /// No animation: pages switch instantly.
  const factory FivePageTransition.none() = FivePageNoTransition;

  /// Builds the transition from two callbacks.
  const factory FivePageTransition.custom({
    required FivePageTransitionWidgetBuilder incomingBuilder,
    required FivePageTransitionWidgetBuilder outgoingBuilder,
    bool incomingOnTop,
  }) = FivePageCustomTransition;

  /// Whether the incoming page is painted above the outgoing page.
  bool get incomingOnTop => true;

  /// Wraps the page that is leaving the screen.
  Widget buildOutgoing(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  );

  /// Wraps the page that is entering the screen.
  Widget buildIncoming(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  );
}

// --- Helpers ---------------------------------------------------------------

/// Maps [t] from the `[begin, end]` interval onto `[0, 1]`.
double _interval(double t, double begin, double end) =>
    ((t - begin) / (end - begin)).clamp(0.0, 1.0);

double _lerp(double a, double b, double t) => lerpDouble(a, b, t)!;

Widget _opacity(double opacity, Widget child) =>
    Opacity(opacity: opacity.clamp(0.0, 1.0), child: child);

/// Draws a translucent black layer above [child].
Widget _dim(double amount, Widget child) => DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        color: Color.fromRGBO(0, 0, 0, amount.clamp(0.0, 1.0)),
      ),
      child: child,
    );

const List<BoxShadow> _kPageShadow = <BoxShadow>[
  BoxShadow(color: Color(0x33000000), blurRadius: 24, spreadRadius: 2),
];

Widget _shadow(bool enabled, Widget child) => DecoratedBox(
      decoration: BoxDecoration(boxShadow: enabled ? _kPageShadow : null),
      child: child,
    );

/// The alignment of the edge the incoming page enters from.
Alignment _entryEdge(Offset vector) => Alignment(-vector.dx, -vector.dy);

/// The alignment of the edge the outgoing page leaves through.
Alignment _exitEdge(Offset vector) => Alignment(vector.dx, vector.dy);

// --- Built-in transitions --------------------------------------------------

/// Both pages slide together. See [FivePageTransition.slide].
class FivePageSlideTransition extends FivePageTransition {
  /// Creates a slide transition.
  const FivePageSlideTransition({
    this.incomingOpacityStart = 1.0,
    this.outgoingOpacityEnd = 1.0,
  })  : assert(incomingOpacityStart >= 0 && incomingOpacityStart <= 1),
        assert(outgoingOpacityEnd >= 0 && outgoingOpacityEnd <= 1);

  /// Opacity of the incoming page when the transition starts.
  final double incomingOpacityStart;

  /// Opacity of the outgoing page when the transition ends.
  final double outgoingOpacityEnd;

  @override
  Widget buildOutgoing(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = details.progress;
    return FractionalTranslation(
      translation: details.vector * t,
      child: _opacity(_lerp(1, outgoingOpacityEnd, t), child),
    );
  }

  @override
  Widget buildIncoming(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = details.progress;
    return FractionalTranslation(
      translation: -details.vector * (1 - t),
      child: _opacity(_lerp(incomingOpacityStart, 1, t), child),
    );
  }
}

/// iOS-style parallax slide. See [FivePageTransition.parallax].
class FivePageParallaxTransition extends FivePageTransition {
  /// Creates a parallax transition.
  const FivePageParallaxTransition({
    this.parallaxFactor = 0.3,
    this.dimOpacity = 0.2,
    this.showShadow = true,
  })  : assert(parallaxFactor >= 0 && parallaxFactor <= 1),
        assert(dimOpacity >= 0 && dimOpacity <= 1);

  /// How far the outgoing page moves, relative to the incoming page.
  final double parallaxFactor;

  /// How dark the outgoing page gets at the end of the transition.
  final double dimOpacity;

  /// Whether the incoming page casts a shadow on the outgoing page.
  final bool showShadow;

  @override
  Widget buildOutgoing(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = details.progress;
    return FractionalTranslation(
      translation: details.vector * (t * parallaxFactor),
      child: _dim(t * dimOpacity, child),
    );
  }

  @override
  Widget buildIncoming(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    return FractionalTranslation(
      translation: -details.vector * (1 - details.progress),
      child: _shadow(showShadow, child),
    );
  }
}

/// The incoming page covers the outgoing one. See [FivePageTransition.cover].
class FivePageCoverTransition extends FivePageTransition {
  /// Creates a cover transition.
  const FivePageCoverTransition({
    this.dimOpacity = 0.3,
    this.outgoingScale = 1.0,
    this.borderRadius = 0.0,
    this.showShadow = true,
  })  : assert(dimOpacity >= 0 && dimOpacity <= 1),
        assert(outgoingScale > 0),
        assert(borderRadius >= 0);

  /// How dark the outgoing page gets at the end of the transition.
  final double dimOpacity;

  /// Scale of the outgoing page at the end of the transition.
  final double outgoingScale;

  /// Corner radius of the outgoing page at the end of the transition.
  final double borderRadius;

  /// Whether the incoming page casts a shadow on the outgoing page.
  final bool showShadow;

  @override
  Widget buildOutgoing(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = details.progress;
    return Transform.scale(
      scale: _lerp(1, outgoingScale, t),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius * t),
        clipBehavior: borderRadius > 0 ? Clip.antiAlias : Clip.none,
        child: _dim(t * dimOpacity, child),
      ),
    );
  }

  @override
  Widget buildIncoming(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    return FractionalTranslation(
      translation: -details.vector * (1 - details.progress),
      child: _shadow(showShadow, child),
    );
  }
}

/// A cover transition that pushes the outgoing page into the background.
/// See [FivePageTransition.depth].
class FivePageDepthTransition extends FivePageCoverTransition {
  /// Creates a depth transition.
  const FivePageDepthTransition({
    super.dimOpacity = 0.4,
    super.outgoingScale = 0.88,
    super.borderRadius = 28.0,
    super.showShadow = true,
  });
}

/// The outgoing page uncovers the incoming page.
/// See [FivePageTransition.reveal].
class FivePageRevealTransition extends FivePageTransition {
  /// Creates a reveal transition.
  const FivePageRevealTransition({
    this.dimOpacity = 0.3,
    this.incomingScale = 0.95,
    this.showShadow = true,
  })  : assert(dimOpacity >= 0 && dimOpacity <= 1),
        assert(incomingScale > 0);

  /// How dark the incoming page is when the transition starts.
  final double dimOpacity;

  /// Scale of the incoming page when the transition starts.
  final double incomingScale;

  /// Whether the outgoing page casts a shadow on the incoming page.
  final bool showShadow;

  @override
  bool get incomingOnTop => false;

  @override
  Widget buildOutgoing(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    return FractionalTranslation(
      translation: details.vector * details.progress,
      child: _shadow(showShadow, child),
    );
  }

  @override
  Widget buildIncoming(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = details.progress;
    return Transform.scale(
      scale: _lerp(incomingScale, 1, t),
      child: _dim((1 - t) * dimOpacity, child),
    );
  }
}

/// Cross-fades the pages. See [FivePageTransition.fade].
class FivePageFadeTransition extends FivePageTransition {
  /// Creates a fade transition.
  const FivePageFadeTransition();

  @override
  Widget buildOutgoing(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) =>
      _opacity(1 - details.progress, child);

  @override
  Widget buildIncoming(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) =>
      _opacity(details.progress, child);
}

/// Material fade through. See [FivePageTransition.fadeThrough].
class FivePageFadeThroughTransition extends FivePageTransition {
  /// Creates a fade through transition.
  const FivePageFadeThroughTransition({this.incomingScaleStart = 0.92})
      : assert(incomingScaleStart > 0);

  /// Scale of the incoming page when it starts fading in.
  final double incomingScaleStart;

  static const double _split = 0.35;

  @override
  Widget buildOutgoing(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) =>
      _opacity(1 - _interval(details.progress, 0, _split), child);

  @override
  Widget buildIncoming(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = _interval(details.progress, _split, 1);
    return Transform.scale(
      scale: _lerp(incomingScaleStart, 1, Curves.easeOut.transform(t)),
      child: _opacity(t, child),
    );
  }
}

/// Material shared axis. See [FivePageTransition.sharedAxis].
class FivePageSharedAxisTransition extends FivePageTransition {
  /// Creates a shared axis transition.
  const FivePageSharedAxisTransition({this.slideDistance = 30.0})
      : assert(slideDistance >= 0);

  /// How far, in logical pixels, each page slides.
  final double slideDistance;

  static const double _split = 0.3;

  @override
  Widget buildOutgoing(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = details.progress;
    return Transform.translate(
      offset: details.vector * (slideDistance * t),
      child: _opacity(1 - _interval(t, 0, _split), child),
    );
  }

  @override
  Widget buildIncoming(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = details.progress;
    return Transform.translate(
      offset: -details.vector * (slideDistance * (1 - t)),
      child: _opacity(_interval(t, _split, 1), child),
    );
  }
}

/// Zooms the pages. See [FivePageTransition.zoom].
class FivePageZoomTransition extends FivePageTransition {
  /// Creates a zoom transition.
  const FivePageZoomTransition({
    this.incomingScaleStart = 0.85,
    this.outgoingScaleEnd = 1.1,
  })  : assert(incomingScaleStart > 0),
        assert(outgoingScaleEnd > 0);

  /// Scale of the incoming page when the transition starts.
  final double incomingScaleStart;

  /// Scale of the outgoing page when the transition ends.
  final double outgoingScaleEnd;

  @override
  Widget buildOutgoing(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = details.progress;
    return Transform.scale(
      scale: _lerp(1, outgoingScaleEnd, t),
      child: _opacity(1 - _interval(t, 0, 0.6), child),
    );
  }

  @override
  Widget buildIncoming(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = details.progress;
    return Transform.scale(
      scale: _lerp(incomingScaleStart, 1, t),
      child: _opacity(_interval(t, 0, 0.6), child),
    );
  }
}

/// Grows the incoming page from its edge. See [FivePageTransition.scale].
class FivePageScaleTransition extends FivePageTransition {
  /// Creates a scale transition.
  const FivePageScaleTransition({
    this.scaleStart = 0.0,
    this.dimOpacity = 0.3,
  })  : assert(scaleStart >= 0 && scaleStart < 1),
        assert(dimOpacity >= 0 && dimOpacity <= 1);

  /// Scale of the incoming page when the transition starts.
  final double scaleStart;

  /// How dark the outgoing page gets at the end of the transition.
  final double dimOpacity;

  @override
  Widget buildOutgoing(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) =>
      _dim(details.progress * dimOpacity, child);

  @override
  Widget buildIncoming(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = details.progress;
    return Transform.scale(
      scale: _lerp(scaleStart, 1, t),
      alignment: _entryEdge(details.vector),
      child: _opacity(_interval(t, 0, 0.3), child),
    );
  }
}

/// Builds a perspective matrix rotated around the axis perpendicular to the
/// swipe direction.
Matrix4 _rotation(
  FivePageTransitionDetails details,
  double angle,
  double perspective,
) {
  final extent = details.extent;
  final matrix = Matrix4.identity()
    ..setEntry(3, 2, extent > 0 ? perspective / extent : 0.0);
  final axis = details.direction.axis;
  return axis == Axis.horizontal
      ? (matrix..rotateY(angle))
      : (matrix..rotateX(angle));
}

/// 3D cube rotation. See [FivePageTransition.cube].
class FivePageCubeTransition extends FivePageTransition {
  /// Creates a cube transition.
  const FivePageCubeTransition({this.perspective = 0.5})
      : assert(perspective >= 0);

  /// Strength of the perspective effect, relative to the page size.
  ///
  /// `0` disables perspective; `0.5` matches a camera placed two page widths
  /// away from the screen.
  final double perspective;

  @override
  Widget buildOutgoing(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = details.progress;
    final v = details.vector;
    final axis = details.direction.axis;
    // Rotate away from the viewer around the edge shared with the incoming
    // page; the sign keeps the far edge receding into the screen.
    final angle = axis == Axis.horizontal
        ? -v.dx * t * math.pi / 2
        : v.dy * t * math.pi / 2;
    return FractionalTranslation(
      translation: v * t,
      child: Transform(
        alignment: _entryEdge(v),
        transform: _rotation(details, angle, perspective),
        child: child,
      ),
    );
  }

  @override
  Widget buildIncoming(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = details.progress;
    final v = details.vector;
    final axis = details.direction.axis;
    final angle = axis == Axis.horizontal
        ? v.dx * (1 - t) * math.pi / 2
        : -v.dy * (1 - t) * math.pi / 2;
    return FractionalTranslation(
      translation: -v * (1 - t),
      child: Transform(
        alignment: _exitEdge(v),
        transform: _rotation(details, angle, perspective),
        child: child,
      ),
    );
  }
}

/// Card flip. See [FivePageTransition.flip].
class FivePageFlipTransition extends FivePageTransition {
  /// Creates a flip transition.
  const FivePageFlipTransition({this.perspective = 0.5})
      : assert(perspective >= 0);

  /// Strength of the perspective effect, relative to the page size.
  final double perspective;

  @override
  Widget buildOutgoing(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = details.progress;
    final v = details.vector;
    final axis = details.direction.axis;
    final turn = math.min(t, 0.5) * math.pi;
    final angle = axis == Axis.horizontal ? v.dx * turn : -v.dy * turn;
    return Opacity(
      opacity: t < 0.5 ? 1 : 0,
      child: Transform(
        alignment: Alignment.center,
        transform: _rotation(details, angle, perspective),
        child: child,
      ),
    );
  }

  @override
  Widget buildIncoming(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = details.progress;
    final v = details.vector;
    final axis = details.direction.axis;
    final turn = math.min(1 - t, 0.5) * math.pi;
    final angle = axis == Axis.horizontal ? -v.dx * turn : v.dy * turn;
    return Opacity(
      opacity: t < 0.5 ? 0 : 1,
      child: Transform(
        alignment: Alignment.center,
        transform: _rotation(details, angle, perspective),
        child: child,
      ),
    );
  }
}

/// Swinging rotation. See [FivePageTransition.rotate].
class FivePageRotateTransition extends FivePageTransition {
  /// Creates a rotate transition.
  const FivePageRotateTransition({this.angle = 0.3});

  /// The rotation, in radians, of a page that is fully off screen.
  final double angle;

  Alignment _pivot(FivePageTransitionDetails details) =>
      details.direction.axis == Axis.horizontal
          ? Alignment.bottomCenter
          : Alignment.centerLeft;

  double _sign(FivePageTransitionDetails details) =>
      details.direction.axis == Axis.horizontal
          ? details.vector.dx
          : -details.vector.dy;

  @override
  Widget buildOutgoing(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = details.progress;
    return FractionalTranslation(
      translation: details.vector * t,
      child: Transform.rotate(
        angle: _sign(details) * t * angle,
        alignment: _pivot(details),
        child: child,
      ),
    );
  }

  @override
  Widget buildIncoming(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) {
    final t = details.progress;
    return FractionalTranslation(
      translation: -details.vector * (1 - t),
      child: Transform.rotate(
        angle: -_sign(details) * (1 - t) * angle,
        alignment: _pivot(details),
        child: child,
      ),
    );
  }
}

/// Switches pages without animation. See [FivePageTransition.none].
///
/// While the user drags, the incoming page appears once the drag passes the
/// half-way point.
class FivePageNoTransition extends FivePageTransition {
  /// Creates a transition without animation.
  const FivePageNoTransition();

  @override
  Widget buildOutgoing(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) =>
      Opacity(opacity: details.progress < 0.5 ? 1 : 0, child: child);

  @override
  Widget buildIncoming(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) =>
      Opacity(opacity: details.progress < 0.5 ? 0 : 1, child: child);
}

/// A transition defined by two builder callbacks.
/// See [FivePageTransition.custom].
class FivePageCustomTransition extends FivePageTransition {
  /// Creates a custom transition.
  const FivePageCustomTransition({
    required this.incomingBuilder,
    required this.outgoingBuilder,
    this.incomingOnTop = true,
  });

  /// Wraps the incoming page.
  final FivePageTransitionWidgetBuilder incomingBuilder;

  /// Wraps the outgoing page.
  final FivePageTransitionWidgetBuilder outgoingBuilder;

  @override
  final bool incomingOnTop;

  @override
  Widget buildIncoming(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) =>
      incomingBuilder(context, details, child);

  @override
  Widget buildOutgoing(
    BuildContext context,
    FivePageTransitionDetails details,
    Widget child,
  ) =>
      outgoingBuilder(context, details, child);
}
