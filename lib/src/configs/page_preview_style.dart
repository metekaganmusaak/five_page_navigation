import 'package:flutter/widgets.dart';

/// Appearance of the preview shown while swiping from the center page when
/// `FivePageNavigator.showSidePagePreviews` is `true`.
///
/// While previews are enabled, dragging from an edge does not move the pages.
/// Instead a small preview (by default a labelled chip) slides in from that
/// edge. Releasing past `swipeThreshold` opens the page with the configured
/// transition; releasing earlier hides the preview.
@immutable
class PagePreviewStyle {
  /// Creates a preview style.
  const PagePreviewStyle({
    this.leftPagePreviewWidget,
    this.rightPagePreviewWidget,
    this.topPagePreviewWidget,
    this.bottomPagePreviewWidget,
    this.leftPageLabel = 'Left',
    this.rightPageLabel = 'Right',
    this.topPageLabel = 'Top',
    this.bottomPageLabel = 'Bottom',
    this.defaultChipBackgroundColor = const Color(0xCC424242),
    this.defaultChipTextColor = const Color(0xFFFFFFFF),
    this.defaultChipPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 8.0,
    ),
    this.defaultChipBorderRadius = const BorderRadius.all(
      Radius.circular(20.0),
    ),
    this.defaultChipTextStyle,
    this.previewOffsetFromEdge = 20.0,
    this.previewAppearanceThreshold = 0.15,
    this.previewMinScale = 0.8,
    this.previewMaxScale = 1.0,
    this.previewScaleBeyondThresholdFactor = 1.1,
  })  : assert(previewOffsetFromEdge >= 0),
        assert(
          previewAppearanceThreshold == null ||
              (previewAppearanceThreshold > 0 &&
                  previewAppearanceThreshold <= 1),
        ),
        assert(previewMinScale >= 0),
        assert(previewMaxScale >= 0),
        assert(previewScaleBeyondThresholdFactor > 0);

  /// Custom preview for the left page. Replaces the default chip.
  final Widget? leftPagePreviewWidget;

  /// Custom preview for the right page. Replaces the default chip.
  final Widget? rightPagePreviewWidget;

  /// Custom preview for the top page. Replaces the default chip.
  final Widget? topPagePreviewWidget;

  /// Custom preview for the bottom page. Replaces the default chip.
  final Widget? bottomPagePreviewWidget;

  /// Label of the default chip for the left page.
  final String leftPageLabel;

  /// Label of the default chip for the right page.
  final String rightPageLabel;

  /// Label of the default chip for the top page.
  final String topPageLabel;

  /// Label of the default chip for the bottom page.
  final String bottomPageLabel;

  /// Background color of the default chip.
  final Color defaultChipBackgroundColor;

  /// Text color of the default chip. Ignored when [defaultChipTextStyle]
  /// is set.
  final Color defaultChipTextColor;

  /// Padding of the default chip.
  final EdgeInsets defaultChipPadding;

  /// Border radius of the default chip.
  final BorderRadius defaultChipBorderRadius;

  /// Text style of the default chip.
  final TextStyle? defaultChipTextStyle;

  /// Distance between the preview and the edge it appears from, inside the
  /// safe area.
  final double previewOffsetFromEdge;

  /// Drag progress (fraction of the navigator's size) at which the preview is
  /// fully visible. `null` shows the preview immediately.
  final double? previewAppearanceThreshold;

  /// Scale of the preview when it starts appearing.
  final double previewMinScale;

  /// Scale of the preview once it is fully visible.
  final double previewMaxScale;

  /// Extra scale applied, with a short animation, once the drag passes
  /// `swipeThreshold` to signal that releasing will open the page.
  final double previewScaleBeyondThresholdFactor;

  /// Returns a copy of this style with the given fields replaced.
  PagePreviewStyle copyWith({
    Widget? leftPagePreviewWidget,
    Widget? rightPagePreviewWidget,
    Widget? topPagePreviewWidget,
    Widget? bottomPagePreviewWidget,
    String? leftPageLabel,
    String? rightPageLabel,
    String? topPageLabel,
    String? bottomPageLabel,
    Color? defaultChipBackgroundColor,
    Color? defaultChipTextColor,
    EdgeInsets? defaultChipPadding,
    BorderRadius? defaultChipBorderRadius,
    TextStyle? defaultChipTextStyle,
    double? previewOffsetFromEdge,
    double? previewAppearanceThreshold,
    double? previewMinScale,
    double? previewMaxScale,
    double? previewScaleBeyondThresholdFactor,
  }) {
    return PagePreviewStyle(
      leftPagePreviewWidget:
          leftPagePreviewWidget ?? this.leftPagePreviewWidget,
      rightPagePreviewWidget:
          rightPagePreviewWidget ?? this.rightPagePreviewWidget,
      topPagePreviewWidget: topPagePreviewWidget ?? this.topPagePreviewWidget,
      bottomPagePreviewWidget:
          bottomPagePreviewWidget ?? this.bottomPagePreviewWidget,
      leftPageLabel: leftPageLabel ?? this.leftPageLabel,
      rightPageLabel: rightPageLabel ?? this.rightPageLabel,
      topPageLabel: topPageLabel ?? this.topPageLabel,
      bottomPageLabel: bottomPageLabel ?? this.bottomPageLabel,
      defaultChipBackgroundColor:
          defaultChipBackgroundColor ?? this.defaultChipBackgroundColor,
      defaultChipTextColor: defaultChipTextColor ?? this.defaultChipTextColor,
      defaultChipPadding: defaultChipPadding ?? this.defaultChipPadding,
      defaultChipBorderRadius:
          defaultChipBorderRadius ?? this.defaultChipBorderRadius,
      defaultChipTextStyle: defaultChipTextStyle ?? this.defaultChipTextStyle,
      previewOffsetFromEdge:
          previewOffsetFromEdge ?? this.previewOffsetFromEdge,
      previewAppearanceThreshold:
          previewAppearanceThreshold ?? this.previewAppearanceThreshold,
      previewMinScale: previewMinScale ?? this.previewMinScale,
      previewMaxScale: previewMaxScale ?? this.previewMaxScale,
      previewScaleBeyondThresholdFactor: previewScaleBeyondThresholdFactor ??
          this.previewScaleBeyondThresholdFactor,
    );
  }
}
