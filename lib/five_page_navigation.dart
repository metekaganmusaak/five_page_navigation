// For sin in shake animation
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// Used for HapticFeedback and linear interpolation
import 'package:flutter/services.dart';

/// Represents the direction of a swipe gesture.
enum SwipeDirection {
  left,
  right,
  up,
  down,
}

/// Represents the type or position of a page within the navigator's structure.
enum PageType {
  center,
  left,
  right,
  top,
  bottom,
}

enum ThresholdFeedback {
  lightImpact,
  mediumImpact,
  heavyImpact,
}

/// Configuration for the preview displayed when `showSidePagePreviews` is true.
class PagePreviewConfig {
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
  final double?
      previewAppearanceThreshold; // Threshold for preview to fully appear
  final double previewMinScale; // Scale when preview starts appearing
  final double
      previewMaxScale; // Scale when preview is fully appeared (at appearance threshold)
  final double
      previewScaleBeyondThresholdFactor; // Extra scale factor beyond main threshold
  final bool enableLeftPreviewShake;
  final bool enableRightPreviewShake;
  final bool enableTopPreviewShake;
  final bool enableBottomPreviewShake;
  final double shakeIntensity; // Base intensity for shake
  final double
      shakeFrequencyFactor; // How much shake frequency increases with overscroll

  const PagePreviewConfig({
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
    this.defaultChipPadding =
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.defaultChipBorderRadius =
        const BorderRadius.all(Radius.circular(20.0)),
    this.defaultChipTextStyle,
    this.previewOffsetFromEdge = 20.0,
    this.previewAppearanceThreshold =
        0.15, // Preview fully appears at 15% swipe
    this.previewMinScale = 0.8,
    this.previewMaxScale = 1.0,
    this.previewScaleBeyondThresholdFactor =
        1.1, // Allow 10% extra scale beyond threshold
    this.enableLeftPreviewShake = true,
    this.enableRightPreviewShake = true,
    this.enableTopPreviewShake = true,
    this.enableBottomPreviewShake = true,
    this.shakeIntensity = 0.015, // 1.5% of screen dimension
    this.shakeFrequencyFactor = 4.0, // Frequency multiplier
  });
}

/// Configuration for the return to center button on side pages.
class ReturnButtonConfig {
  /// A custom builder for the button widget.
  /// Provides the BuildContext, an `onPressed` callback, and the `PageType`
  /// of the page the button is on.
  /// If null, the default button will be used.
  final Widget Function(
          BuildContext context, VoidCallback onPressed, PageType pageType)?
      customButtonBuilder;

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

  const ReturnButtonConfig({
    this.customButtonBuilder,
    this.backgroundColor = const Color(0x66000000), // Black with 40% opacity
    this.iconColor = Colors.white,
    this.buttonSize = 48.0,
    this.iconSize = 30.0,
    this.edgeOffset = 6.0,
  });
}

/// A custom navigator widget that allows swiping between a center page
/// and four surrounding pages (left, right, top, bottom).
class FivePageNavigator extends StatefulWidget {
  final Widget centerPage;
  final Widget leftPage;
  final Widget rightPage;
  final Widget topPage;
  final Widget bottomPage;
  // REMOVED: animationDuration is now fixed internally.
  final double swipeThreshold; // Threshold to trigger navigation
  final double zoomOutScale;
  final Function(PageType)? onPageChanged;
  final double verticalDetectionAreaHeight;
  final double horizontalDetectionAreaWidth;
  final bool enableLeftPageSwipeBack;
  final bool enableRightPageSwipeBack;
  final bool enableTopPageSwipeBack;
  final bool enableBottomPageSwipeBack;
  final bool Function()? canSwipeFromCenter;
  final ThresholdFeedback thresholdFeedback;
  final VoidCallback? onReturnCenterPage;
  final VoidCallback? onLeftPageOpened;
  final VoidCallback? onRightPageOpened;
  final VoidCallback? onTopPageOpened;
  final VoidCallback? onBottomPageOpened;
  final bool showSidePagePreviews;
  final PagePreviewConfig? previewConfig;
  final double incomingPageOpacityStart;

  // NEW FEATURES: Initial Center Page Entrance Animation
  final bool animateCenterPageEntranceOpacity;
  final Duration centerPageEntranceAnimationDuration;

  // NEW FEATURES: Return Button Configuration
  final bool showReturnToCenterButton;
  final ReturnButtonConfig? returnButtonConfig;

  const FivePageNavigator({
    super.key,
    required this.centerPage,
    required this.leftPage,
    required this.rightPage,
    required this.topPage,
    required this.bottomPage,
    // this.animationDuration = const Duration(milliseconds: 300), // REMOVED
    this.swipeThreshold = 0.25,
    this.zoomOutScale = 1,
    this.onPageChanged,
    this.verticalDetectionAreaHeight = 200.0,
    this.horizontalDetectionAreaWidth = 100.0,
    this.enableLeftPageSwipeBack = false,
    this.enableRightPageSwipeBack = false,
    this.enableTopPageSwipeBack = false,
    this.enableBottomPageSwipeBack = false,
    this.canSwipeFromCenter,
    this.thresholdFeedback = ThresholdFeedback.heavyImpact,
    this.onReturnCenterPage,
    this.onLeftPageOpened,
    this.onRightPageOpened,
    this.onTopPageOpened,
    this.onBottomPageOpened,
    this.showSidePagePreviews = false,
    this.previewConfig,
    this.incomingPageOpacityStart = 0.1,
    // New properties for initial center page animation
    this.animateCenterPageEntranceOpacity = false,
    this.centerPageEntranceAnimationDuration = kThemeAnimationDuration,
    // New properties for return button
    this.showReturnToCenterButton = true,
    this.returnButtonConfig,
  }) : assert(
          !(animateCenterPageEntranceOpacity == false &&
              centerPageEntranceAnimationDuration != kThemeAnimationDuration),
          'centerPageEntranceAnimationDuration only applies when animateCenterPageEntranceOpacity is true.',
        );

  @override
  State<FivePageNavigator> createState() => _FivePageNavigatorState();
}

class _FivePageNavigatorState extends State<FivePageNavigator>
    with TickerProviderStateMixin {
  bool _hasTriggerHapticFeedback = false;

  late AnimationController _swipeTransitionController;
  // Shake effect is calculated directly in build, no separate controller needed
  double _swipeProgress = 0.0;
  SwipeDirection? _currentSwipeDirection;
  Offset? _dragStartPosition;
  bool _isReturningToCenter = false;
  PageType? _returningFromPageType;
  late PagePreviewConfig _effectivePreviewConfig;

  // Animation controllers and animations for center page entrance opacity
  AnimationController? _centerPageEntranceController;
  Animation<double>? _centerPageEntranceOpacityAnimation;

  // Fixed animation duration for swipe transitions
  static const Duration _fixedSwipeAnimationDuration =
      Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _effectivePreviewConfig = widget.previewConfig ?? const PagePreviewConfig();

    _swipeTransitionController = AnimationController(
      duration: _fixedSwipeAnimationDuration, // Fixed duration
      vsync: this,
    );

    // Initialize entrance animation if enabled
    if (widget.animateCenterPageEntranceOpacity) {
      _centerPageEntranceController = AnimationController(
        duration: widget.centerPageEntranceAnimationDuration,
        vsync: this,
      );
      _centerPageEntranceOpacityAnimation =
          Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _centerPageEntranceController!,
          curve: Curves.easeIn,
        ),
      );
      // Start animation immediately after the first frame to ensure it runs once on build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _centerPageEntranceController?.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant FivePageNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.previewConfig != oldWidget.previewConfig) {
      _effectivePreviewConfig =
          widget.previewConfig ?? const PagePreviewConfig();
    }
  }

  @override
  void dispose() {
    _swipeTransitionController.dispose();
    _centerPageEntranceController?.dispose(); // Dispose if initialized
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<Widget>('centerPage', widget.centerPage));
    properties.add(DiagnosticsProperty<bool>(
        'showSidePagePreviews', widget.showSidePagePreviews));
    properties.add(DiagnosticsProperty<bool>('animateCenterPageEntranceOpacity',
        widget.animateCenterPageEntranceOpacity));
    if (widget.animateCenterPageEntranceOpacity) {
      properties.add(DiagnosticsProperty<Duration>(
          'centerPageEntranceAnimationDuration',
          widget.centerPageEntranceAnimationDuration));
    }
    properties.add(DiagnosticsProperty<bool>(
        'showReturnToCenterButton', widget.showReturnToCenterButton));
    properties.add(DiagnosticsProperty<ReturnButtonConfig?>(
        'returnButtonConfig', widget.returnButtonConfig));
  }

  // --- Gesture Handling ---

  void _handlePanStart(DragStartDetails details) {
    if (_swipeTransitionController.isAnimating || _isReturningToCenter) {
      _dragStartPosition = null;
      return;
    }
    bool canSwipe = widget.canSwipeFromCenter?.call() ?? true;
    if (!canSwipe) {
      _dragStartPosition = null;
      return;
    }
    _dragStartPosition = details.localPosition;
    _currentSwipeDirection = null;
    _swipeProgress = 0.0;
    _hasTriggerHapticFeedback = false;
    _swipeTransitionController.value = 0.0;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_dragStartPosition == null ||
        _swipeTransitionController.isAnimating ||
        _isReturningToCenter) {
      return; // Ignore updates if not in a valid state
    }

    final screenSize = MediaQuery.sizeOf(context);
    if (_currentSwipeDirection == null) {
      _determineSwipeDirection(details, screenSize);
    }

    if (_currentSwipeDirection != null) {
      double delta;
      double dimension;
      switch (_currentSwipeDirection!) {
        case SwipeDirection.left:
        case SwipeDirection.right:
          delta = details.delta.dx;
          dimension = screenSize.width;
          break;
        case SwipeDirection.up:
        case SwipeDirection.down:
          delta = details.delta.dy;
          dimension = screenSize.height;
          break;
      }
      double progressDelta = delta / dimension;
      if (_currentSwipeDirection == SwipeDirection.left ||
          _currentSwipeDirection == SwipeDirection.up) {
        _swipeProgress += progressDelta;
        _swipeProgress = _swipeProgress.clamp(-1.0, 0.0);
      } else {
        _swipeProgress += progressDelta;
        _swipeProgress = _swipeProgress.clamp(0.0, 1.0);
      }
      if (!mounted) return;
      _swipeTransitionController.value = _swipeProgress.abs();

      // Haptic feedback (only trigger once when threshold is first crossed)
      if (_swipeTransitionController.value >= widget.swipeThreshold &&
          !_hasTriggerHapticFeedback) {
        if (widget.thresholdFeedback == ThresholdFeedback.lightImpact)
          HapticFeedback.lightImpact();
        else if (widget.thresholdFeedback == ThresholdFeedback.mediumImpact)
          HapticFeedback.mediumImpact();
        else if (widget.thresholdFeedback == ThresholdFeedback.heavyImpact)
          HapticFeedback.heavyImpact();
        _hasTriggerHapticFeedback = true;
      } else if (_swipeTransitionController.value < widget.swipeThreshold) {
        _hasTriggerHapticFeedback = false; // Reset if goes back below threshold
      }
    }
  }

  void _determineSwipeDirection(DragUpdateDetails details, Size screenSize) {
    final startX = _dragStartPosition!.dx;
    final startY = _dragStartPosition!.dy;
    final currentX = details.localPosition.dx;
    final currentY = details.localPosition.dy;
    final totalDeltaX = currentX - startX;
    final totalDeltaY = currentY - startY;
    final absDeltaX = totalDeltaX.abs();
    final absDeltaY = totalDeltaY.abs();
    const double directionLockThreshold = 5.0;

    if (absDeltaX > directionLockThreshold ||
        absDeltaY > directionLockThreshold) {
      if (absDeltaX > absDeltaY) {
        if (totalDeltaX > 0 && startX < widget.horizontalDetectionAreaWidth) {
          _currentSwipeDirection = SwipeDirection.right;
        } else if (totalDeltaX < 0 &&
            startX > screenSize.width - widget.horizontalDetectionAreaWidth) {
          _currentSwipeDirection = SwipeDirection.left;
        }
      } else {
        if (totalDeltaY > 0 && startY < widget.verticalDetectionAreaHeight) {
          _currentSwipeDirection = SwipeDirection.down;
        } else if (totalDeltaY < 0 &&
            startY > screenSize.height - widget.verticalDetectionAreaHeight) {
          _currentSwipeDirection = SwipeDirection.up;
        }
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_currentSwipeDirection == null ||
        _swipeTransitionController.isAnimating ||
        _isReturningToCenter) {
      if (!_isReturningToCenter) _resetDragState();
      return;
    }
    _hasTriggerHapticFeedback = false; // Reset for next potential swipe

    final swipeProgress = _swipeTransitionController.value;
    if (swipeProgress >= widget.swipeThreshold) {
      _animateToPage();
    } else {
      _animateBackToCenter();
    }
  }

  // --- State Resets ---

  void _resetDragState({bool keepControllerValue = false}) {
    if (mounted) {
      _swipeProgress = 0.0;
      _currentSwipeDirection = null;
      _dragStartPosition = null;

      if (!keepControllerValue) {
        if (_swipeTransitionController.isAnimating) {
          _swipeTransitionController.stop();
        }
        _swipeTransitionController.value = 0.0;
      }
    }
  }

  void _resetReturnState() {
    if (mounted) {
      setState(() {
        _isReturningToCenter = false;
        _returningFromPageType = null;
        _currentSwipeDirection = null;
        _swipeProgress = 0.0;
        _dragStartPosition = null;
      });
      if (_swipeTransitionController.isAnimating)
        _swipeTransitionController.stop();
      _swipeTransitionController.value =
          0.0; // Always reset value on return completion
    }
  }

  // --- Animation and Navigation ---

  void _animateToPage() {
    if (_currentSwipeDirection == null ||
        _swipeTransitionController.isAnimating) return;
    // Start the animation to complete the swipe
    _swipeTransitionController
        .forward(from: _swipeTransitionController.value)
        .then((_) {
      // After animation completes, push the actual page
      if (mounted) _navigateToPageActual();
    }).catchError((error) {
      if (mounted) {
        debugPrint('Animation forward error: $error');
        _resetDragState();
      }
    });
  }

  void _animateBackToCenter() {
    if (_currentSwipeDirection == null ||
        _swipeTransitionController.isAnimating) return;
    // Animate back to the start position
    _swipeTransitionController
        .reverse(from: _swipeTransitionController.value)
        .then((_) {
      if (mounted)
        _resetDragState(); // Reset state completely after snapping back
    }).catchError((error) {
      if (mounted) {
        debugPrint('Animation reverse error: $error');
        _resetDragState();
      }
    });
  }

  void _handleReturnFromPage(PageType returnedFrom) {
    if (!mounted ||
        _swipeTransitionController.isAnimating ||
        _isReturningToCenter) {
      return;
    }
    final reverseDirection = _getReverseSwipeDirection(returnedFrom);
    if (reverseDirection == null) {
      _resetReturnState();
      return;
    }
    setState(() {
      _isReturningToCenter = true;
      _returningFromPageType = returnedFrom;
      _currentSwipeDirection = reverseDirection;
      _swipeTransitionController.value =
          1.0; // Start return animation from fully open
    });
    widget.onPageChanged?.call(PageType.center);
    _swipeTransitionController.reverse(from: 1.0).then((_) {
      if (mounted) {
        _resetReturnState(); // Reset state after the animation completes
        widget.onReturnCenterPage?.call();
      }
    }).catchError((error) {
      if (mounted) {
        debugPrint(
            'Animation reverse error (from _handleReturnFromPage): $error');
        _resetReturnState();
      }
    });
  }

  void _navigateToPageActual() {
    if (_currentSwipeDirection == null || !mounted) {
      _resetDragState();
      return;
    }

    PageType targetPageType;
    Widget targetPageWidget;
    bool enableSwipeBackForTarget = false;
    switch (_currentSwipeDirection!) {
      case SwipeDirection.left:
        targetPageType = PageType.right;
        targetPageWidget = widget.rightPage;
        enableSwipeBackForTarget = widget.enableRightPageSwipeBack;
        break;
      case SwipeDirection.right:
        targetPageType = PageType.left;
        targetPageWidget = widget.leftPage;
        enableSwipeBackForTarget = widget.enableLeftPageSwipeBack;
        break;
      case SwipeDirection.up:
        targetPageType = PageType.bottom;
        targetPageWidget = widget.bottomPage;
        enableSwipeBackForTarget = widget.enableBottomPageSwipeBack;
        break;
      case SwipeDirection.down:
        targetPageType = PageType.top;
        targetPageWidget = widget.topPage;
        enableSwipeBackForTarget = widget.enableTopPageSwipeBack;
        break;
    }

    Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (ctx, anim, secAnim) => PageWrapper(
            pageType: targetPageType,
            onReturnFromPage: _handleReturnFromPage,
            enableSwipeBack: enableSwipeBackForTarget,
            centerPage: widget.centerPage,
            thresholdFeedback: widget.thresholdFeedback,
            // Pass return button config AND incomingPageOpacityStart
            showReturnToCenterButton: widget.showReturnToCenterButton,
            returnButtonConfig: widget.returnButtonConfig,
            incomingPageOpacityStart: widget.incomingPageOpacityStart,
            child: targetPageWidget,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        )).then((result) {
      if (!mounted) return; // Ensure widget is still mounted after async op

      if (result is Map && result["type"] == "gesture_pop_completed") {
        // This was a gesture pop from PageWrapper, and PageWrapper completed its animation.
        // FivePageNavigator just needs to reset its state to idle, no animation needed.
        _resetReturnState(); // This sets _isReturningToCenter to false, _swipeProgress to 0
        widget.onReturnCenterPage
            ?.call(); // Notify listener that we're back at center
      } else if (result is String && result.startsWith("button_pop")) {
        // This was a button pop from PageWrapper.
        // _handleReturnFromPage was ALREADY called by the button's onTap directly
        // before the pop, and it handles the animation and state reset.
        // So, do nothing here to avoid redundant calls/resets.
      } else {
        // This covers system back button pops (result is null) or any other unhandled pops.
        // In these cases, PageWrapper's PopScope's onPopInvokedWithResult should
        // ideally have called _handleReturnFromPage to trigger animation.
        // If _isReturningToCenter is true, it means _handleReturnFromPage was already called
        // and is running its animation, so let it complete its own reset.
        // If _isReturningToCenter is false, it means an unexpected pop occurred
        // without _handleReturnFromPage being invoked, so we need a fallback reset.
        if (!_isReturningToCenter) {
          _resetReturnState();
          widget.onReturnCenterPage?.call();
        }
      }
    });

    // CRITICAL FIX: Reset FivePageNavigator's swipe animation state to idle AFTER pushing the page.
    // This ensures FivePageNavigator isn't stuck rendering a "partially swiped" state
    // when a child route (PageWrapper) is now on top. This will make _buildSwipeContent
    // render the idle center page in the background, which PageWrapper then uses.
    _resetDragState(keepControllerValue: false);

    widget.onPageChanged?.call(targetPageType);
    switch (targetPageType) {
      case PageType.left:
        widget.onLeftPageOpened?.call();
        break;
      case PageType.right:
        widget.onRightPageOpened?.call();
        break;
      case PageType.top:
        widget.onTopPageOpened?.call();
        break;
      case PageType.bottom:
        widget.onBottomPageOpened?.call();
        break;
      case PageType.center:
        break;
    }
  }

  // --- Helper Functions ---

  SwipeDirection? _getReverseSwipeDirection(PageType fromPage) {
    switch (fromPage) {
      case PageType.left:
        return SwipeDirection.right;
      case PageType.right:
        return SwipeDirection.left;
      case PageType.top:
        return SwipeDirection.down;
      case PageType.bottom:
        return SwipeDirection.up;
      case PageType.center:
        return null;
    }
  }

  Offset _getCenterPageEndOffset(SwipeDirection dir, Size s) {
    switch (dir) {
      case SwipeDirection.left:
        return Offset(-s.width, 0);
      case SwipeDirection.right:
        return Offset(s.width, 0);
      case SwipeDirection.up:
        return Offset(0, -s.height);
      case SwipeDirection.down:
        return Offset(0, s.height);
    }
  }

  Offset _getOffScreenOffset(SwipeDirection dir, Size s) {
    switch (dir) {
      case SwipeDirection.left:
        return Offset(s.width, 0);
      case SwipeDirection.right:
        return Offset(-s.width, 0);
      case SwipeDirection.up:
        return Offset(0, s.height);
      case SwipeDirection.down:
        return Offset(0, -s.height);
    }
  }

  // Get the actual page widget instance based on the *target* PageType
  Widget _getSwipingPageWidget(PageType targetType) {
    switch (targetType) {
      case PageType.right:
        return widget.rightPage;
      case PageType.left:
        return widget.leftPage;
      case PageType.bottom:
        return widget.bottomPage;
      case PageType.top:
        return widget.topPage;
      default:
        return const SizedBox.shrink(); // Should not happen
    }
  }

  Widget _getPreviewWidgetOrBuildDefault(SwipeDirection direction) {
    Widget? customPreviewWidget;
    String defaultLabel = "";
    switch (direction) {
      case SwipeDirection.left:
        customPreviewWidget = _effectivePreviewConfig.rightPagePreviewWidget;
        defaultLabel = _effectivePreviewConfig.rightPageLabel;
        break;
      case SwipeDirection.right:
        customPreviewWidget = _effectivePreviewConfig.leftPagePreviewWidget;
        defaultLabel = _effectivePreviewConfig.leftPageLabel;
        break;
      case SwipeDirection.up:
        customPreviewWidget = _effectivePreviewConfig.bottomPagePreviewWidget;
        defaultLabel = _effectivePreviewConfig.bottomPageLabel;
        break;
      case SwipeDirection.down:
        customPreviewWidget = _effectivePreviewConfig.topPagePreviewWidget;
        defaultLabel = _effectivePreviewConfig.topPageLabel;
        break;
    }
    // If a custom widget is provided, wrap it in Material if it isn't already one
    // to ensure consistent behavior (e.g., for InkWell effects if used inside).
    // However, requiring the user to provide Material might be better practice.
    // Let's wrap the *default* chip in Material explicitly.
    if (customPreviewWidget != null) {
      // It's generally better for the user to provide Material if needed
      // for their custom widget. We won't wrap it here.
      return Material(
        type: MaterialType.transparency,
        child: customPreviewWidget,
      );
    }

    // Build default chip, wrapped in Material
    return Material(
      type: MaterialType.transparency, // Avoids double background
      child: Container(
        padding: _effectivePreviewConfig.defaultChipPadding,
        decoration: BoxDecoration(
          color: _effectivePreviewConfig.defaultChipBackgroundColor,
          borderRadius: _effectivePreviewConfig.defaultChipBorderRadius,
        ),
        child: Text(
          defaultLabel,
          style: _effectivePreviewConfig.defaultChipTextStyle ??
              TextStyle(
                  color: _effectivePreviewConfig.defaultChipTextColor,
                  fontSize: 14),
        ),
      ),
    );
  }

  Widget _getPageWidgetByType(PageType type) {
    switch (type) {
      case PageType.center:
        return widget.centerPage;
      case PageType.left:
        return widget.leftPage;
      case PageType.right:
        return widget.rightPage;
      case PageType.top:
        return widget.topPage;
      case PageType.bottom:
        return widget.bottomPage;
    }
  }

  // Helper to get target PageType from SwipeDirection
  PageType? _getPageTypeFromSwipeDirection(SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.left:
        return PageType.right;
      case SwipeDirection.right:
        return PageType.left;
      case SwipeDirection.up:
        return PageType.bottom;
      case SwipeDirection.down:
        return PageType.top;
    }
  }

  // Helper to get the center page wrapped with its entrance opacity animation
  Widget _getAnimatedCenterPage() {
    if (!widget.animateCenterPageEntranceOpacity ||
        _centerPageEntranceController == null) {
      // If animation is not enabled or controller not initialized, return the raw widget.
      return widget.centerPage;
    }

    // Wrap the center page in an AnimatedBuilder to handle its initial opacity fade-in.
    // This AnimatedBuilder ensures the widget rebuilds when _centerPageEntranceOpacityAnimation changes.
    return AnimatedBuilder(
      animation: _centerPageEntranceOpacityAnimation!,
      builder: (context, child) {
        return Opacity(
          opacity: _centerPageEntranceOpacityAnimation!.value,
          child: child,
        );
      },
      child: widget.centerPage,
    );
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    // Listen only to swipe controller; shake effect is calculated directly in build
    return ListenableBuilder(
        listenable: _swipeTransitionController,
        builder: (context, child) {
          return GestureDetector(
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            behavior: HitTestBehavior.opaque,
            child: Container(
              clipBehavior: Clip.hardEdge,
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(),
              child: _buildSwipeContent(_swipeTransitionController.value),
            ),
          );
        });
  }

  /// Builds the preview widget that animates based on swipe progress.
  Widget _buildPreviewOverlay(
      double animationProgress, SwipeDirection direction) {
    final screenSize = MediaQuery.sizeOf(context);
    final previewWidget =
        _getPreviewWidgetOrBuildDefault(direction); // Gets custom or default

    // Threshold for opacity and scale to become fully visible/scaled
    final double appearanceThreshold =
        _effectivePreviewConfig.previewAppearanceThreshold ??
            widget.swipeThreshold;
    // Ensure appearanceThreshold is not zero to avoid division by zero
    final double safeAppearanceThreshold = max(0.01, appearanceThreshold);
    // Progress ratio specifically for appearance effects (opacity, scale, AND POSITION) 0.0 to 1.0
    // This ratio determines how "complete" the preview appearance is based on the appearance threshold.
    final appearanceProgressRatio =
        (animationProgress / safeAppearanceThreshold).clamp(0.0, 1.0);

    // --- Opacity ---
    final chipOpacity = appearanceProgressRatio;

    // --- Scale ---
    // Scale animation completes at appearance threshold
    double currentScale = lerpDouble(_effectivePreviewConfig.previewMinScale,
        _effectivePreviewConfig.previewMaxScale, appearanceProgressRatio)!;

    // --- Extra Scale & Shake Calculation (only if beyond main swipeThreshold) ---
    Offset currentShakeOffset = Offset.zero;
    // Calculate overscroll progress (0.0 to 1.0 for the range threshold -> 1.0)
    final double overscrollRaw = (animationProgress - widget.swipeThreshold);
    if (overscrollRaw > 0) {
      // Avoid division by zero if threshold is 1.0
      final double overscrollRange = max(0.01, 1.0 - widget.swipeThreshold);
      final double overscrollProgress =
          (overscrollRaw / overscrollRange).clamp(0.0, 1.0);

      // Apply extra scaling based on overscroll
      if (_effectivePreviewConfig.previewScaleBeyondThresholdFactor != 1.0) {
        final beyondThresholdScaleMultiplier = lerpDouble(
            1.0,
            _effectivePreviewConfig.previewScaleBeyondThresholdFactor,
            overscrollProgress)!;
        currentScale *=
            beyondThresholdScaleMultiplier; // Apply extra scale ON TOP of the base max scale
      }

      // Calculate shake based on overscroll
      bool shakeEnabled = false;
      switch (direction) {
        case SwipeDirection.right:
          shakeEnabled = _effectivePreviewConfig.enableLeftPreviewShake;
          break;
        case SwipeDirection.left:
          shakeEnabled = _effectivePreviewConfig.enableRightPreviewShake;
          break;
        case SwipeDirection.down:
          shakeEnabled = _effectivePreviewConfig.enableTopPreviewShake;
          break;
        case SwipeDirection.up:
          shakeEnabled = _effectivePreviewConfig.enableBottomPreviewShake;
          break;
      }

      if (shakeEnabled) {
        final intensity = _effectivePreviewConfig.shakeIntensity;
        final frequencyFactor = 1.0 +
            (overscrollProgress * _effectivePreviewConfig.shakeFrequencyFactor);
        double dx = 0, dy = 0;
        double time = DateTime.now().millisecondsSinceEpoch / 100.0;
        double sineValue = sin(frequencyFactor * time * 2 * pi);
        double currentAmplitudeFactor = overscrollProgress;

        if (direction == SwipeDirection.left ||
            direction == SwipeDirection.right) {
          dy = screenSize.height *
              intensity *
              sineValue *
              currentAmplitudeFactor;
        } else {
          dx =
              screenSize.width * intensity * sineValue * currentAmplitudeFactor;
        }
        currentShakeOffset = Offset(dx, dy);
      }
    }

    // Combine opacity and scale for the preview widget itself
    Widget animatedPreviewContent = Opacity(
      opacity: chipOpacity,
      child: Transform.scale(
        scale: currentScale,
        alignment: Alignment.center,
        child: previewWidget,
      ),
    );

    // --- Positioning ---
    // Position animation also completes at appearance threshold, using appearanceProgressRatio
    final double targetEdgeOffset =
        _effectivePreviewConfig.previewOffsetFromEdge;

    switch (direction) {
      case SwipeDirection.right: // Revealing Left Page (align left-center)
        final double offScreenStart =
            -screenSize.width; // Start way off-screen left
        // Use appearanceProgressRatio for positioning lerp
        final double currentLeft = lerpDouble(
            offScreenStart, targetEdgeOffset, appearanceProgressRatio)!;
        return Positioned(
          left: currentLeft +
              currentShakeOffset.dx, // Apply shake to final position
          top: 0 +
              currentShakeOffset
                  .dy, // Apply shake Y (handles vertical centering implicitly with top/bottom 0)
          bottom: 0,
          child: Center(child: animatedPreviewContent), // Center vertically
        );

      case SwipeDirection.left: // Revealing Right Page (align right-center)
        final double offScreenStart = -screenSize
            .width; // Start effectively far left for 'right' property
        // Use appearanceProgressRatio for positioning lerp
        final double currentRight = lerpDouble(
            offScreenStart, targetEdgeOffset, appearanceProgressRatio)!;
        return Positioned(
          right:
              currentRight - currentShakeOffset.dx, // Apply shake X (inverted)
          top: 0 + currentShakeOffset.dy, // Apply shake Y
          bottom: 0,
          child: Center(child: animatedPreviewContent), // Center vertically
        );

      case SwipeDirection.down: // Revealing Top Page (align top-center)
        final double offScreenStart =
            -screenSize.height; // Start way off-screen top
        // Use appearanceProgressRatio for positioning lerp
        final double currentTop = lerpDouble(
            offScreenStart, targetEdgeOffset, appearanceProgressRatio)!;
        return Positioned(
          top: currentTop + currentShakeOffset.dy, // Apply shake Y
          left: 0 +
              currentShakeOffset
                  .dx, // Apply shake X (handles horizontal centering implicitly)
          right: 0,
          child: Center(child: animatedPreviewContent), // Center horizontally
        );

      case SwipeDirection.up: // Revealing Bottom Page (align bottom-center)
        final double offScreenStart = -screenSize
            .height; // Start effectively far top for 'bottom' property
        // Use appearanceProgressRatio for positioning lerp
        final double currentBottom = lerpDouble(
            offScreenStart, targetEdgeOffset, appearanceProgressRatio)!;
        return Positioned(
          bottom:
              currentBottom - currentShakeOffset.dy, // Apply shake Y (inverted)
          left: 0 + currentShakeOffset.dx, // Apply shake X
          right: 0,
          child: Center(child: animatedPreviewContent), // Center horizontally
        );
    }
  }

  /// Builds the content displayed during swipe (drag) and swipe transitions
  Widget _buildSwipeContent(double animationProgress) {
    final size = MediaQuery.sizeOf(context);
    List<Widget> stackChildren = [];

    // This is the version of the center page that includes the initial fade-in animation,
    // if enabled. It will be opaque (1.0) once the animation completes.
    // We'll use this `animatedCenterPage` whenever the center page is static or a background.
    final Widget animatedCenterPage = _getAnimatedCenterPage();

    if (_isReturningToCenter) {
      // Case 1: Returning to Center (center page is animating in, driven by FivePageNavigator)
      // This happens for button clicks or system back if PageWrapper didn't handle animation.
      Widget pageComingOnScreen = widget.centerPage;
      Widget pageGoingOffScreen = _getPageWidgetByType(_returningFromPageType!);
      SwipeDirection effectiveDirection = _currentSwipeDirection!;
      double currentScale =
          lerpDouble(widget.zoomOutScale, 1.0, 1.0 - animationProgress)!;
      final centerPushedOffset =
          _getCenterPageEndOffset(effectiveDirection, size);
      final incomingPageProgress = 1.0 - animationProgress;
      final offsetForOnScreen =
          Offset.lerp(centerPushedOffset, Offset.zero, incomingPageProgress)!;
      final sideOffScreenOffset = _getOffScreenOffset(effectiveDirection, size);
      final offsetForOffScreen =
          Offset.lerp(Offset.zero, sideOffScreenOffset, incomingPageProgress)!;

      stackChildren.add(
        Transform.translate(
          offset: offsetForOnScreen,
          child: Transform.scale(
            scale: currentScale,
            alignment: Alignment.center,
            child: Opacity(
              opacity: lerpDouble(
                  widget.incomingPageOpacityStart, 1.0, incomingPageProgress)!,
              child:
                  pageComingOnScreen, // Raw center page, opacity handled by lerp here
            ),
          ),
        ),
      );
      stackChildren.add(
        Transform.translate(
          offset: offsetForOffScreen,
          child: Transform.scale(
            scale: currentScale,
            alignment: Alignment.center,
            child: pageGoingOffScreen,
          ),
        ),
      );
    } else if (_currentSwipeDirection != null) {
      // Case 2: Swiping from Center (either showing preview or final slide, driven by FivePageNavigator)
      SwipeDirection effectiveDirection = _currentSwipeDirection!;
      bool isAnimatingToPageCompletion =
          _swipeTransitionController.isAnimating &&
              (_swipeTransitionController.status == AnimationStatus.forward);

      if (widget.showSidePagePreviews && !isAnimatingToPageCompletion) {
        // Sub-case 2a: Swiping with previews active: center page is background.
        // Use the `animatedCenterPage` here so it gets its initial fade-in effect.
        stackChildren.add(animatedCenterPage);
        if (animationProgress > 0) {
          // Only show preview if there's actual swipe progress
          stackChildren
              .add(_buildPreviewOverlay(animationProgress, effectiveDirection));
        }
      } else {
        // Sub-case 2b: Final slide animation (no preview shown, center page slides out, side page slides in)
        // The center page is *moving out*, its opacity is 1.0 (it's the active page).
        // So, use the raw `widget.centerPage` here.
        Widget pageGoingOffScreen = widget.centerPage;
        double currentScaleForOffScreen = 1.0;
        if (widget.zoomOutScale != 1.0) {
          currentScaleForOffScreen =
              lerpDouble(1.0, widget.zoomOutScale, animationProgress)!;
        }
        final centerEndOffset =
            _getCenterPageEndOffset(effectiveDirection, size);
        final offsetForOffScreen =
            Offset.lerp(Offset.zero, centerEndOffset, animationProgress)!;

        stackChildren.add(Transform.translate(
          offset: offsetForOffScreen,
          child: Transform.scale(
            scale: currentScaleForOffScreen,
            alignment: Alignment.center,
            child: pageGoingOffScreen,
          ),
        ));

        PageType? targetPageType =
            _getPageTypeFromSwipeDirection(effectiveDirection);
        if (targetPageType != null) {
          Widget pageComingOnScreen = _getSwipingPageWidget(targetPageType);
          double currentScaleForOnScreen = 1.0;
          if (widget.zoomOutScale != 1.0) {
            currentScaleForOnScreen =
                lerpDouble(widget.zoomOutScale, 1.0, animationProgress)!;
          }
          final sideStartOffset = _getOffScreenOffset(effectiveDirection, size);
          final offsetForOnScreen =
              Offset.lerp(sideStartOffset, Offset.zero, animationProgress)!;
          stackChildren.add(
            Transform.translate(
              offset: offsetForOnScreen,
              child: Transform.scale(
                scale: currentScaleForOnScreen,
                alignment: Alignment.center,
                child: Opacity(
                  opacity: lerpDouble(
                      widget.incomingPageOpacityStart, 1.0, animationProgress)!,
                  child: pageComingOnScreen,
                ),
              ),
            ),
          );
        }
      }
    } else {
      // Case 3: Idle state: Only center page is visible.
      // This is also the state when a PageWrapper is pushed on top and FivePageNavigator is behind it.
      // Use the `animatedCenterPage` here so it gets its initial fade-in effect.
      stackChildren.add(animatedCenterPage);
    }

    return Stack(children: stackChildren);
  }
} // End of _FivePageNavigatorState

/// A wrapper widget for the pages displayed as side pages in the [FivePageNavigator].
/// Handles system back button and optional swipe-back gesture.
class PageWrapper extends StatefulWidget {
  final Widget child;
  final PageType pageType;
  final Function(PageType returnedFrom)? onReturnFromPage;
  final bool enableSwipeBack;
  final Widget
      centerPage; // Needed for the swipe-back animation to reveal center
  final ThresholdFeedback thresholdFeedback;

  // NEW: Return Button Configuration
  final bool showReturnToCenterButton;
  final ReturnButtonConfig? returnButtonConfig;
  final double incomingPageOpacityStart; // NEW: Pass down this value

  const PageWrapper({
    super.key, // Allow key to be passed
    required this.child,
    required this.pageType,
    this.onReturnFromPage,
    this.enableSwipeBack = false,
    required this.centerPage,
    this.thresholdFeedback = ThresholdFeedback.heavyImpact,
    // NEW properties
    this.showReturnToCenterButton = true,
    this.returnButtonConfig,
    this.incomingPageOpacityStart = 0.1, // NEW: Receive this value
  });

  @override
  State<PageWrapper> createState() => _PageWrapperState();
}

class _PageWrapperState extends State<PageWrapper>
    with TickerProviderStateMixin {
  late AnimationController _swipeBackController;
  double _swipeBackDragStart = 0.0;
  bool _isSwipeBackDragging = false; // Tracks if a swipe-back gesture is active
  bool _hasTriggerHapticFeedback = false;

  @override
  void initState() {
    super.initState();
    _swipeBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _swipeBackController.dispose();
    super.dispose();
  }

  // --- Gesture Handling for Swipe-Back ---
  void _handlePanStart(DragStartDetails details) {
    if (!widget.enableSwipeBack || _swipeBackController.isAnimating) return;
    const double edgeThreshold = 200.0;
    final size = MediaQuery.sizeOf(context);
    bool isValidSwipeStart = false;
    switch (widget.pageType) {
      case PageType.left:
        if (details.localPosition.dx >= size.width - edgeThreshold) {
          _swipeBackDragStart = details.localPosition.dx;
          isValidSwipeStart = true;
        }
        break;
      case PageType.right:
        if (details.localPosition.dx <= edgeThreshold) {
          _swipeBackDragStart = details.localPosition.dx;
          isValidSwipeStart = true;
        }
        break;
      case PageType.top:
        if (details.localPosition.dy >= size.height - edgeThreshold) {
          _swipeBackDragStart = details.localPosition.dy;
          isValidSwipeStart = true;
        }
        break;
      case PageType.bottom:
        if (details.localPosition.dy <= edgeThreshold) {
          _swipeBackDragStart = details.localPosition.dy;
          isValidSwipeStart = true;
        }
        break;
      case PageType.center:
        break;
    }

    // Update _isSwipeBackDragging and trigger rebuild to hide the button
    if (_isSwipeBackDragging != isValidSwipeStart) {
      setState(() {
        _isSwipeBackDragging = isValidSwipeStart;
      });
    }

    if (_isSwipeBackDragging) {
      _hasTriggerHapticFeedback = false;
      _swipeBackController.value = 0.0;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isSwipeBackDragging) return;
    final size = MediaQuery.sizeOf(context);
    double delta;
    double maxSize;
    switch (widget.pageType) {
      case PageType.left:
        delta = _swipeBackDragStart - details.localPosition.dx;
        maxSize = size.width;
        break;
      case PageType.right:
        delta = details.localPosition.dx - _swipeBackDragStart;
        maxSize = size.width;
        break;
      case PageType.top:
        delta = _swipeBackDragStart - details.localPosition.dy;
        maxSize = size.height;
        break;
      case PageType.bottom:
        delta = details.localPosition.dy - _swipeBackDragStart;
        maxSize = size.height;
        break;
      case PageType.center:
        return;
    }
    final progress = (delta / maxSize).clamp(0.0, 1.0);
    if (!mounted) return;
    _swipeBackController.value = progress;
    const double swipeBackHapticThreshold = 0.5;
    if (_swipeBackController.value >= swipeBackHapticThreshold &&
        !_hasTriggerHapticFeedback) {
      if (widget.thresholdFeedback == ThresholdFeedback.lightImpact)
        HapticFeedback.lightImpact();
      else if (widget.thresholdFeedback == ThresholdFeedback.mediumImpact)
        HapticFeedback.mediumImpact();
      else if (widget.thresholdFeedback == ThresholdFeedback.heavyImpact)
        HapticFeedback.heavyImpact();
      _hasTriggerHapticFeedback = true;
    } else if (_swipeBackController.value < swipeBackHapticThreshold) {
      _hasTriggerHapticFeedback = false;
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isSwipeBackDragging) return;
    _hasTriggerHapticFeedback = false;
    const double swipeBackPopThreshold = 0.5;
    if (_swipeBackController.value >= swipeBackPopThreshold) {
      _swipeBackController.animateTo(1.0).then((_) {
        if (mounted) {
          // Pop with a map to signify gesture pop and pass pageType
          // FivePageNavigator will just reset state, no animation needed from its side.
          Navigator.of(context).pop(
            {
              "type": "gesture_pop_completed",
              "fromPage": widget.pageType,
            },
          );
        }
      }).catchError((e) {
        if (mounted) _swipeBackController.value = 0.0;
      }).whenComplete(() {
        // Always reset _isSwipeBackDragging and trigger rebuild when animation completes
        if (mounted) {
          setState(() {
            _isSwipeBackDragging = false;
          });
        }
      });
    } else {
      _swipeBackController.reverse().catchError((e) {
        if (mounted) _swipeBackController.value = 0.0;
      }).whenComplete(() {
        // Always reset _isSwipeBackDragging and trigger rebuild when animation completes
        if (mounted) {
          setState(() {
            _isSwipeBackDragging = false;
          });
        }
      });
    }
  }

  /// Builds the return-to-center button for side pages.
  Widget _buildReturnToCenterButton(BuildContext context) {
    // If the feature is disabled, or no return callback is provided, or currently swiping back, hide the button.
    if (!widget.showReturnToCenterButton ||
        widget.onReturnFromPage == null ||
        _isSwipeBackDragging) {
      return const SizedBox.shrink();
    }

    final effectiveConfig =
        widget.returnButtonConfig ?? const ReturnButtonConfig();

    // Unified onTap logic
    void onButtonTapped() {
      // Trigger haptic feedback
      if (widget.thresholdFeedback == ThresholdFeedback.lightImpact) {
        HapticFeedback.lightImpact();
      } else if (widget.thresholdFeedback == ThresholdFeedback.mediumImpact) {
        HapticFeedback.mediumImpact();
      } else if (widget.thresholdFeedback == ThresholdFeedback.heavyImpact) {
        HapticFeedback.heavyImpact();
      }
      // Call the callback to notify FivePageNavigator
      // FivePageNavigator WILL animate the return in this case.
      widget.onReturnFromPage?.call(widget.pageType);
      // Pop the current page from the navigator stack
      Navigator.of(context).pop("button_pop_${widget.pageType.name}");
    }

    IconData iconData;
    Alignment alignment;
    double? left, right, top, bottom;

    // Determine alignment and icon based on page type, regardless of custom button
    switch (widget.pageType) {
      case PageType.left: // Return from left page (button on right edge)
        iconData = Icons.chevron_right;
        alignment = Alignment.centerRight;
        right = effectiveConfig.edgeOffset;
        top = 0;
        bottom = 0;
        break;
      case PageType.right: // Return from right page (button on left edge)
        iconData = Icons.chevron_left;
        alignment = Alignment.centerLeft;
        left = effectiveConfig.edgeOffset;
        top = 0;
        bottom = 0;
        break;
      case PageType.top: // Return from top page (button on bottom edge)
        iconData = Icons.expand_more;
        alignment = Alignment.bottomCenter;
        bottom = effectiveConfig.edgeOffset;
        left = 0;
        right = 0;
        break;
      case PageType.bottom: // Return from bottom page (button on top edge)
        iconData = Icons.expand_less;
        alignment = Alignment.topCenter;
        top = effectiveConfig.edgeOffset;
        left = 0;
        right = 0;
        break;
      case PageType.center:
        return const SizedBox.shrink(); // Button not needed on center page
    }

    Widget buttonWidget;
    if (effectiveConfig.customButtonBuilder != null) {
      // Use custom builder if provided
      buttonWidget = effectiveConfig.customButtonBuilder!(
          context, onButtonTapped, widget.pageType);
    } else {
      // Build default button
      buttonWidget = Material(
        color: Colors.transparent, // Background will be from Container
        type: MaterialType.circle,
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onButtonTapped,
          customBorder: const CircleBorder(),
          child: Container(
            width: effectiveConfig.buttonSize,
            height: effectiveConfig.buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: effectiveConfig
                  .backgroundColor, // Apply default background here
            ),
            child: Icon(
              iconData,
              color: effectiveConfig.iconColor,
              size: effectiveConfig.iconSize,
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: SafeArea(
        child: Align(
          alignment: alignment,
          child: buttonWidget,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We always wrap with GestureDetector and AnimatedBuilder to maintain
    // a consistent structure for swipe-back logic and also to easily add
    // the button as an overlay.
    return GestureDetector(
      onPanStart: widget.enableSwipeBack ? _handlePanStart : null,
      onPanUpdate: widget.enableSwipeBack ? _handlePanUpdate : null,
      onPanEnd: widget.enableSwipeBack ? _handlePanEnd : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _swipeBackController,
        builder: (context, child) {
          final size = MediaQuery.sizeOf(context);
          double sidePageTranslateX = 0.0, sidePageTranslateY = 0.0;
          double centerPageTranslateX = 0.0, centerPageTranslateY = 0.0;

          if (widget.enableSwipeBack) {
            switch (widget.pageType) {
              case PageType.left: // Swiping back from left page (moving right)
                sidePageTranslateX = -_swipeBackController.value * size.width;
                centerPageTranslateX =
                    size.width * (1.0 - _swipeBackController.value);
                break;
              case PageType.right: // Swiping back from right page (moving left)
                sidePageTranslateX = _swipeBackController.value * size.width;
                centerPageTranslateX =
                    -size.width * (1.0 - _swipeBackController.value);
                break;
              case PageType.top: // Swiping back from top page (moving down)
                sidePageTranslateY = -_swipeBackController.value * size.height;
                centerPageTranslateY =
                    size.height * (1.0 - _swipeBackController.value);
                break;
              case PageType.bottom: // Swiping back from bottom page (moving up)
                sidePageTranslateY = _swipeBackController.value * size.height;
                centerPageTranslateY =
                    -size.height * (1.0 - _swipeBackController.value);
                break;
              case PageType.center:
                break;
            }
          }

          return Stack(
            children: [
              // This is the background center page shown during swipe back
              // The opacity is handled here by PageWrapper
              Transform.translate(
                offset: Offset(centerPageTranslateX, centerPageTranslateY),
                child: widget.centerPage,
              ),
              // This is the actual side page content
              Transform.translate(
                offset: Offset(sidePageTranslateX, sidePageTranslateY),
                child: PopScope(
                  // System back button can pop if not actively swiping back or if drag is minimal
                  canPop: widget.enableSwipeBack
                      ? (_swipeBackController.value < 0.1 &&
                          !_isSwipeBackDragging)
                      : true,
                  onPopInvokedWithResult: (didPop, result) {
                    // Only call onReturnFromPage if it was a system back button pop
                    // and not one of our gesture_pop_completed or button_pop.
                    // This ensures the animation from FivePageNavigator's side.
                    if (didPop &&
                        !(result is Map &&
                            result["type"] == "gesture_pop_completed") &&
                        !(result is String &&
                            result.startsWith("button_pop"))) {
                      widget.onReturnFromPage?.call(widget.pageType);
                    }
                  },
                  child: widget.child, // The actual side page content
                ),
              ),
              // Add the return button on top of everything
              _buildReturnToCenterButton(context),
            ],
          );
        },
      ),
    );
  }
}
