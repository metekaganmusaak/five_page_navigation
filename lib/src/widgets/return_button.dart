import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../configs/return_button_style.dart';
import '../enums/page_type.dart';

/// The space taken by the top and bottom bars of the first scaffold found in
/// a page.
@immutable
class ScaffoldBarInsets {
  /// Creates bar insets.
  const ScaffoldBarInsets({this.top = 0, this.bottom = 0});

  /// Height of the app bar or navigation bar, including the status bar area
  /// it paints behind.
  final double top;

  /// Height of the bottom navigation bar or tab bar.
  final double bottom;

  /// Insets for a page without bars.
  static const ScaffoldBarInsets zero = ScaffoldBarInsets();

  @override
  bool operator ==(Object other) =>
      other is ScaffoldBarInsets && other.top == top && other.bottom == bottom;

  @override
  int get hashCode => Object.hash(top, bottom);
}

// Probing walks a bounded part of the element tree. Scaffolds and their bars
// sit close to the root of a page, so these limits are generous.
const int _kMaxProbeDepth = 24;
const int _kMaxProbeElements = 4000;

/// Measures the bars of the outermost [Scaffold] or [CupertinoPageScaffold]
/// below [root].
///
/// Must be called after layout (for example from a post-frame callback),
/// because it reads the size of the rendered bars.
ScaffoldBarInsets measureScaffoldBars(Element root) {
  Element? scaffold;
  var visited = 0;
  final queue = Queue<(Element, int)>()..add((root, 0));
  while (queue.isNotEmpty && visited < _kMaxProbeElements) {
    final (element, depth) = queue.removeFirst();
    visited++;
    final widget = element.widget;
    if (widget is Scaffold || widget is CupertinoPageScaffold) {
      scaffold = element;
      break;
    }
    if (depth < _kMaxProbeDepth) {
      element.visitChildElements((child) => queue.add((child, depth + 1)));
    }
  }
  if (scaffold == null) return ScaffoldBarInsets.zero;

  final Widget? topBar;
  final Widget? bottomBar;
  final widget = scaffold.widget;
  if (widget is Scaffold) {
    topBar = widget.appBar;
    bottomBar = widget.bottomNavigationBar;
  } else {
    topBar = (widget as CupertinoPageScaffold).navigationBar;
    bottomBar = null;
  }
  if (topBar == null && bottomBar == null) return ScaffoldBarInsets.zero;

  double top = 0;
  double bottom = 0;
  var remaining = (topBar != null ? 1 : 0) + (bottomBar != null ? 1 : 0);
  visited = 0;
  queue
    ..clear()
    ..add((scaffold, 0));
  while (queue.isNotEmpty && remaining > 0 && visited < _kMaxProbeElements) {
    final (element, depth) = queue.removeFirst();
    visited++;
    final w = element.widget;
    if (identical(w, topBar) || identical(w, bottomBar)) {
      final renderObject = element.renderObject;
      if (renderObject is RenderBox && renderObject.hasSize) {
        if (identical(w, topBar)) {
          top = renderObject.size.height;
        } else {
          bottom = renderObject.size.height;
        }
      }
      remaining--;
      continue;
    }
    // Do not descend into nested scaffolds (for example inside the body).
    if (element != scaffold && (w is Scaffold || w is CupertinoPageScaffold)) {
      continue;
    }
    if (depth < _kMaxProbeDepth) {
      element.visitChildElements((child) => queue.add((child, depth + 1)));
    }
  }
  return ScaffoldBarInsets(top: top, bottom: bottom);
}

/// Places the "return to center" button on top of a side page.
///
/// The button is aligned to the edge that faces the center page. When
/// [ReturnButtonStyle.respectScaffoldBars] is enabled, it is pushed below the
/// page's app bar or above its bottom navigation bar, so it never covers them.
class ReturnButtonOverlay extends StatefulWidget {
  /// Creates the overlay.
  const ReturnButtonOverlay({
    super.key,
    required this.pageType,
    required this.style,
    required this.onPressed,
    required this.pageKey,
  });

  /// The side page the button is placed on.
  final PageType pageType;

  /// The appearance of the button.
  final ReturnButtonStyle style;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  /// Key of the subtree that contains the page, used to look for bars.
  final GlobalKey pageKey;

  @override
  State<ReturnButtonOverlay> createState() => _ReturnButtonOverlayState();
}

class _ReturnButtonOverlayState extends State<ReturnButtonOverlay> {
  ScaffoldBarInsets _bars = ScaffoldBarInsets.zero;
  bool _probeScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleProbe();
  }

  @override
  void didUpdateWidget(ReturnButtonOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleProbe();
  }

  void _scheduleProbe() {
    if (_probeScheduled || !widget.style.respectScaffoldBars) return;
    _probeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _probeScheduled = false;
      if (!mounted) return;
      final pageContext = widget.pageKey.currentContext;
      if (pageContext is! Element) return;
      final bars = measureScaffoldBars(pageContext);
      if (bars != _bars) setState(() => _bars = bars);
    }, debugLabel: 'ReturnButtonOverlay.probe');
  }

  Alignment get _defaultAlignment => switch (widget.pageType) {
        PageType.left => Alignment.centerRight,
        PageType.right => Alignment.centerLeft,
        PageType.top => Alignment.bottomCenter,
        PageType.bottom => Alignment.topCenter,
        PageType.center => Alignment.center,
      };

  IconData get _icon => switch (widget.pageType) {
        PageType.left => Icons.chevron_right_rounded,
        PageType.right => Icons.chevron_left_rounded,
        PageType.top => Icons.expand_more_rounded,
        PageType.bottom => Icons.expand_less_rounded,
        PageType.center => Icons.close_rounded,
      };

  Widget _buildDefaultButton(BuildContext context) {
    final style = widget.style;
    final label = style.tooltip ??
        Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        )?.backButtonTooltip ??
        'Back';

    Widget button = Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onPressed,
          customBorder: const CircleBorder(),
          child: Ink(
            width: style.buttonSize,
            height: style.buttonSize,
            decoration: ShapeDecoration(
              color: style.backgroundColor,
              shape: const CircleBorder(),
              shadows: style.elevation > 0
                  ? kElevationToShadow[style.elevation.round().clamp(1, 24)] ??
                      kElevationToShadow[1]
                  : null,
            ),
            child: Icon(
              style.icon ?? _icon,
              color: style.iconColor,
              size: style.iconSize,
            ),
          ),
        ),
      ),
    );

    // Tooltips need an Overlay, which is missing when the navigator is used
    // above the app's Navigator (for example in MaterialApp.builder).
    if (style.tooltip != null && Overlay.maybeOf(context) != null) {
      button = Tooltip(message: style.tooltip, child: button);
    }
    return button;
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final safe = MediaQuery.paddingOf(context);
    final offset = style.edgeOffset;
    final bars = style.respectScaffoldBars ? _bars : ScaffoldBarInsets.zero;

    final button = style.customButtonBuilder?.call(
          context,
          widget.onPressed,
          widget.pageType,
        ) ??
        _buildDefaultButton(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        safe.left + offset,
        math.max(safe.top, bars.top) + offset,
        safe.right + offset,
        math.max(safe.bottom, bars.bottom) + offset,
      ),
      child: Align(
        alignment: style.alignment ?? _defaultAlignment,
        child: button,
      ),
    );
  }
}
