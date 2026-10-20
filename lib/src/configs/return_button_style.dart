import 'package:flutter/widgets.dart';

import '../enums/page_type.dart';

/// Signature for building a custom "return to center" button.
///
/// [onPressed] returns to the center page; [pageType] is the side page the
/// button is placed on.
typedef ReturnButtonBuilder = Widget Function(
  BuildContext context,
  VoidCallback onPressed,
  PageType pageType,
);

/// Appearance of the "return to center" button shown on side pages when
/// `FivePageNavigator.showReturnToCenterButton` is `true`.
///
/// By default the button sits on the edge that faces the center page: on the
/// right of the left page, on the left of the right page, at the bottom of
/// the top page and at the top of the bottom page.
@immutable
class ReturnButtonStyle {
  /// Creates a return button style.
  const ReturnButtonStyle({
    this.customButtonBuilder,
    this.backgroundColor = const Color(0x66000000),
    this.iconColor = const Color(0xFFFFFFFF),
    this.buttonSize = 48.0,
    this.iconSize = 30.0,
    this.edgeOffset = 6.0,
    this.icon,
    this.tooltip,
    this.elevation = 0.0,
    this.alignment,
    this.respectScaffoldBars = true,
  })  : assert(buttonSize > 0),
        assert(iconSize > 0),
        assert(elevation >= 0);

  /// Builds a custom button instead of the default circular one.
  ///
  /// The result is still positioned by this style ([alignment],
  /// [edgeOffset], [respectScaffoldBars]). Return `SizedBox.shrink()` to hide
  /// the button on some pages.
  final ReturnButtonBuilder? customButtonBuilder;

  /// Background color of the default button.
  final Color backgroundColor;

  /// Icon color of the default button.
  final Color iconColor;

  /// Width and height of the default circular button.
  final double buttonSize;

  /// Size of the icon inside the default button.
  final double iconSize;

  /// Distance between the button and the edge of the page (after the safe
  /// area and the scaffold bars).
  final double edgeOffset;

  /// Icon of the default button. When `null`, a chevron pointing towards the
  /// center page is used.
  final IconData? icon;

  /// Tooltip shown on hover or long press. Also used as the semantic label;
  /// when `null` the localized "Back" label is announced instead.
  final String? tooltip;

  /// Elevation of the default button's shadow.
  final double elevation;

  /// Overrides where the button is aligned on every side page.
  final AlignmentGeometry? alignment;

  /// Whether the button avoids the page's `AppBar`/`CupertinoNavigationBar`
  /// and `bottomNavigationBar`.
  ///
  /// The navigator looks for the outermost `Scaffold` or
  /// `CupertinoPageScaffold` of each side page after it is laid out and
  /// offsets the button by the height of its bars. Pages without bars are
  /// only offset by the safe area.
  final bool respectScaffoldBars;

  /// Returns a copy of this style with the given fields replaced.
  ReturnButtonStyle copyWith({
    ReturnButtonBuilder? customButtonBuilder,
    Color? backgroundColor,
    Color? iconColor,
    double? buttonSize,
    double? iconSize,
    double? edgeOffset,
    IconData? icon,
    String? tooltip,
    double? elevation,
    AlignmentGeometry? alignment,
    bool? respectScaffoldBars,
  }) {
    return ReturnButtonStyle(
      customButtonBuilder: customButtonBuilder ?? this.customButtonBuilder,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      iconColor: iconColor ?? this.iconColor,
      buttonSize: buttonSize ?? this.buttonSize,
      iconSize: iconSize ?? this.iconSize,
      edgeOffset: edgeOffset ?? this.edgeOffset,
      icon: icon ?? this.icon,
      tooltip: tooltip ?? this.tooltip,
      elevation: elevation ?? this.elevation,
      alignment: alignment ?? this.alignment,
      respectScaffoldBars: respectScaffoldBars ?? this.respectScaffoldBars,
    );
  }
}
