import 'package:flutter/material.dart'
    show BuildContext, VoidCallback, Color, Widget, Colors;

import '../enums/page_type.dart';

/// Configuration for the return to center button on side pages.
class ReturnButtonStyle {
  /// A custom builder for the button widget.
  /// Provides the BuildContext, an `onPressed` callback, and the `PageType`
  /// of the page the button is on.
  /// If null, the default button will be used.
  final Widget Function(
    BuildContext context,
    VoidCallback onPressed,
    PageType pageType,
  )? customButtonBuilder;

  /// Background color for the default button.
  final Color backgroundColor;

  /// Icon color for the default button.
  final Color iconColor;

  /// Size (width and height) for the default circular button.
  final double buttonSize;

  /// Size for the icon within the default button.
  final double iconSize;

  /// Offset from the edge of the screen for the default button.
  final double edgeOffset;

  const ReturnButtonStyle({
    this.customButtonBuilder,
    this.backgroundColor = const Color(0x66000000), // Black with 40% opacity
    this.iconColor = Colors.white,
    this.buttonSize = 48.0,
    this.iconSize = 30.0,
    this.edgeOffset = 6.0,
  });
}
