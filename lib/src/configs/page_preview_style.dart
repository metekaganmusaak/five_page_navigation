import 'package:flutter/material.dart'
    show Colors, Widget, Color, EdgeInsets, BorderRadius, TextStyle, Radius;

/// Configuration for the preview displayed when `showSidePagePreviews` is true.
class PagePreviewStyle {
  final Widget? leftPagePreviewWidget;
  final Widget? rightPagePreviewWidget;
  final Widget? topPagePreviewWidget;
  final Widget? bottomPagePreviewWidget;
  final String leftPageLabel;
  final String rightPageLabel;
  final String topPageLabel;
  final String bottomPageLabel;
  final Color defaultChipBackgroundColor;
  final Color defaultChipTextColor;
  final EdgeInsets defaultChipPadding;
  final BorderRadius defaultChipBorderRadius;
  final TextStyle? defaultChipTextStyle;
  final double previewOffsetFromEdge;
  // Threshold for preview to fully appear
  final double? previewAppearanceThreshold;
  // Scale when preview starts appearing
  final double previewMinScale;
  // Scale when preview is fully appeared (at appearance threshold)
  final double previewMaxScale;
  // Extra scale factor beyond main threshold
  final double previewScaleBeyondThresholdFactor;

  const PagePreviewStyle({
    this.leftPagePreviewWidget,
    this.rightPagePreviewWidget,
    this.topPagePreviewWidget,
    this.bottomPagePreviewWidget,
    this.leftPageLabel = "Left",
    this.rightPageLabel = "Right",
    this.topPageLabel = "Top",
    this.bottomPageLabel = "Bottom",
    this.defaultChipBackgroundColor = const Color(0xCC424242),
    this.defaultChipTextColor = Colors.white,
    this.defaultChipPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 8.0,
    ),
    this.defaultChipBorderRadius = const BorderRadius.all(
      Radius.circular(20.0),
    ),
    this.defaultChipTextStyle,
    this.previewOffsetFromEdge = 20.0,
    // Preview fully appears at 15% swipe
    this.previewAppearanceThreshold = 0.15,
    this.previewMinScale = 0.8,
    this.previewMaxScale = 1.0,
    // Allow 10% extra scale beyond threshold
    this.previewScaleBeyondThresholdFactor = 1.1,
  });
}
