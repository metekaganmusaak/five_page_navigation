import 'package:flutter/widgets.dart' show Axis, Offset;

/// The direction of a swipe gesture, i.e. the direction the finger and the
/// page content move.
enum SwipeDirection {
  /// Content moves to the left (reveals the right page).
  left,

  /// Content moves to the right (reveals the left page).
  right,

  /// Content moves up (reveals the bottom page).
  up,

  /// Content moves down (reveals the top page).
  down;

  /// The axis this direction lies on.
  Axis get axis => switch (this) {
        SwipeDirection.left || SwipeDirection.right => Axis.horizontal,
        SwipeDirection.up || SwipeDirection.down => Axis.vertical,
      };

  /// The direction pointing the other way on the same axis.
  SwipeDirection get opposite => switch (this) {
        SwipeDirection.left => SwipeDirection.right,
        SwipeDirection.right => SwipeDirection.left,
        SwipeDirection.up => SwipeDirection.down,
        SwipeDirection.down => SwipeDirection.up,
      };

  /// The unit vector of this direction in logical pixel space, where positive
  /// `dy` points down.
  Offset get vector => switch (this) {
        SwipeDirection.left => const Offset(-1, 0),
        SwipeDirection.right => const Offset(1, 0),
        SwipeDirection.up => const Offset(0, -1),
        SwipeDirection.down => const Offset(0, 1),
      };
}
