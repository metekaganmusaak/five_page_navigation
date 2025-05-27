import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'configs/page_preview_style.dart';
import 'configs/return_button_style.dart';
import 'enums/page_type.dart';
import 'enums/swipe_direction.dart';
import 'enums/threshold_vibration.dart';
import 'page_wrapper.dart';

/// A controller for the [FivePageNavigator] to programmatically trigger page changes.
///
/// This controller allows developers to imperatively control the navigation
/// within the [FivePageNavigator], initiating swipes to side pages or
/// returning to the center page without user gesture.
class FivePageController extends ChangeNotifier {
  // A private reference to the state of the FivePageNavigator widget.
  // This allows the controller to call methods on the state.
  _FivePageNavigatorState? _state;

  /// Attaches this controller to a [_FivePageNavigatorState].
  ///
  /// This method is called internally by the [FivePageNavigator] when it's initialized.
  void _attach(_FivePageNavigatorState state) {
    _state = state;
  }

  /// Detaches this controller from its [_FivePageNavigatorState].
  ///
  /// This method is called internally when the [FivePageNavigator] is disposed.
  void _detach() {
    _state = null;
  }

  /// Programmatically navigates to the left page.
  ///
  /// This action is only effective if the navigator is currently displaying
  /// the [PageType.center] page and no other navigation or animation is in progress.
  /// If the `leftPage` is not provided in `FivePageNavigator`, this will have no effect.
  void navigateLeft() {
    _state?.programmaticNavigate(PageType.left);
  }

  /// Programmatically navigates to the right page.
  ///
  /// This action is only effective if the navigator is currently displaying
  /// the [PageType.center] page and no other navigation or animation is in progress.
  /// If the `rightPage` is not provided in `FivePageNavigator`, this will have no effect.
  void navigateRight() {
    _state?.programmaticNavigate(PageType.right);
  }

  /// Programmatically navigates to the top page.
  ///
  /// This action is only effective if the navigator is currently displaying
  /// the [PageType.center] page and no other navigation or animation is in progress.
  /// If the `topPage` is not provided in `FivePageNavigator`, this will have no effect.
  void navigateTop() {
    _state?.programmaticNavigate(PageType.top);
  }

  /// Programmatically navigates to the bottom page.
  ///
  /// This action is only effective if the navigator is currently displaying
  /// the [PageType.center] page and no other navigation or animation is in progress.
  /// If the `bottomPage` is not provided in `FivePageNavigator`, this will have no effect.
  void navigateBottom() {
    _state?.programmaticNavigate(PageType.bottom);
  }

  /// Programmatically returns to the center page from the currently displayed side page.
  ///
  /// This action is only effective if a side page is currently displayed and
  /// no swipe or animation is already in progress.
  Future<void> returnToCenter() async {
    await _state?.programmaticReturnToCenter();
  }

  /// Returns the currently active [PageType] being displayed by the navigator.
  ///
  /// Defaults to [PageType.center] if the controller is not yet attached
  /// or if the state is unavailable.
  PageType get currentPage => _state?._currentPageType ?? PageType.center;
}

/// A custom navigator widget that allows swiping between a center page
/// and four surrounding pages (left, right, top, bottom).
///
/// This widget provides a unique navigation experience where users can
/// intuitively swipe to access related content. It includes features like
/// customizable swipe thresholds, haptic feedback, side page previews,
/// and programmatic control.
class FivePageNavigator extends StatefulWidget {
  /// The main page displayed in the center of the navigator.
  final Widget centerPage;

  /// The page to be displayed when swiping to the left. Can be null if no left page is desired.
  final Widget? leftPage;

  /// The page to be displayed when swiping to the right. Can be null if no right page is desired.
  final Widget? rightPage;

  /// The page to be displayed when swiping upwards. Can be null if no top page is desired.
  final Widget? topPage;

  /// The page to be displayed when swiping downwards. Can be null if no bottom page is desired.
  final Widget? bottomPage;

  /// The fraction of the screen width/height that a swipe must cover to trigger navigation.
  ///
  /// For example, a value of 0.25 means the user must drag 25% of the screen
  /// dimension in the swipe direction for the navigation to commit.
  final double swipeThreshold;

  /// Callback invoked when the active page changes.
  ///
  /// Provides the [PageType] of the newly active page.
  final Function(PageType)? onPageChanged;

  /// The height of the vertical detection area at the top and bottom edges
  /// where vertical swipes are initiated from the center page.
  ///
  /// For example, if a swipe starts within the top `verticalDetectionAreaHeight`
  /// and is primarily vertical, it will be considered a swipe to the top page.
  final double verticalDetectionAreaHeight;

  /// The width of the horizontal detection area at the left and right edges
  /// where horizontal swipes are initiated from the center page.
  ///
  /// Similar to `verticalDetectionAreaHeight`, but for horizontal swipes.
  final double horizontalDetectionAreaWidth;

  /// Enables or disables the swipe-back gesture from the left page to return to center.
  final bool enableLeftPageSwipeBack;

  /// Enables or disables the swipe-back gesture from the right page to return to center.
  final bool enableRightPageSwipeBack;

  /// Enables or disables the swipe-back gesture from the top page to return to center.
  final bool enableTopPageSwipeBack;

  /// Enables or disables the swipe-back gesture from the bottom page to return to center.
  final bool enableBottomPageSwipeBack;

  /// An optional callback function that determines if a swipe gesture from the
  /// center page should be allowed.
  ///
  /// If this function returns `false`, gestures from the center page will be ignored.
  /// If `null`, swipes are always allowed by default.
  final bool Function()? canSwipeFromCenter;

  /// The type of haptic feedback (vibration) to provide when the swipe threshold is met.
  final ThresholdVibration thresholdFeedback;

  /// Callback invoked when the navigator successfully returns to the center page.
  ///
  /// This happens after completing a swipe-back gesture or programmatic return.
  final VoidCallback? onReturnCenterPage;

  /// Callback invoked when the left page is opened (becomes the active page).
  final VoidCallback? onLeftPageOpened;

  /// Callback invoked when the right page is opened (becomes the active page).
  final VoidCallback? onRightPageOpened;

  /// Callback invoked when the top page is opened (becomes the active page).
  final VoidCallback? onTopPageOpened;

  /// Callback invoked when the bottom page is opened (becomes the active page).
  final VoidCallback? onBottomPageOpened;

  /// Determines if a preview of the destination side page should be shown
  /// during a swipe gesture from the center.
  final bool showSidePagePreviews;

  /// Optional configuration for the appearance and behavior of side page previews.
  ///
  /// If `null`, a default preview style will be used.
  final PagePreviewStyle? pagePreviewStyle;

  /// The starting opacity of the incoming page (either a side page during swipe-in
  /// or the center page during swipe-back).
  ///
  /// The page fades in from this opacity to 1.0.
  final double incomingPageOpacityStart;

  /// Determines if the center page should animate its entrance opacity when the
  /// navigator is first built.
  final bool animateCenterPageEntranceOpacity;

  /// The duration of the center page entrance opacity animation.
  ///
  /// This property only applies if `animateCenterPageEntranceOpacity` is `true`.
  final Duration centerPageEntranceAnimationDuration;

  /// Determines if a button to return to the center page should be displayed
  /// on the side pages.
  final bool showReturnToCenterButton;

  /// Optional configuration for the return-to-center button's appearance and behavior.
  ///
  /// If `null`, a default button style will be used.
  final ReturnButtonStyle? returnButtonStyle;

  /// An optional [FivePageController] to programmatically control the navigator.
  final FivePageController? controller;

  const FivePageNavigator({
    super.key,
    required this.centerPage,
    this.leftPage,
    this.rightPage,
    this.topPage,
    this.bottomPage,
    this.swipeThreshold = 0.25,
    this.onPageChanged,
    this.verticalDetectionAreaHeight = 200.0,
    this.horizontalDetectionAreaWidth = 100.0,
    this.enableLeftPageSwipeBack = false,
    this.enableRightPageSwipeBack = false,
    this.enableTopPageSwipeBack = false,
    this.enableBottomPageSwipeBack = false,
    this.canSwipeFromCenter,
    this.thresholdFeedback = ThresholdVibration.heavy,
    this.onReturnCenterPage,
    this.onLeftPageOpened,
    this.onRightPageOpened,
    this.onTopPageOpened,
    this.onBottomPageOpened,
    this.showSidePagePreviews = false,
    this.pagePreviewStyle,
    this.incomingPageOpacityStart = 0.1,
    this.animateCenterPageEntranceOpacity = false,
    this.centerPageEntranceAnimationDuration = kThemeAnimationDuration,
    this.showReturnToCenterButton = false,
    this.returnButtonStyle,
    this.controller,
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
  /// Flag to ensure haptic feedback is triggered only once per swipe gesture.
  bool _hasTriggerHapticFeedback = false;

  /// Controls the animation for the swipe transition between pages.
  ///
  /// Its value represents the progress of the swipe (0.0 = center page visible, 1.0 = side page visible).
  late AnimationController _swipeTransitionController;

  /// The current normalized progress of the user's swipe gesture (0.0 to 1.0).
  ///
  /// Negative values are clamped to 0.0, and values > 1.0 are clamped to 1.0.
  double _swipeProgress = 0.0;

  /// The determined direction of the current swipe gesture, if any.
  SwipeDirection? _currentSwipeDirection;

  /// The local position where the drag gesture initially started.
  Offset? _dragStartPosition;

  /// A [ValueNotifier] to manage the state of whether the navigator is currently
  /// animating a return to the center page.
  late ValueNotifier<bool> _isReturningToCenterNotifier;

  /// Stores the type of page that is currently returning to the center.
  PageType? _returningFromPageType;

  /// The effective [PagePreviewStyle] being used, either from widget properties or a default.
  late PagePreviewStyle _effectivePreviewConfig;

  /// Controls the initial entrance opacity animation for the center page.
  AnimationController? _centerPageEntranceController;

  /// The animation for the center page's opacity during its initial entrance.
  Animation<double>? _centerPageEntranceOpacityAnimation;

  /// The currently active [PageType] displayed by the navigator.
  PageType _currentPageType = PageType.center;

  /// The fixed duration for page transition animations (swipe-in and swipe-out).
  static const Duration _fixedSwipeAnimationDuration =
      Duration(milliseconds: 300);

  /// A small threshold to determine if a drag is primarily horizontal or vertical.
  /// Drags below this delta do not lock a direction.
  static const double _directionLockThreshold = 5.0;

  @override
  void initState() {
    super.initState();
    _effectivePreviewConfig =
        widget.pagePreviewStyle ?? const PagePreviewStyle();

    _swipeTransitionController = AnimationController(
      duration: _fixedSwipeAnimationDuration,
      vsync: this,
    );

    // Initialize the ValueNotifier for the returning-to-center state.
    _isReturningToCenterNotifier = ValueNotifier<bool>(false);

    // Initialize the center page entrance animation if enabled.
    if (widget.animateCenterPageEntranceOpacity) {
      _centerPageEntranceController = AnimationController(
        duration: widget.centerPageEntranceAnimationDuration,
        vsync: this,
      );
      // Start the animation after the first frame is rendered.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _centerPageEntranceController?.forward();
        }
      });
      _centerPageEntranceOpacityAnimation =
          Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _centerPageEntranceController!,
          curve: Curves.easeIn,
        ),
      );
    }

    // Attach the controller if provided.
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant FivePageNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update effective preview config if it changes.
    if (widget.pagePreviewStyle != oldWidget.pagePreviewStyle) {
      _effectivePreviewConfig =
          widget.pagePreviewStyle ?? const PagePreviewStyle();
    }
    // Handle controller re-attachment if the controller instance changes.
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    _swipeTransitionController.dispose();
    _centerPageEntranceController?.dispose();
    _isReturningToCenterNotifier.dispose();
    widget.controller?._detach();
    super.dispose();
  }

  /// Provides debugging information for the widget's properties.
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
    properties.add(DiagnosticsProperty<ReturnButtonStyle?>(
        'returnButtonConfig', widget.returnButtonStyle));
    properties.add(
        DiagnosticsProperty<PageType>('_currentPageType', _currentPageType));
    properties.add(DiagnosticsProperty<FivePageController?>(
        'controller', widget.controller));
  }

  //* --- Gesture Handling ---

  /// Handles the beginning of a pan gesture.
  ///
  /// Initializes drag state, but only if no animations are running and
  /// the current page is the center page, and `canSwipeFromCenter` allows it.
  void _handlePanStart(DragStartDetails details) {
    // Prevent new drags if an animation is already in progress or returning to center.
    if (_swipeTransitionController.isAnimating ||
        _isReturningToCenterNotifier.value) {
      _dragStartPosition = null;
      return;
    }
    // Only allow swipe from the center page.
    if (_currentPageType != PageType.center) {
      _dragStartPosition = null;
      return;
    }
    // Consult the `canSwipeFromCenter` callback if provided.
    bool canSwipe = widget.canSwipeFromCenter?.call() ?? true;
    if (!canSwipe) {
      _dragStartPosition = null;
      return;
    }
    // Initialize drag state.
    _dragStartPosition = details.localPosition;
    _currentSwipeDirection = null;
    _swipeProgress = 0.0;
    _hasTriggerHapticFeedback = false;
    _swipeTransitionController.value = 0.0;
  }

  /// Handles updates during a pan gesture.
  ///
  /// Calculates the swipe progress, determines the swipe direction (if not already set),
  /// and updates the animation controller's value accordingly.
  /// Also triggers haptic feedback when the `swipeThreshold` is met.
  void _handlePanUpdate(DragUpdateDetails details) {
    // Do nothing if drag hasn't started, or an animation is already active, or returning to center.
    if (_dragStartPosition == null ||
        _swipeTransitionController.isAnimating ||
        _isReturningToCenterNotifier.value) {
      return;
    }

    final screenSize = MediaQuery.sizeOf(context);

    // Determine the swipe direction if it hasn't been locked yet.
    if (_currentSwipeDirection == null) {
      _determineSwipeDirection(details, screenSize);
    }

    // If a direction is determined, update swipe progress.
    if (_currentSwipeDirection != null) {
      double delta; // Change in position along the relevant axis.
      double dimension; // Total screen dimension along the relevant axis.

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

      // Calculate progress delta, clamping it to valid range (-1.0 to 1.0).
      double progressDelta = delta / dimension;
      if (_currentSwipeDirection == SwipeDirection.left ||
          _currentSwipeDirection == SwipeDirection.up) {
        _swipeProgress += progressDelta;
        _swipeProgress =
            _swipeProgress.clamp(-1.0, 0.0); // Swiping 'into' negative space
      } else {
        _swipeProgress += progressDelta;
        _swipeProgress =
            _swipeProgress.clamp(0.0, 1.0); // Swiping 'into' positive space
      }

      if (!mounted) return; // Ensure widget is still in the tree.

      // Update the animation controller value based on absolute swipe progress.
      _swipeTransitionController.value = _swipeProgress.abs();

      // Trigger haptic feedback if threshold is met and not yet triggered.
      if (_swipeTransitionController.value >= widget.swipeThreshold &&
          !_hasTriggerHapticFeedback) {
        _triggerHapticFeedback(widget.thresholdFeedback);
        _hasTriggerHapticFeedback = true;
      } else if (_swipeTransitionController.value < widget.swipeThreshold) {
        // Reset haptic feedback flag if swipe falls below threshold.
        _hasTriggerHapticFeedback = false;
      }
    }
  }

  /// Determines the primary swipe direction (horizontal or vertical) and
  /// locks it for the duration of the gesture.
  ///
  /// This prevents accidental diagonal swipes from triggering unexpected navigations.
  void _determineSwipeDirection(DragUpdateDetails details, Size screenSize) {
    final startX = _dragStartPosition!.dx;
    final startY = _dragStartPosition!.dy;
    final currentX = details.localPosition.dx;
    final currentY = details.localPosition.dy;
    final totalDeltaX = currentX - startX;
    final totalDeltaY = currentY - startY;
    final absDeltaX = totalDeltaX.abs();
    final absDeltaY = totalDeltaY.abs();

    if (absDeltaX > _directionLockThreshold ||
        absDeltaY > _directionLockThreshold) {
      if (absDeltaX > absDeltaY) {
        // Horizontal swipe detected.
        // Check if swipe originates from a valid horizontal detection area.
        if (totalDeltaX > 0 &&
            startX < widget.horizontalDetectionAreaWidth &&
            widget.leftPage != null) {
          // Swipe right to reveal left page.
          _currentSwipeDirection = SwipeDirection.right;
        } else if (totalDeltaX < 0 &&
            startX > screenSize.width - widget.horizontalDetectionAreaWidth &&
            widget.rightPage != null) {
          // Swipe left to reveal right page.
          _currentSwipeDirection = SwipeDirection.left;
        }
      } else {
        // Vertical swipe detected.
        // Check if swipe originates from a valid vertical detection area.
        if (totalDeltaY > 0 &&
            startY < widget.verticalDetectionAreaHeight &&
            widget.topPage != null) {
          // Swipe down to reveal top page.
          _currentSwipeDirection = SwipeDirection.down;
        } else if (totalDeltaY < 0 &&
            startY > screenSize.height - widget.verticalDetectionAreaHeight &&
            widget.bottomPage != null) {
          // Swipe up to reveal bottom page.
          _currentSwipeDirection = SwipeDirection.up;
        }
      }
    }
  }

  /// Handles the end of a pan gesture.
  ///
  /// Based on the final swipe progress, it decides whether to complete the
  /// navigation to the new page or snap back to the center page.
  void _handlePanEnd(DragEndDetails details) {
    // Do nothing if no swipe direction was determined, animation is running, or returning.
    if (_currentSwipeDirection == null ||
        _swipeTransitionController.isAnimating ||
        _isReturningToCenterNotifier.value) {
      if (!_isReturningToCenterNotifier.value) {
        // Ensure state is clean.
        _resetDragState();
      }
      return;
    }
    _hasTriggerHapticFeedback = false; // Reset for next swipe.

    final swipeProgress = _swipeTransitionController.value;
    if (swipeProgress >= widget.swipeThreshold) {
      // If threshold met, animate to the target page.
      _animateToPage();
    } else {
      // Otherwise, animate back to the center.
      _animateBackToCenter();
    }
  }

  // --- State Resets ---

  /// Resets the internal state related to the swipe gesture.
  ///
  /// [keepControllerValue]: If `true`, the `_swipeTransitionController`'s
  /// value is not reset to 0.0, useful when another animation takes over.
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

  /// Resets the internal state related to returning to the center page.
  ///
  /// This is called after a return animation completes.
  void _resetReturnState() {
    if (mounted) {
      // Update the ValueNotifier directly. This will trigger a rebuild for consumers.
      _isReturningToCenterNotifier.value = false;
      _returningFromPageType = null;
      _currentSwipeDirection =
          null; // Ensure direction is cleared for next swipe.
      _swipeProgress = 0.0;
      _dragStartPosition = null;

      if (_swipeTransitionController.isAnimating) {
        _swipeTransitionController.stop();
      }
      _swipeTransitionController.value = 0.0;
    }
  }

  // --- Animation and Navigation ---

  /// Triggers haptic feedback based on the specified [ThresholdVibration] type.
  void _triggerHapticFeedback(ThresholdVibration feedbackType) {
    switch (feedbackType) {
      case ThresholdVibration.soft:
        HapticFeedback.lightImpact();
        break;
      case ThresholdVibration.medium:
        HapticFeedback.mediumImpact();
        break;
      case ThresholdVibration.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  /// Initiates the animation to transition to the target side page.
  ///
  /// This method is called when a swipe gesture successfully crosses the `swipeThreshold`.
  void _animateToPage() {
    // Prevent starting animation if no direction or already animating.
    if (_currentSwipeDirection == null ||
        _swipeTransitionController.isAnimating) {
      return;
    }

    // Determine the target page type based on the swipe direction.
    PageType? targetPageType =
        _getPageTypeFromSwipeDirection(_currentSwipeDirection!);

    // If target page is null (e.g., no widget provided), snap back.
    if (targetPageType == null ||
        _getPageWidgetByType(targetPageType) == null) {
      debugPrint(
          "Attempted to navigate to a non-existent page: $targetPageType. Snapping back.");
      _animateBackToCenter();
      return;
    }

    // Animate the swipe transition controller to its forward (1.0) state.
    _swipeTransitionController
        .forward(from: _swipeTransitionController.value)
        .then((_) {
      if (mounted) {
        // After animation completes, perform the actual page navigation (push route).
        _navigateToPageActual();
      }
    }).catchError((error) {
      // Handle potential animation errors.
      if (mounted) {
        debugPrint('Animation forward error: $error');
        _resetDragState(); // Reset state on error.
      }
    });
  }

  /// Initiates the animation to snap back to the center page.
  ///
  /// This method is called when a swipe gesture does not meet the `swipeThreshold`.
  void _animateBackToCenter() {
    // Prevent starting animation if no direction or already animating.
    if (_currentSwipeDirection == null ||
        _swipeTransitionController.isAnimating) {
      return;
    }

    // Animate the swipe transition controller back to its reverse (0.0) state.
    _swipeTransitionController
        .reverse(from: _swipeTransitionController.value)
        .then((_) {
      if (mounted) {
        _resetDragState(); // Reset drag state after snapping back.
      }
    }).catchError((error) {
      // Handle potential animation errors.
      if (mounted) {
        debugPrint('Animation reverse error: $error');
        _resetDragState(); // Reset state on error.
      }
    });
  }

  /// Handles the return to center from a side page.
  ///
  /// This callback is passed to `PageWrapper` and is invoked when a `PageWrapper`
  /// route is popped (either by its own gesture, button, or system back).
  /// It orchestrates the reverse animation to show the center page coming back into view.
  ///
  /// [returnedFrom]: The [PageType] of the page that is being returned from.
  /// [popResult]: An optional result from the `Navigator.pop` operation.
  ///   This is crucial for determining if the animation is needed here, as
  ///   some pops (like gesture swipe-back from `PageWrapper`) already handle
  ///   the animation, and we should avoid double animating.
  void _handleReturnFromPage(PageType returnedFrom, dynamic popResult) {
    if (!mounted) return;

    // Check if the pop was initiated by a swipe-back gesture from PageWrapper.
    // If so, PageWrapper has already handled the animation, so we just update state.
    if (popResult is Map && popResult["type"] == "gesture_pop_completed") {
      debugPrint(
          "[_handleReturnFromPage] Handling gesture_pop_completed. Skipping animation.");
      if (_swipeTransitionController.isAnimating) {
        _swipeTransitionController.stop(); // Stop any lingering animation.
      }
      // Update the ValueNotifier directly to trigger a rebuild and reset state.
      _isReturningToCenterNotifier.value = false;
      _currentPageType =
          PageType.center; // Ensure current page type is updated.
      widget.onReturnCenterPage?.call(); // Notify parent of return.
      return; // DO NOT perform another animation.
    }

    // For button-initiated or programmatic pops, or system back, we need to animate.
    // Prevent starting a new animation if one is already active or we are already returning.
    if (_swipeTransitionController.isAnimating ||
        _isReturningToCenterNotifier.value) {
      debugPrint(
          "[_handleReturnFromPage] Navigator is already busy for non-gesture pop.");
      return;
    }

    // Update the ValueNotifier. This will trigger a rebuild of _buildSwipeContent
    // to switch to the "returning to center" animation logic.
    _isReturningToCenterNotifier.value = true;
    _returningFromPageType = returnedFrom;
    // Determine the direction the center page should animate *from*.
    _currentSwipeDirection = _getReverseSwipeDirection(returnedFrom);
    _swipeTransitionController.value =
        1.0; // Start animation from fully revealed state.

    // Notify page changed to center immediately as the transition begins.
    widget.onPageChanged?.call(PageType.center);

    // Animate the controller in reverse to show the center page.
    _swipeTransitionController.reverse(from: 1.0).then((_) {
      if (mounted) {
        _resetReturnState(); // This will set _isReturningToCenterNotifier.value = false.
        widget.onReturnCenterPage?.call(); // Notify parent of return.
        _currentPageType = PageType.center; // Explicitly set current page.
      }
    }).catchError((error) {
      // Handle animation errors.
      if (mounted) {
        debugPrint(
            'Animation reverse error (from _handleReturnFromPage): $error');
        _resetReturnState();
        _currentPageType = PageType.center;
      }
    });
  }

  /// Pushes the target side page onto the navigator stack.
  ///
  /// This method is called after the initial swipe-in animation completes.
  /// It wraps the target page in a [PageWrapper] to handle swipe-back gestures
  /// and the return button.
  void _navigateToPageActual() {
    // Do nothing if no direction or not mounted.
    if (_currentSwipeDirection == null || !mounted) {
      _resetDragState();
      return;
    }

    PageType targetPageType;
    Widget? targetPageWidget;
    bool enableSwipeBackForTarget = false;

    // Determine the actual page widget and its swipe-back enablement.
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

    // If target page is unexpectedly null, snap back.
    if (targetPageWidget == null) {
      debugPrint(
          "Attempted to navigate to a null page in _navigateToPageActual. Snapping back.");
      _animateBackToCenter();
      return;
    }

    _currentPageType = targetPageType; // Update current page type.

    // Push the PageWrapper route. Using PageRouteBuilder with zero duration
    // ensures our custom animations manage the transition.
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque:
            false, // Allows content underneath to be seen during transitions.
        pageBuilder: (ctx, anim, secAnim) => PageWrapper(
          pageType: targetPageType,
          onReturnFromPage:
              _handleReturnFromPage, // Callback for when PageWrapper is popped.
          enableSwipeBack: enableSwipeBackForTarget,
          centerPage: widget.centerPage,
          vibration: widget.thresholdFeedback, // Corrected parameter name
          showReturnToCenterButton: widget.showReturnToCenterButton,
          returnButtonConfig: widget.returnButtonStyle,
          incomingPageOpacityStart: widget.incomingPageOpacityStart,
          child: targetPageWidget!, // The actual side page content.
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        barrierColor:
            Colors.black, // A dark barrier to prevent visual artifacts.
        barrierLabel: 'Barrier',
      ),
    ).then((result) {
      // This `.then` block is called when the pushed PageWrapper route is popped.
      // `_handleReturnFromPage` is the primary handler for all pops and animations.
      // This block acts as a fallback to ensure state consistency if
      // `_isReturningToCenterNotifier.value` wasn't set correctly (e.g., if a pop occurred
      // that wasn't properly routed through `onPopInvokedWithResult` or a button press).
      if (!mounted) return;
      if (!_isReturningToCenterNotifier.value) {
        // Check notifier value
        _resetReturnState();
        _currentPageType = PageType.center;
        widget.onReturnCenterPage?.call();
      }
    });

    _resetDragState(keepControllerValue: false); // Reset drag state.

    // Invoke callbacks for page change and page opened.
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
      case PageType.center: // Should not happen here.
        break;
    }
  }

  /// Programmatically initiates a swipe to a target page from the center page.
  ///
  /// This method is typically called via [FivePageController].
  /// Does nothing if not currently on the center page or if a swipe is in progress.
  ///
  /// [targetPage]: The [PageType] of the page to navigate to.
  void programmaticNavigate(PageType targetPage) {
    // Check preconditions for programmatic navigation.
    if (!mounted ||
        _currentPageType != PageType.center || // Must be on center page.
        _swipeTransitionController.isAnimating ||
        _isReturningToCenterNotifier.value) {
      // Check notifier value
      debugPrint(
          "Programmatic navigation to $targetPage ignored: Not on center page or navigator is busy.");
      return;
    }

    // Determine the necessary swipe direction to reveal the target page.
    final SwipeDirection? swipeDir =
        _getSwipeDirectionForTargetPage(targetPage);
    // If no valid direction or target page is null, ignore.
    if (swipeDir == null || _getPageWidgetByType(targetPage) == null) {
      debugPrint(
          "Programmatic navigation ignored: Target page $targetPage is null or no swipe direction for center.");
      return;
    }

    // Simulate a drag start and set current swipe direction and full progress.
    _dragStartPosition = Offset.zero; // A dummy start position.
    _currentSwipeDirection = swipeDir;
    _swipeProgress = 1.0; // Ensures the animation proceeds to completion.
    _hasTriggerHapticFeedback = false; // Reset haptic feedback.
    _swipeTransitionController.value = 0.0; // Start animation from 0.

    // Trigger the navigation animation and subsequent route push.
    _animateToPage();
  }

  /// Programmatically returns to the center page from the currently displayed side page.
  ///
  /// This method is typically called via [FivePageController].
  /// It triggers a `Navigator.pop` operation for the currently active side page route.
  /// The `_handleReturnFromPage` callback will then manage the return animation.
  Future<void> programmaticReturnToCenter() async {
    // Check preconditions for programmatic return.
    if (!mounted ||
        _currentPageType == PageType.center || // Must be on a side page.
        _swipeTransitionController.isAnimating ||
        _isReturningToCenterNotifier.value) {
      // Check notifier value
      debugPrint("Programmatic return ignored: already center or animating.");
      return Future.value(); // Return a completed future if no action taken.
    }
    // Perform a pop operation. The `_navigateToPageActual().then()` block
    // and `_handleReturnFromPage` will handle the animation and state changes.
    // We pass a simple string result for debugging/tracking.
    return Navigator.of(context).pop("controller_return_pop");
  }

  // --- Helper Functions ---

  /// Determines the [SwipeDirection] required to *reveal* a given [targetType] page
  /// from the center.
  ///
  /// Returns `null` if the target is [PageType.center] (cannot swipe to center).
  SwipeDirection? _getSwipeDirectionForTargetPage(PageType targetType) {
    switch (targetType) {
      case PageType.left:
        return SwipeDirection
            .right; // To see the left page, one must swipe right.
      case PageType.right:
        return SwipeDirection
            .left; // To see the right page, one must swipe left.
      case PageType.top:
        return SwipeDirection.down; // To see the top page, one must swipe down.
      case PageType.bottom:
        return SwipeDirection.up; // To see the bottom page, one must swipe up.
      case PageType.center:
        return null; // Cannot "swipe" to center; only return.
    }
  }

  /// Determines the reverse [SwipeDirection] from a given [fromPage].
  ///
  /// This is used to calculate the direction the center page should animate
  /// from when returning from a side page.
  SwipeDirection? _getReverseSwipeDirection(PageType fromPage) {
    switch (fromPage) {
      // If coming from left, center moves right.
      case PageType.left:
        return SwipeDirection.right;
      // If coming from right, center moves left.
      case PageType.right:
        return SwipeDirection.left;
      // If coming from top, center moves down.
      case PageType.top:
        return SwipeDirection.down;
      // If coming from bottom, center moves up.
      case PageType.bottom:
        return SwipeDirection.up;
      // No reverse direction from center.
      case PageType.center:
        return null;
    }
  }

  /// Calculates the final offset for the center page when it is pushed off-screen
  /// during a swipe to a side page.
  ///
  /// [dir]: The direction the center page is being pushed.
  /// [s]: The size of the screen.
  Offset _getCenterPageEndOffset(SwipeDirection dir, Size s) {
    switch (dir) {
      case SwipeDirection.left:
        return Offset(-s.width, 0); // Center moves left.
      case SwipeDirection.right:
        return Offset(s.width, 0); // Center moves right.
      case SwipeDirection.up:
        return Offset(0, -s.height); // Center moves up.
      case SwipeDirection.down:
        return Offset(0, s.height); // Center moves down.
    }
  }

  /// Calculates the starting off-screen offset for an incoming side page.
  ///
  /// [dir]: The direction the side page is coming *from*.
  /// [s]: The size of the screen.
  Offset _getOffScreenOffset(SwipeDirection dir, Size s) {
    switch (dir) {
      case SwipeDirection.left:
        // Side page comes from right to fill center.
        return Offset(s.width, 0);
      case SwipeDirection.right:
        // Side page comes from left to fill center.
        return Offset(-s.width, 0);
      case SwipeDirection.up:
        // Side page comes from bottom to fill center.
        return Offset(0, s.height);
      case SwipeDirection.down:
        // Side page comes from top to fill center.
        return Offset(0, -s.height);
    }
  }

  /// Retrieves the [Widget] corresponding to the given [targetType] (side page).
  ///
  /// Returns `null` if the target is [PageType.center] or if no widget is provided.
  Widget? _getSwipingPageWidget(PageType targetType) {
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
        return null;
    }
  }

  /// Builds or retrieves the preview widget for a given swipe direction.
  ///
  /// If a custom preview widget is provided in `_effectivePreviewConfig`, it's used.
  /// Otherwise, a default [Material] chip with a label is created.
  /// [direction]: The [SwipeDirection] indicating which page's preview is needed.
  Widget _getPreviewWidgetOrBuildDefault(SwipeDirection direction) {
    Widget? customPreviewWidget;
    String defaultLabel = "";

    Alignment alignment;

    // Determine the correct preview widget and label based on swipe direction.
    // Note: SwipeDirection.left means swiping left *to reveal* the right page.
    switch (direction) {
      case SwipeDirection.left:
        customPreviewWidget = _effectivePreviewConfig.rightPagePreviewWidget;
        defaultLabel = _effectivePreviewConfig.rightPageLabel;
        alignment = Alignment.centerRight;
        break;
      case SwipeDirection.right:
        customPreviewWidget = _effectivePreviewConfig.leftPagePreviewWidget;
        defaultLabel = _effectivePreviewConfig.leftPageLabel;
        alignment = Alignment.centerLeft;
        break;
      case SwipeDirection.up:
        customPreviewWidget = _effectivePreviewConfig.bottomPagePreviewWidget;
        defaultLabel = _effectivePreviewConfig.bottomPageLabel;
        alignment = Alignment.bottomCenter;
        break;
      case SwipeDirection.down:
        customPreviewWidget = _effectivePreviewConfig.topPagePreviewWidget;
        defaultLabel = _effectivePreviewConfig.topPageLabel;
        alignment = Alignment.topCenter;
        break;
    }

    // Return custom widget if available, otherwise build default.
    if (customPreviewWidget != null) {
      return Material(
        type: MaterialType.transparency, // Allows background to show through.
        child: customPreviewWidget,
      );
    }

    // Default preview chip.
    return Align(
      alignment: alignment,
      child: Material(
        type: MaterialType.transparency,
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
                  fontSize: 14,
                ),
          ),
        ),
      ),
    );
  }

  /// Retrieves the [Widget] associated with a given [PageType].
  ///
  /// This acts as a central lookup for all pages provided to the navigator.
  Widget? _getPageWidgetByType(PageType type) {
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

  /// Determines the [PageType] that would be revealed by a given [SwipeDirection].
  ///
  /// Returns `null` if no page is configured for that direction.
  PageType? _getPageTypeFromSwipeDirection(SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.left:
        return widget.rightPage != null ? PageType.right : null;
      case SwipeDirection.right:
        return widget.leftPage != null ? PageType.left : null;
      case SwipeDirection.up:
        return widget.bottomPage != null ? PageType.bottom : null;
      case SwipeDirection.down:
        return widget.topPage != null ? PageType.top : null;
    }
  }

  /// Returns the center page widget, wrapped in an [AnimatedBuilder] if
  /// `animateCenterPageEntranceOpacity` is true.
  Widget _getAnimatedCenterPage() {
    if (!widget.animateCenterPageEntranceOpacity ||
        _centerPageEntranceController == null) {
      return widget.centerPage;
    }

    return AnimatedBuilder(
      animation: _centerPageEntranceOpacityAnimation!,
      builder: (context, child) {
        return AnimatedOpacity(
          duration: widget.centerPageEntranceAnimationDuration,
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
    // The outermost [ListenableBuilder] listens to the main animation controller,
    // which drives the overall swipe progress.
    return ListenableBuilder(
      listenable: _swipeTransitionController,
      builder: (context, _) {
        // The inner [ValueListenableBuilder] listens specifically to changes in
        // the `_isReturningToCenterNotifier`. This allows the `_buildSwipeContent`
        // to switch between "swiping out" and "returning in" logic without
        // rebuilding the entire `GestureDetector` wrapper each time the flag changes.
        return ValueListenableBuilder<bool>(
          valueListenable: _isReturningToCenterNotifier,
          builder: (context, isReturningToCenter, __) {
            // [GestureDetector] handles all pan (drag) gestures for navigation.
            return GestureDetector(
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              behavior: HitTestBehavior
                  .opaque, // Ensures gestures are captured even in empty spaces.
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                // Calls a helper method to build the dynamic content based on
                // animation progress and the returning state.
                child: _buildSwipeContent(
                    _swipeTransitionController.value, isReturningToCenter),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the content displayed during swipe (drag) and swipe transitions.
  ///
  /// This method is responsible for rendering the center page, the incoming side page,
  /// and the preview overlay based on the current `animationProgress` and state.
  ///
  /// [animationProgress]: The current value of the `_swipeTransitionController` (0.0 to 1.0).
  /// [isReturningToCenter]: A boolean indicating if the navigator is currently animating
  ///   a return from a side page to the center.
  Widget _buildSwipeContent(
      double animationProgress, bool isReturningToCenter) {
    final size = MediaQuery.sizeOf(context);
    List<Widget> stackChildren = [];

    // The center page, potentially with an entrance opacity animation.
    final Widget animatedCenterPage = _getAnimatedCenterPage();

    if (isReturningToCenter) {
      // Logic for animating back to the center page from a side page.
      Widget pageComingOnScreen = widget.centerPage;
      Widget pageGoingOffScreen =
          _getPageWidgetByType(_returningFromPageType!)!; // The side page.
      SwipeDirection effectiveDirection = _currentSwipeDirection!;

      // Calculate offsets for the center page coming back into view.
      final centerPushedOffset =
          _getCenterPageEndOffset(effectiveDirection, size);
      // `incomingPageProgress` goes from 0.0 to 1.0 as center page comes into view.
      final incomingPageProgress = 1.0 - animationProgress;
      final offsetForOnScreen =
          Offset.lerp(centerPushedOffset, Offset.zero, incomingPageProgress)!;

      // Calculate offsets for the side page going off screen.
      final sideOffScreenOffset = _getOffScreenOffset(effectiveDirection, size);
      final offsetForOffScreen =
          Offset.lerp(Offset.zero, sideOffScreenOffset, incomingPageProgress)!;

      // Add the center page, sliding in and fading in.
      stackChildren.add(
        Transform.translate(
          offset: offsetForOnScreen,
          child: Opacity(
            opacity: lerpDouble(
              widget.incomingPageOpacityStart, // Starts less visible.
              1.0, // Ends fully visible.
              incomingPageProgress,
            )!,
            child: pageComingOnScreen,
          ),
        ),
      );

      // Add the side page, sliding out and fading out.
      stackChildren.add(
        Transform.translate(
          offset: offsetForOffScreen,
          child: Opacity(
            opacity: 1.0 - incomingPageProgress, // Fades out.
            child: pageGoingOffScreen,
          ),
        ),
      );
    } else if (_currentSwipeDirection != null) {
      // Logic for animating from the center page to a side page.
      SwipeDirection effectiveDirection = _currentSwipeDirection!;
      // Determine if a transition animation is actively running to a target page.
      // This helps decide whether to show the preview or the actual incoming page.
      bool isAnimatingToPageCompletion =
          _swipeTransitionController.isAnimating &&
              (_swipeTransitionController.status == AnimationStatus.forward);

      PageType? targetPageType =
          _getPageTypeFromSwipeDirection(effectiveDirection);
      if (targetPageType == null ||
          _getPageWidgetByType(targetPageType) == null) {
        // If target page is invalid, just show center page.
        stackChildren.add(animatedCenterPage);
        return Stack(children: stackChildren);
      }

      if (widget.showSidePagePreviews && !isAnimatingToPageCompletion) {
        // If previews are enabled and not actively animating to completion,
        // show the center page with the preview overlay.
        stackChildren.add(animatedCenterPage);
        if (animationProgress > 0) {
          stackChildren.add(
            Transform.scale(
              scale: 1.0 - animationProgress, // Scale down center page.
              alignment: Alignment.center,
              child: Opacity(
                opacity: lerpDouble(
                  1.0, // Starts fully visible.
                  widget.incomingPageOpacityStart, // Ends less visible.
                  animationProgress,
                )!,
                child: _getPreviewWidgetOrBuildDefault(effectiveDirection),
              ),
            ),
          );
        }
      } else {
        // Otherwise (no previews, or animating to completion), show the
        // center page moving out and the side page moving in.
        Widget pageGoingOffScreen = widget.centerPage;
        // Currently not scaling center page.
        double currentScaleForOffScreen = 1.0;

        // Calculate offset for the center page going off screen.
        final centerEndOffset =
            _getCenterPageEndOffset(effectiveDirection, size);
        final offsetForOffScreen =
            Offset.lerp(Offset.zero, centerEndOffset, animationProgress)!;

        stackChildren.add(Transform.translate(
          offset: offsetForOffScreen,
          child: Transform.scale(
            scale: currentScaleForOffScreen,
            alignment: Alignment.center,
            child: Opacity(
              opacity: lerpDouble(
                1.0, // Starts fully visible.

                widget.incomingPageOpacityStart, // Ends less visible.
                animationProgress,
              )!,
              child: pageGoingOffScreen,
            ),
          ),
        ));

        // Get the target side page widget.
        Widget pageComingOnScreen = _getSwipingPageWidget(targetPageType)!;

        // Calculate starting off-screen offset for the incoming side page.
        final sideStartOffset = _getOffScreenOffset(effectiveDirection, size);

        // Calculate current offset for the incoming side page.
        final offsetForOnScreen = Offset.lerp(
          sideStartOffset,
          Offset.zero, // Ends at center.
          animationProgress,
        )!;

        stackChildren.add(
          Transform.translate(
            offset: offsetForOnScreen,
            child: Opacity(
              opacity: lerpDouble(
                widget.incomingPageOpacityStart, // Starts less visible.
                1.0, // Ends fully visible.
                animationProgress,
              )!,
              child: pageComingOnScreen,
            ),
          ),
        );
      }
    } else {
      // If no swipe is in progress, just display the animated center page.
      stackChildren.add(animatedCenterPage);
    }

    return Stack(children: stackChildren);
  }
}
