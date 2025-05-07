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

/// A custom navigator widget that allows swiping between a center page
/// and four surrounding pages (left, right, top, bottom).
class FivePageNavigator extends StatefulWidget {
  final Widget centerPage;
  final Widget leftPage;
  final Widget rightPage;
  final Widget topPage;
  final Widget bottomPage;
  final Duration animationDuration;
  final Duration initialWaitDuration;
  final double swipeThreshold; // Threshold to trigger navigation
  final double zoomOutScale;
  final Function(PageType)? onPageChanged;
  final double verticalDetectionAreaHeight;
  final double horizontalDetectionAreaWidth;
  final bool enableLeftPageSwipeBack;
  final bool enableRightPageSwipeBack;
  final bool enableTopPageSwipeBack;
  final bool enableBottomPageSwipeBack;
  final double initialViewScale;
  final bool Function()? canSwipeFromCenter;
  final ThresholdFeedback thresholdFeedback;
  final VoidCallback? onReturnCenterPage;
  final VoidCallback? onLeftPageOpened;
  final VoidCallback? onRightPageOpened;
  final VoidCallback? onTopPageOpened;
  final VoidCallback? onBottomPageOpened;
  final bool showSidePagePreviews;
  final PagePreviewConfig? previewConfig;

  const FivePageNavigator({
    super.key,
    required this.centerPage,
    required this.leftPage,
    required this.rightPage,
    required this.topPage,
    required this.bottomPage,
    this.animationDuration = const Duration(milliseconds: 300),
    this.initialWaitDuration = Duration.zero,
    this.swipeThreshold = 0.25,
    this.zoomOutScale = 1,
    this.onPageChanged,
    this.verticalDetectionAreaHeight = 200.0,
    this.horizontalDetectionAreaWidth = 100.0,
    this.enableLeftPageSwipeBack = false,
    this.enableRightPageSwipeBack = false,
    this.enableTopPageSwipeBack = false,
    this.enableBottomPageSwipeBack = false,
    this.initialViewScale = 1.0,
    this.canSwipeFromCenter,
    this.thresholdFeedback = ThresholdFeedback.heavyImpact,
    this.onReturnCenterPage,
    this.onLeftPageOpened,
    this.onRightPageOpened,
    this.onTopPageOpened,
    this.onBottomPageOpened,
    this.showSidePagePreviews = false,
    this.previewConfig,
  });

  @override
  State<FivePageNavigator> createState() => _FivePageNavigatorState();
}

class _FivePageNavigatorState extends State<FivePageNavigator>
    with TickerProviderStateMixin {
  bool _hasTriggerHapticFeedback = false;
  late AnimationController _initialZoomController;
  late AnimationController _swipeTransitionController;
  // Shake effect is calculated directly in build, no separate controller needed
  double _swipeProgress = 0.0;
  SwipeDirection? _currentSwipeDirection;
  Offset? _dragStartPosition;
  bool _isInitialZoomCompleted = false;
  bool _isReturningToCenter = false;
  PageType? _returningFromPageType;
  late PagePreviewConfig _effectivePreviewConfig;

  @override
  void initState() {
    super.initState();
    _effectivePreviewConfig = widget.previewConfig ?? const PagePreviewConfig();
    _initialZoomController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _swipeTransitionController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(widget.initialWaitDuration, () {
        if (mounted) {
          _initialZoomController.forward().then((_) {
            if (mounted) {
              setState(() {
                _isInitialZoomCompleted = true;
              });
              widget.onPageChanged?.call(PageType.center);
            }
          });
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant FivePageNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.previewConfig != oldWidget.previewConfig) {
      _effectivePreviewConfig =
          widget.previewConfig ?? const PagePreviewConfig();
    }
    if (widget.animationDuration != oldWidget.animationDuration) {
      _swipeTransitionController.duration = widget.animationDuration;
    }
  }

  @override
  void dispose() {
    _initialZoomController.dispose();
    _swipeTransitionController.dispose();
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<Widget>('centerPage', widget.centerPage));
    properties.add(DiagnosticsProperty<bool>(
        'showSidePagePreviews', widget.showSidePagePreviews));
  }

  // --- Gesture Handling ---

  void _handlePanStart(DragStartDetails details) {
    if (!_isInitialZoomCompleted ||
        _swipeTransitionController.isAnimating ||
        _isReturningToCenter) {
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
        _isReturningToCenter) return;
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
        _resetReturnState();
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

    // --- KeyedSubtree KALDIRILDI ---
    // final pageKey = ValueKey('SidePage_${targetPageType.toString()}'); // Key kullanımını kaldırdık

    Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (ctx, anim, secAnim) => PageWrapper(
            // key: pageKey, // Anahtarı PageWrapper'a vermiyoruz
            pageType: targetPageType, onReturnFromPage: _handleReturnFromPage,
            enableSwipeBack: enableSwipeBackForTarget,
            centerPage: widget.centerPage,
            thresholdFeedback: widget.thresholdFeedback,
            child: targetPageWidget,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        )).then((result) {
      if (result == "gesture_pop") {
        _resetReturnState(); // Resets controller value to 0
        widget.onReturnCenterPage?.call();
      }
    });

    _resetDragState(keepControllerValue: true);

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

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    if (!_isInitialZoomCompleted) {
      return AnimatedBuilder(
          animation: _initialZoomController,
          builder: (context, child) =>
              _buildInitialZoomContent(_initialZoomController.value));
    }
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

  /// Builds the content displayed during the initial zoom-out animation.
  /// FIX: Refined center page scaling and positioning logic for smoothness.
  Widget _buildInitialZoomContent(double animationProgress) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    const double spacing = 15.0; // Consistent spacing

    // Calculate scales based on animation progress
    // Side pages scale down to 0
    final sideScale =
        lerpDouble(widget.initialViewScale, 0.0, animationProgress)!
            .clamp(0.0, 1.0);
    // Center page scales from initialViewScale up to 1.0
    final centerCurrentScale =
        lerpDouble(widget.initialViewScale, 1.0, animationProgress)!;

    // --- Calculate Initial Positions/Sizes (animationProgress = 0) ---
    final initialCenterWidth = screenWidth * widget.initialViewScale;
    final initialCenterHeight = screenHeight * widget.initialViewScale;
    final initialCenterX = (screenWidth - initialCenterWidth) / 2;
    final initialCenterY = (screenHeight - initialCenterHeight) / 2;

    final initialSideWidth = screenWidth * widget.initialViewScale;
    final initialSideHeight = screenHeight * widget.initialViewScale;

    // Calculate positions relative to the initial center position
    final initialLeftX = initialCenterX - initialSideWidth - spacing;
    final initialRightX = initialCenterX + initialCenterWidth + spacing;
    final initialTopY = initialCenterY - initialSideHeight - spacing;
    final initialBottomY = initialCenterY + initialCenterHeight + spacing;
    final initialSideY = initialCenterY; // Y for left/right pages initially
    final initialSideX = initialCenterX; // X for top/bottom pages initially

    // --- Calculate Final Positions/Sizes (animationProgress = 1) ---
    const finalCenterX = 0.0;
    const finalCenterY = 0.0;

    // Final positions ensure side pages are completely off-screen
    final finalLeftX = -screenWidth;
    final finalRightX = screenWidth;
    final finalTopY = -screenHeight;
    final finalBottomY = screenHeight;

    // Final alignment helper positions (less critical as scale is 0)
    final finalSideY = (screenHeight - initialSideHeight) / 2;
    final finalSideX = (screenWidth - initialSideWidth) / 2;

    // --- Interpolate Current Positions ---
    final currentCenterX =
        lerpDouble(initialCenterX, finalCenterX, animationProgress)!;
    final currentCenterY =
        lerpDouble(initialCenterY, finalCenterY, animationProgress)!;
    final currentLeftX =
        lerpDouble(initialLeftX, finalLeftX, animationProgress)!;
    final currentRightX =
        lerpDouble(initialRightX, finalRightX, animationProgress)!;
    final currentTopY = lerpDouble(initialTopY, finalTopY, animationProgress)!;
    final currentBottomY =
        lerpDouble(initialBottomY, finalBottomY, animationProgress)!;
    final currentSideY =
        lerpDouble(initialSideY, finalSideY, animationProgress)!;
    final currentSideX =
        lerpDouble(initialSideX, finalSideX, animationProgress)!;

    // Animate the display size of the center page's container
    final currentCenterDisplayWidth =
        lerpDouble(initialCenterWidth, screenWidth, animationProgress)!;
    final currentCenterDisplayHeight =
        lerpDouble(initialCenterHeight, screenHeight, animationProgress)!;

    // --- Build the Stack ---
    List<Widget> stackChildren = [];

    // Add side pages only if they are significantly visible
    if (sideScale > 0.01) {
      // Reduced threshold slightly
      stackChildren.addAll([
        // Use initial sizes for Positioned, let Transform.scale handle the size change
        Positioned(
          left: currentLeftX,
          top: currentSideY,
          width: initialSideWidth,
          height: initialSideHeight,
          child: Transform.scale(
            scale: sideScale,
            alignment: Alignment.center,
            child: widget.leftPage,
          ),
        ),
        Positioned(
          left: currentRightX,
          top: currentSideY,
          width: initialSideWidth,
          height: initialSideHeight,
          child: Transform.scale(
            scale: sideScale,
            alignment: Alignment.center,
            child: widget.rightPage,
          ),
        ),
        Positioned(
          left: currentSideX,
          top: currentTopY,
          width: initialSideWidth,
          height: initialSideHeight,
          child: Transform.scale(
            scale: sideScale,
            alignment: Alignment.center,
            child: widget.topPage,
          ),
        ),
        Positioned(
          left: currentSideX,
          top: currentBottomY,
          width: initialSideWidth,
          height: initialSideHeight,
          child: Transform.scale(
            scale: sideScale,
            alignment: Alignment.center,
            child: widget.bottomPage,
          ),
        ),
      ]);
    }

    // Add the center page
    stackChildren.add(
      Positioned(
        left: currentCenterX,
        top: currentCenterY,
        width: currentCenterDisplayWidth, // Animate container size
        height: currentCenterDisplayHeight,
        // The Positioned widget handles the overall placement and size animation.
        // The Transform.scale inside scales the *content* to match the desired scale smoothly.
        child: Transform.scale(
          // Scale factor goes from initialViewScale to 1.0
          scale: centerCurrentScale,
          alignment: Alignment.center,
          // Provide a SizedBox sized to the *final* screen dimensions.
          // The Transform.scale above will handle scaling this down/up correctly
          // within the animated Positioned bounds. No ClipRect needed here.
          child: SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: widget.centerPage),
        ),
      ),
    );

    // Always return a Stack
    return Stack(children: stackChildren);
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
    // Idle state: Show only center page
    if (_currentSwipeDirection == null &&
        !_isReturningToCenter &&
        !_swipeTransitionController.isAnimating &&
        animationProgress == 0.0) {
      return widget.centerPage;
    }

    final size = MediaQuery.sizeOf(context);
    List<Widget> stackChildren = [];
    Widget centerPageForStack = widget.centerPage; // Base layer

    if (_isReturningToCenter) {
      // --- Returning to Center ---
      // Standard slide animation, no previews involved here.
      Widget pageComingOnScreen = widget.centerPage;
      Widget pageGoingOffScreen = _getPageWidgetByType(_returningFromPageType!);
      SwipeDirection effectiveDirection = _currentSwipeDirection!;
      double currentScaleForOnScreen = 1.0, currentScaleForOffScreen = 1.0;
      if (widget.zoomOutScale != 1.0) {
        currentScaleForOnScreen =
            lerpDouble(widget.zoomOutScale, 1.0, 1.0 - animationProgress)!;
        currentScaleForOffScreen =
            lerpDouble(1.0, widget.zoomOutScale, 1.0 - animationProgress)!;
      }
      final centerPushedOffset =
          _getCenterPageEndOffset(effectiveDirection, size);
      final offsetForOnScreen = Offset.lerp(
          centerPushedOffset, Offset.zero, 1.0 - animationProgress)!;
      final sideOffScreenOffset = _getOffScreenOffset(effectiveDirection, size);
      final offsetForOffScreen = Offset.lerp(
          Offset.zero, sideOffScreenOffset, 1.0 - animationProgress)!;
      stackChildren.add(Transform.translate(
          offset: offsetForOffScreen,
          child: Transform.scale(
              scale: currentScaleForOffScreen,
              alignment: Alignment.center,
              child: pageGoingOffScreen)));
      stackChildren.add(Transform.translate(
          offset: offsetForOnScreen,
          child: Transform.scale(
              scale: currentScaleForOnScreen,
              alignment: Alignment.center,
              child: pageComingOnScreen)));
    } else if (_currentSwipeDirection != null) {
      // --- Swiping from Center ---
      SwipeDirection effectiveDirection = _currentSwipeDirection!;
      bool isAnimatingToPageCompletion =
          _swipeTransitionController.isAnimating &&
              (_swipeTransitionController.status == AnimationStatus.forward);

      // If showing previews AND not in the final slide animation, show center + preview.
      if (widget.showSidePagePreviews && !isAnimatingToPageCompletion) {
        stackChildren
            .add(centerPageForStack); // Center page is static background
        if (animationProgress > 0) {
          stackChildren
              .add(_buildPreviewOverlay(animationProgress, effectiveDirection));
        }
      } else {
        // --- Standard Slide (or Final Slide after preview) ---
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

        // Render the outgoing page (center) transforming
        stackChildren.add(Transform.translate(
            offset: offsetForOffScreen,
            child: Transform.scale(
                scale: currentScaleForOffScreen,
                alignment: Alignment.center,
                child: pageGoingOffScreen)));

        // **Render the incoming page for the slide effect**
        // This fixes the black screen issue.
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
          stackChildren.add(Transform.translate(
              offset: offsetForOnScreen,
              child: Transform.scale(
                  scale: currentScaleForOnScreen,
                  alignment: Alignment.center,
                  child: pageComingOnScreen)));
        }
      }
    } else {
      stackChildren.add(centerPageForStack);
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

  const PageWrapper({
    super.key, // Allow key to be passed
    required this.child,
    required this.pageType,
    this.onReturnFromPage,
    this.enableSwipeBack = false,
    required this.centerPage,
    this.thresholdFeedback = ThresholdFeedback.heavyImpact,
  });

  @override
  State<PageWrapper> createState() => _PageWrapperState();
}

class _PageWrapperState extends State<PageWrapper>
    with TickerProviderStateMixin {
  late AnimationController _swipeBackController;
  double _swipeBackDragStart = 0.0;
  bool _isSwipeBackDragging = false;
  bool _hasTriggerHapticFeedback = false;

  @override
  void initState() {
    super.initState();
    // print("✅ PageWrapper initState for ${widget.pageType}"); // Debug log
    _swipeBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    // print("❌ PageWrapper dispose for ${widget.pageType}"); // Debug log
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
    _isSwipeBackDragging = isValidSwipeStart;
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
    _isSwipeBackDragging = false;
    _hasTriggerHapticFeedback = false;
    const double swipeBackPopThreshold = 0.5;
    if (_swipeBackController.value >= swipeBackPopThreshold) {
      _swipeBackController.animateTo(1.0).then((_) {
        if (mounted) Navigator.of(context).pop("gesture_pop");
      }).catchError((e) {
        if (mounted) _swipeBackController.value = 0.0;
      });
    } else {
      _swipeBackController.reverse().catchError((e) {
        if (mounted) _swipeBackController.value = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If swipe-back is not enabled, just wrap the child with PopScope.
    if (!widget.enableSwipeBack) {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop && result != "gesture_pop") {
            widget.onReturnFromPage?.call(widget.pageType);
          }
        },
        // --- KeyedSubtree KALDIRILDI ---
        child: widget.child,
      );
    }

    // If swipe-back is enabled, build the animating stack.
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _swipeBackController,
        builder: (context, child) {
          final size = MediaQuery.sizeOf(context);
          double sidePageTranslateX = 0.0, sidePageTranslateY = 0.0;
          double centerPageTranslateX = 0.0, centerPageTranslateY = 0.0;

          switch (widget.pageType) {
            case PageType.left:
              sidePageTranslateX = -_swipeBackController.value * size.width;
              centerPageTranslateX =
                  size.width * (1.0 - _swipeBackController.value);
              break;
            case PageType.right:
              sidePageTranslateX = _swipeBackController.value * size.width;
              centerPageTranslateX =
                  -size.width * (1.0 - _swipeBackController.value);
              break;
            case PageType.top:
              sidePageTranslateY = -_swipeBackController.value * size.height;
              centerPageTranslateY =
                  size.height * (1.0 - _swipeBackController.value);
              break;
            case PageType.bottom:
              sidePageTranslateY = _swipeBackController.value * size.height;
              centerPageTranslateY =
                  -size.height * (1.0 - _swipeBackController.value);
              break;
            case PageType.center:
              break;
          }

          return Stack(
            children: [
              Transform.translate(
                offset: Offset(centerPageTranslateX, centerPageTranslateY),
                child: widget.centerPage,
              ),
              Transform.translate(
                offset: Offset(sidePageTranslateX, sidePageTranslateY),
                child: PopScope(
                  canPop: _swipeBackController.value < 0.1,
                  onPopInvokedWithResult: (didPop, result) {
                    if (didPop && result != "gesture_pop") {
                      widget.onReturnFromPage?.call(widget.pageType);
                    }
                  },
                  child: widget.child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
