import 'swipe_direction.dart';

/// The position of a page inside a [FivePageNavigator].
///
/// Positions are physical: [left] is always on the left side of the screen,
/// regardless of the ambient [TextDirection].
enum PageType {
  /// The main page, shown when no side page is open.
  center,

  /// The page placed on the left of the center page.
  left,

  /// The page placed on the right of the center page.
  right,

  /// The page placed above the center page.
  top,

  /// The page placed below the center page.
  bottom;

  /// Whether this is [PageType.center].
  bool get isCenter => this == PageType.center;

  /// Whether this is one of the four side pages.
  bool get isSide => this != PageType.center;

  /// The direction the content moves (the direction of the finger) when this
  /// side page is opened from the center page.
  ///
  /// For example, the left page is revealed by swiping to the right.
  /// Returns `null` for [PageType.center].
  SwipeDirection? get openDirection => switch (this) {
        PageType.center => null,
        PageType.left => SwipeDirection.right,
        PageType.right => SwipeDirection.left,
        PageType.top => SwipeDirection.down,
        PageType.bottom => SwipeDirection.up,
      };

  /// The direction the content moves when returning from this side page to
  /// the center page. Returns `null` for [PageType.center].
  SwipeDirection? get returnDirection => openDirection?.opposite;
}
