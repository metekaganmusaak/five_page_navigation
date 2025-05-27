import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Used for HapticFeedback

import 'configs/return_button_style.dart'; // Custom configuration for return button
import 'enums/page_type.dart'; // Enum for page types
import 'enums/threshold_vibration.dart'; // Enum for haptic feedback types

/// A wrapper widget for the pages displayed as side pages in the [FivePageNavigator].
///
/// This widget enhances the child page with:
/// - An optional swipe-back gesture to return to the center page.
/// - An optional "return to center" button with customizable appearance.
/// - Visual transitions (opacity and position) for both the side page and
///   the underlying center page during a swipe-back.
/// - Integration with the system back button via [PopScope] to ensure smooth
///   navigation state management.
class PageWrapper extends StatefulWidget {
  /// The actual content widget of the side page that this wrapper encloses.
  final Widget child;

  /// The type or position of this page within the navigator's structure
  /// (e.g., [PageType.left], [PageType.right]).
  final PageType pageType;

  /// Callback function invoked when this page is being returned from (popped).
  ///
  /// This signature includes a `dynamic popResult` to provide context about
  /// *how* the page was popped (e.g., via a gesture, button, or system back).
  /// This allows the parent navigator to handle animations appropriately
  /// without redundancy.
  final Function(PageType returnedFrom, dynamic popResult)? onReturnFromPage;

  /// Determines if the swipe-back gesture is enabled for this specific side page.
  /// If `true`, users can swipe from the appropriate edge to return to the center.
  final bool enableSwipeBack;

  /// The main center page widget, which is displayed underneath this side page
  /// and becomes visible during the swipe-back transition.
  final Widget centerPage;

  /// The type of haptic feedback (vibration) to provide when the swipe-back
  /// threshold is met, giving tactile confirmation to the user.
  final ThresholdVibration vibration;

  /// Determines if the dedicated "return to center" button should be shown
  /// on this side page.
  final bool showReturnToCenterButton;

  /// Optional configuration for the "return to center" button.
  /// If `null`, a default button style will be used.
  final ReturnButtonStyle? returnButtonConfig;

  /// The starting opacity of the incoming page (the center page) during the
  /// return transition. The center page fades in from this value to 1.0.
  final double incomingPageOpacityStart;

  const PageWrapper({
    super.key,
    required this.child,
    required this.pageType,
    this.onReturnFromPage,
    this.enableSwipeBack = false,
    required this.centerPage,
    this.vibration = ThresholdVibration.heavy,
    this.showReturnToCenterButton = false,
    this.returnButtonConfig,
    this.incomingPageOpacityStart = 0.1,
  });

  @override
  State<PageWrapper> createState() => _PageWrapperState();
}

class _PageWrapperState extends State<PageWrapper>
    with TickerProviderStateMixin {
  /// Controls the animation for the swipe-back gesture.
  /// Its value represents the progress of the swipe (0.0 = fully on screen, 1.0 = fully off screen).
  late AnimationController _swipeBackController;

  /// The starting position of the drag, used to calculate drag delta for swipe-back.
  double _swipeBackDragStart = 0.0;

  /// A [ValueNotifier] to manage the dragging state of the swipe-back gesture.
  late ValueNotifier<bool> _isSwipeBackDraggingNotifier;

  /// Flag to ensure haptic feedback is triggered only once per swipe-back gesture.
  bool _hasTriggerHapticFeedback = false;

  /// The minimum progress required for the swipe-back gesture to trigger a successful
  /// pop animation (0.0 to 1.0, where 1.0 means fully swiped off).
  static const double _swipeBackPopThreshold = 0.5;

  /// The threshold for the swipe-back gesture progress to trigger haptic feedback.
  static const double _swipeBackHapticThreshold = 0.5;

  /// The width/height of the edge detection area from which a swipe-back gesture
  /// can be initiated.
  late double _horizontalEdgeDetectionAreaWidth;
  late double _verticalEdgeDetectionAreaHeight;

  @override
  void initState() {
    super.initState();
    _swipeBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    // Initialize the ValueNotifier for dragging state
    _isSwipeBackDraggingNotifier = ValueNotifier<bool>(false);

    // Set up a post-frame callback to calculate edge detection area dimensions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.sizeOf(context);
      // 20% of screen width
      _horizontalEdgeDetectionAreaWidth = size.width * 0.2;
      // 20% of screen height
      _verticalEdgeDetectionAreaHeight = size.height * 0.2;
    });
  }

  @override
  void dispose() {
    _swipeBackController.dispose();
    _isSwipeBackDraggingNotifier.dispose();
    super.dispose();
  }

  /// Handles the start of a pan gesture for swipe-back.
  ///
  /// Determines if the drag originated from the correct edge for the current
  /// [pageType] and updates the [_isSwipeBackDraggingNotifier] accordingly.
  void _handlePanStart(DragStartDetails details) {
    // Prevent starting a new gesture if swipe-back is disabled or an animation is already active.
    if (!widget.enableSwipeBack || _swipeBackController.isAnimating) return;

    final size = MediaQuery.sizeOf(context);
    bool isValidSwipeStart = false;

    // Check if the drag starts from the correct edge based on the page type.
    // Each page type has a specific edge from which it can be "un-swiped".
    switch (widget.pageType) {
      case PageType.left:
        // For the left page, initiate swipe-back by dragging from the right edge to the left.
        if (details.localPosition.dx >=
            size.width - _horizontalEdgeDetectionAreaWidth) {
          _swipeBackDragStart = details.localPosition.dx;
          isValidSwipeStart = true;
        }
        break;
      case PageType.right:
        // For the right page, initiate swipe-back by dragging from the left edge to the right.
        if (details.localPosition.dx <= _horizontalEdgeDetectionAreaWidth) {
          _swipeBackDragStart = details.localPosition.dx;
          isValidSwipeStart = true;
        }
        break;
      case PageType.top:
        // For the top page, initiate swipe-back by dragging from the bottom edge to the top.
        if (details.localPosition.dy >=
            size.height - _verticalEdgeDetectionAreaHeight) {
          _swipeBackDragStart = details.localPosition.dy;
          isValidSwipeStart = true;
        }
        break;
      case PageType.bottom:
        // For the bottom page, initiate swipe-back by dragging from the top edge to the bottom.
        if (details.localPosition.dy <= _verticalEdgeDetectionAreaHeight) {
          _swipeBackDragStart = details.localPosition.dy;
          isValidSwipeStart = true;
        }
        break;
      case PageType.center:
        // Swipe-back is not applicable for the center page; it is the origin.
        break;
    }

    // Update the ValueNotifier if the dragging state has changed.
    if (_isSwipeBackDraggingNotifier.value != isValidSwipeStart) {
      _isSwipeBackDraggingNotifier.value = isValidSwipeStart;
    }

    // If a valid swipe-back gesture has started, reset flags and animation controller.
    if (_isSwipeBackDraggingNotifier.value) {
      _hasTriggerHapticFeedback = false;
      _swipeBackController.value = 0.0;
    }
  }

  /// Handles updates during a pan gesture for swipe-back.
  ///
  /// Calculates the progress of the swipe and updates the [_swipeBackController]
  /// value, also triggering haptic feedback if the threshold is met for the first time.
  void _handlePanUpdate(DragUpdateDetails details) {
    // Only process updates if a swipe-back gesture is currently in progress.
    if (!_isSwipeBackDraggingNotifier.value) return;

    final size = MediaQuery.sizeOf(context);

    // Amount of drag in the relevant direction
    double delta;
    // Max dimension (width/height) for calculating progress
    double maxSize;

    // Calculate drag delta and maximum swipe dimension based on the current page type.
    switch (widget.pageType) {
      case PageType.left:
        // Swiping left from the right edge of the left page.
        delta = _swipeBackDragStart - details.localPosition.dx;
        maxSize = size.width;
        break;
      case PageType.right:
        // Swiping right from the left edge of the right page.
        delta = details.localPosition.dx - _swipeBackDragStart;
        maxSize = size.width;
        break;
      case PageType.top:
        // Swiping up from the bottom edge of the top page.
        delta = _swipeBackDragStart - details.localPosition.dy;
        maxSize = size.height;
        break;
      case PageType.bottom:
        // Swiping down from the top edge of the bottom page.
        delta = details.localPosition.dy - _swipeBackDragStart;
        maxSize = size.height;
        break;
      case PageType.center:
        // Should not be reached if _isSwipeBackDraggingNotifier.value is false.
        return;
    }

    // Clamp the progress between 0.0 and 1.0 to prevent over-scrolling.
    final progress = (delta / maxSize).clamp(0.0, 1.0);
    if (!mounted) return; // Ensure the widget is still in the tree.

    // Update the animation controller's value, which will trigger an AnimatedBuilder rebuild.
    _swipeBackController.value = progress;

    // Trigger haptic feedback if the threshold is met and hasn't been triggered yet for this swipe.
    if (_swipeBackController.value >= _swipeBackHapticThreshold &&
        !_hasTriggerHapticFeedback) {
      _triggerHapticFeedback(widget.vibration);
      _hasTriggerHapticFeedback = true;
    } else if (_swipeBackController.value < _swipeBackHapticThreshold) {
      // Reset haptic feedback flag if the swipe falls back below the threshold.
      _hasTriggerHapticFeedback = false;
    }
  }

  /// Handles the end of a pan gesture for swipe-back.
  ///
  /// Determines whether to complete the swipe-back (pop the page) or
  /// animate back to the original position based on the final swipe progress.
  void _handlePanEnd(DragEndDetails details) {
    // Only process end event if a swipe-back gesture was in progress.
    if (!_isSwipeBackDraggingNotifier.value) return;

    _hasTriggerHapticFeedback =
        false; // Reset haptic feedback flag for the next gesture.

    // If swipe progress is beyond the pop threshold, animate to complete the swipe-back and pop the route.
    if (_swipeBackController.value >= _swipeBackPopThreshold) {
      _swipeBackController.animateTo(1.0).then((_) {
        if (mounted) {
          // IMPORTANT: Pass a specific map result when pop is due to a gesture-back.
          // This allows the parent (_FivePageNavigatorState) to differentiate
          // a gesture-initiated pop from other pops (like button press or system back)
          // and avoid redundant animations, as the animation is already handled here.
          Navigator.of(context).pop(
            {
              "type": "gesture_pop_completed",
              "fromPage": widget.pageType,
            },
          );
        }
      }).catchError((e) {
        // If animation fails (e.g., widget disposed), reset controller value.
        if (mounted) _swipeBackController.value = 0.0;
      }).whenComplete(() {
        // Always reset dragging state after the animation completes or an error occurs.
        if (mounted) {
          _isSwipeBackDraggingNotifier.value = false;
        }
      });
    } else {
      // If swipe progress is below the pop threshold, animate back to the original position.
      _swipeBackController.reverse().catchError((e) {
        // If animation fails, reset controller value.
        if (mounted) _swipeBackController.value = 0.0;
      }).whenComplete(() {
        // Always reset dragging state after the animation completes or an error occurs.
        if (mounted) {
          _isSwipeBackDraggingNotifier.value = false;
        }
      });
    }
  }

  /// Triggers haptic feedback based on the specified [ThresholdVibration] type.
  ///
  /// This function abstracts away the actual [HapticFeedback] calls.
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

  /// Builds the "return to center" button for side pages.
  ///
  /// This button is only shown if [showReturnToCenterButton] is true,
  /// [onReturnFromPage] is provided, and a swipe-back gesture is not
  /// currently in progress.
  Widget _buildReturnToCenterButton(BuildContext context) {
    // [ValueListenableBuilder] is used here to only rebuild the button
    // when `_isSwipeBackDraggingNotifier` changes, efficiently hiding
    // it during a drag.
    return ValueListenableBuilder<bool>(
      valueListenable: _isSwipeBackDraggingNotifier,
      builder: (context, isDragging, child) {
        // Hide the button if not configured to show, no callback, or if dragging.
        if (!widget.showReturnToCenterButton ||
            widget.onReturnFromPage == null ||
            isDragging) {
          // Invisible placeholder
          return const SizedBox.shrink();
        }

        // Use provided button configuration or fall back to defaults.
        final effectiveConfig =
            widget.returnButtonConfig ?? const ReturnButtonStyle();

        // Callback for button tap, triggers haptic feedback and pops the navigator.
        void onButtonTapped() {
          _triggerHapticFeedback(widget.vibration);
          // When the button is tapped, we simply pop the navigator route.
          // The `onPopInvokedWithResult` in this `PageWrapper`'s `PopScope`
          // will then handle calling `onReturnFromPage` in `_FivePageNavigatorState`.
          Navigator.of(context).pop("button_pop_${widget.pageType.name}");
        }

        IconData iconData;
        Alignment alignment;

        // Position properties for [Positioned] widget
        double? left, right, top, bottom;

        // Determine the appropriate icon and positioning for the button
        // based on the current page type, guiding the user back to the center.
        switch (widget.pageType) {
          case PageType.left:
            // If on the left page, button points right, placed on the right edge.
            iconData = Icons.chevron_right;
            alignment = Alignment.centerRight;
            right = effectiveConfig.edgeOffset;
            top = 0;
            bottom = 0;
            break;
          case PageType.right:
            // If on the right page, button points left, placed on the left edge.
            iconData = Icons.chevron_left;
            alignment = Alignment.centerLeft;
            left = effectiveConfig.edgeOffset;
            top = 0;
            bottom = 0;
            break;
          case PageType.top:
            // If on the top page, button points down, placed on the bottom edge.
            iconData = Icons.expand_more;
            alignment = Alignment.bottomCenter;
            bottom = effectiveConfig.edgeOffset;
            left = 0;
            right = 0;
            break;
          case PageType.bottom:
            // If on the bottom page, button points up, placed on the top edge.
            iconData = Icons.expand_less;
            alignment = Alignment.topCenter;
            top = effectiveConfig.edgeOffset;
            left = 0;
            right = 0;
            break;
          case PageType.center:
            // Button is not applicable for the center page.
            return const SizedBox.shrink();
        }

        Widget buttonWidget;
        // Use a custom button builder if provided, allowing full customization.
        // Otherwise, build the default circular button with icon.
        if (effectiveConfig.customButtonBuilder != null) {
          buttonWidget = effectiveConfig.customButtonBuilder!(
            context,
            onButtonTapped,
            widget.pageType,
          );
        } else {
          buttonWidget = Material(
            // Make background transparent for circular inkwell
            color: Colors.transparent,
            // Ensures circular shape for InkWell interaction
            type: MaterialType.circle,
            clipBehavior: Clip.hardEdge, // Clips content to the circular shape
            child: InkWell(
              onTap: onButtonTapped,
              customBorder: const CircleBorder(),
              child: Container(
                width: effectiveConfig.buttonSize,
                height: effectiveConfig.buttonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effectiveConfig.backgroundColor,
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

        // Position the button on the screen using [Positioned] and [SafeArea]
        // to avoid system UI overlays (e.g., notches, status bar).
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // The main layout for PageWrapper.
    // [ValueListenableBuilder] controls the `GestureDetector`'s enabled status,
    // ensuring pan detection is only active when appropriate.
    return ValueListenableBuilder<bool>(
      valueListenable: _isSwipeBackDraggingNotifier,
      builder: (context, isDragging, child) {
        return GestureDetector(
          // `onPanStart` is only active if swipe back is enabled and not already dragging.
          onPanStart:
              widget.enableSwipeBack && !isDragging ? _handlePanStart : null,
          // `onPanUpdate` and `onPanEnd` are only active if a drag is currently in progress.
          onPanUpdate: isDragging ? _handlePanUpdate : null,
          onPanEnd: isDragging ? _handlePanEnd : null,
          // Ensures gestures are captured throughout the widget's area.
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            // [AnimatedBuilder] listens to `_swipeBackController` for animations.
            animation: _swipeBackController,
            builder: (context, child) {
              final size = MediaQuery.sizeOf(context);
              double sidePageTranslateX = 0.0, sidePageTranslateY = 0.0;
              double centerPageTranslateX = 0.0, centerPageTranslateY = 0.0;

              // Calculate translation offsets for both the current side page
              // and the underlying center page during the swipe-back animation.
              if (widget.enableSwipeBack) {
                switch (widget.pageType) {
                  case PageType.left:
                    // Left page moves further left as it disappears.
                    sidePageTranslateX =
                        -_swipeBackController.value * size.width;
                    // Center page slides into view from the right.
                    centerPageTranslateX =
                        size.width * (1.0 - _swipeBackController.value);
                    break;
                  case PageType.right:
                    // Right page moves further right as it disappears.
                    sidePageTranslateX =
                        _swipeBackController.value * size.width;
                    // Center page slides into view from the left.
                    centerPageTranslateX =
                        -size.width * (1.0 - _swipeBackController.value);
                    break;
                  case PageType.top:
                    // Top page moves further up as it disappears.
                    sidePageTranslateY =
                        -_swipeBackController.value * size.height;
                    // Center page slides into view from the bottom.
                    centerPageTranslateY =
                        size.height * (1.0 - _swipeBackController.value);
                    break;
                  case PageType.bottom:
                    // Bottom page moves further down as it disappears.
                    sidePageTranslateY =
                        _swipeBackController.value * size.height;
                    // Center page slides into view from the top.
                    centerPageTranslateY =
                        -size.height * (1.0 - _swipeBackController.value);
                    break;
                  case PageType.center:
                    break; // Should not be reached as this wrapper is for side pages.
                }
              }

              return Stack(
                children: [
                  // 1. Center page:
                  //    - Its opacity animates from `incomingPageOpacityStart` to 1.0.
                  //    - It slides into view from the direction opposite to the side page's departure.
                  Opacity(
                    opacity: lerpDouble(
                      widget.incomingPageOpacityStart,
                      1.0,
                      _swipeBackController.value,
                    )!,
                    child: Transform.translate(
                      offset:
                          Offset(centerPageTranslateX, centerPageTranslateY),
                      child: widget.centerPage,
                    ),
                  ),
                  // 2. Current side page:
                  //    - Its opacity animates from 1.0 to 0.0 as it disappears.
                  //    - It slides further off-screen in its original direction.
                  Opacity(
                    opacity: lerpDouble(1.0, 0.0, _swipeBackController.value)!,
                    child: Transform.translate(
                      offset: Offset(sidePageTranslateX, sidePageTranslateY),
                      child: PopScope(
                        // `canPop` controls whether the system back button (or `Navigator.pop`)
                        // is allowed to directly pop this route.
                        // It's set to `true` only when:
                        // 1. Swipe-back is disabled (`widget.enableSwipeBack` is `false`).
                        // 2. Or, swipe-back is enabled, but the gesture is not currently in progress
                        //    and the animation controller is near its start (meaning the page is fully on screen).
                        canPop: widget.enableSwipeBack
                            ? (_swipeBackController.value <
                                    0.1 && // Near start of animation (page fully visible)
                                !_isSwipeBackDraggingNotifier
                                    .value) // Not actively dragging
                            : true, // If swipe-back is disabled, always allow pop.
                        // `onPopInvokedWithResult` is called when a pop is attempted on this route,
                        // regardless of `canPop`'s value.
                        // `didPop` indicates if the pop actually happened (i.e., `canPop` was true or ignored).
                        // `result` is any data passed to `Navigator.pop`.
                        onPopInvokedWithResult: (didPop, result) {
                          if (didPop) {
                            // If the pop was successful, notify the parent navigator.
                            // The `result` helps the parent distinguish between a gesture pop,
                            // a button pop, or a system back pop, enabling appropriate follow-up actions.
                            widget.onReturnFromPage
                                ?.call(widget.pageType, result);
                          }
                        },
                        child: widget.child,
                      ),
                    ),
                  ),
                  // 3. The optional "return to center" button.
                  _buildReturnToCenterButton(context),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
