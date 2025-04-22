import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble; // Used for linear interpolation

/// Represents the direction of a swipe gesture.
///
/// Used internally by the navigator to determine the target page and animation.
enum SwipeDirection {
  left, // Indicates a swipe from right to left.
  right, // Indicates a swipe from left to right.
  up, // Indicates a swipe from bottom to top.
  down, // Indicates a swipe from top to bottom.
}

/// Represents the type or position of a page within the navigator's structure.
///
/// Used to identify the currently active page and determine navigation targets.
enum PageType {
  center, // The main, central page.
  left, // The page located to the left of the center.
  right, // The page located to the right of the center.
  top, // The page located above the center.
  bottom, // The page located below the center.
}

/// A custom navigator widget that allows swiping between a center page
/// and four surrounding pages (left, right, top, bottom).
///
/// It includes an initial zoom-out animation showing all pages and supports
/// navigating to side pages via swipe gestures from the center, and returning
/// via the system back button or an optional swipe-back gesture from side pages.
class FivePageNavigator extends StatefulWidget {
  /// The main page displayed in the center.
  final Widget centerPage;

  /// The page displayed to the left of the center page.
  final Widget leftPage;

  /// The page displayed to the right of the center page.
  final Widget rightPage;

  /// The page displayed above the center page.
  final Widget topPage;

  /// The page displayed below the center page.
  final Widget bottomPage;

  /// The duration of the swipe and return animations.
  ///
  /// Defaults to 300 milliseconds.
  final Duration animationDuration;

  /// The initial delay before the zoom-out animation starts.
  ///
  /// This allows the layout to settle before the animation begins.
  /// Defaults to 100 milliseconds.
  final Duration initialWaitDuration;

  /// The fraction of the screen width/height that must be swiped
  /// to trigger a page transition (0.0 to 1.0).
  ///
  /// If the swipe distance falls below this threshold, the page snaps back.
  /// Defaults to 0.25 (25%).
  final double swipeThreshold;

  /// The scale factor for the inactive pages during swipe animations.
  ///
  /// A value of 1.0 means no zoom effect. A value less than 1.0 zooms out.
  /// Defaults to 1.0.
  final double zoomOutScale;

  /// Callback function invoked when the active page changes *after* a
  /// successful navigation (push to a side page or pop back to center).
  ///
  /// Called with the [PageType] of the page that becomes active.
  final Function(PageType)? onPageChanged;

  /// The height area (in logical pixels) at the top and bottom edges of the
  /// screen within which vertical swipes from the center page are detected.
  ///
  /// Swipes originating outside this area will not be registered as vertical
  /// swipes, helping to prevent accidental vertical swipes when scrolling content
  /// within the center page. Defaults to 200.0.
  final double verticalDetectionAreaHeight;

  /// The width area (in logical pixels) at the left and right edges of the
  /// screen within which horizontal swipes from the center page are detected.
  ///
  /// Swipes originating outside this area will not be registered as horizontal
  /// swipes, helping to prevent accidental horizontal swipes when scrolling
  /// content within the center page. Defaults to 100.0.
  final double horizontalDetectionAreaWidth;

  /// Whether to enable swipe-back gesture on the left page
  /// to return to the center page. Defaults to false.
  final bool enableLeftPageSwipeBack;

  /// Whether to enable swipe-back gesture on the right page
  /// to return to the center page. Defaults to false.
  final bool enableRightPageSwipeBack;

  /// Whether to enable swipe-back gesture on the top page
  /// to return to the center page. Defaults to false.
  final bool enableTopPageSwipeBack;

  /// Whether to enable swipe-back gesture on the bottom page
  /// to return to the center page. Defaults to false.
  final bool enableBottomPageSwipeBack;

  /// Constructs a [FivePageNavigator].
  const FivePageNavigator({
    super.key,
    required this.centerPage,
    required this.leftPage,
    required this.rightPage,
    required this.topPage,
    required this.bottomPage,
    this.animationDuration = const Duration(milliseconds: 300),
    this.initialWaitDuration = const Duration(milliseconds: 100),
    this.swipeThreshold = 0.25,
    this.zoomOutScale = 1,
    this.onPageChanged,
    this.verticalDetectionAreaHeight = 200.0,
    this.horizontalDetectionAreaWidth = 100.0,
    this.enableLeftPageSwipeBack = false,
    this.enableRightPageSwipeBack = false,
    this.enableTopPageSwipeBack = false,
    this.enableBottomPageSwipeBack = false,
  });

  @override
  State<FivePageNavigator> createState() => _FivePageNavigatorState();
}

/// The state for [FivePageNavigator], managing animations, gestures, and page transitions.
class _FivePageNavigatorState extends State<FivePageNavigator>
    with TickerProviderStateMixin {
  // --- Animation Controllers ---

  /// Controller for the initial zoom-out animation.
  late AnimationController _initialZoomController;

  /// Controller for swipe animations (dragging and animating to/from side pages).
  late AnimationController _swipeTransitionController;

  // --- Gesture and State Variables ---

  /// Tracks the cumulative progress of the current swipe gesture (0.0 to 1.0).
  /// This value directly updates [_swipeTransitionController.value] during a drag.
  double _swipeProgress = 0.0;

  /// The detected direction of the current swipe gesture.
  SwipeDirection? _currentSwipeDirection;

  /// The local position where the pan gesture started. Used to determine direction
  /// and check detection areas.
  Offset? _dragStartPosition;

  // --- State Flags ---

  /// True after the initial zoom-out animation has completed. Gestures are
  /// only enabled when this is true.
  bool _isInitialZoomCompleted = false;

  /// True when animating back to the center page after a side page has been popped.
  bool _isReturningToCenter = false;

  /// Stores the type of the page being returned from when [_isReturningToCenter] is true.
  PageType? _returningFromPageType;

  // --- Lifecycle Methods ---

  @override
  void initState() {
    super.initState();

    // Initialize the controller for the initial zoom animation
    _initialZoomController = AnimationController(
      duration: const Duration(milliseconds: 300), // Fixed duration for zoom
      vsync: this, // Provides the ticker
    );

    // Initialize the controller for swipe transitions
    _swipeTransitionController = AnimationController(
      duration: widget.animationDuration, // Configurable duration
      vsync: this, // Provides the ticker
    );

    // Schedule the initial zoom animation to start after the first frame.
    // This ensures the context and screen size are available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(widget.initialWaitDuration, () {
        if (mounted) {
          // Start the forward animation (zooming in to the center)
          _initialZoomController.forward().then((_) {
            if (mounted) {
              // Mark initial zoom as complete and enable gestures
              setState(() {
                _isInitialZoomCompleted = true;
              });
              // Notify the listener that the center page is now active
              widget.onPageChanged?.call(PageType.center);
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    // Dispose of animation controllers to prevent resource leaks
    _initialZoomController.dispose();
    _swipeTransitionController.dispose();
    super.dispose();
  }

  // Add this to ensure FivePageNavigator can be found by descendant widgets
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<Widget>('centerPage', widget.centerPage));
  }

  // --- Gesture Handling ---

  /// Handles the start of a pan gesture.
  ///
  /// Initializes state variables for tracking the gesture. Gestures are ignored
  /// if the initial zoom isn't complete or if an animation is already running.
  void _handlePanStart(DragStartDetails details) {
    // Block gestures during initial zoom, during any swipe animation (forward or reverse),
    // or if currently in the process of returning from a pushed page.
    if (!_isInitialZoomCompleted ||
        _swipeTransitionController.isAnimating ||
        _isReturningToCenter) {
      _dragStartPosition = null; // Ensure state is clean
      return;
    }

    // Store the starting position and reset state for a new drag
    _dragStartPosition = details.localPosition;
    _currentSwipeDirection = null; // Direction is determined on first update
    _swipeProgress = 0.0; // Start progress from zero
    // Reset controller value to 0 at the start of a new drag. This is
    // important if a previous animation was interrupted or didn't finish cleanly.
    _swipeTransitionController.value = 0.0;
  }

  /// Handles updates during a pan gesture.
  ///
  /// Determines the swipe direction on the first update and updates the
  /// animation controller value based on the drag distance.
  void _handlePanUpdate(DragUpdateDetails details) {
    // Continue blocking if the drag wasn't properly started or animation is running
    if (_dragStartPosition == null ||
        _swipeTransitionController.isAnimating ||
        _isReturningToCenter) {
      return;
    }

    final screenSize = MediaQuery.sizeOf(context);

    // Determine direction if not already determined
    if (_currentSwipeDirection == null) {
      _determineSwipeDirection(details, screenSize);
      // If direction is determined, the AnimatedBuilder will start reacting
      // as soon as the controller value is updated below.
    }

    // If a valid swipe direction has been determined, update the swipe progress
    if (_currentSwipeDirection != null) {
      double delta; // Change in position along the swipe axis
      double dimension; // Screen dimension along the swipe axis

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

      // Accumulate swipe progress based on the delta relative to the screen dimension.
      // For left/up, delta is negative for forward movement. For right/down, delta is positive.
      // We want _swipeProgress to be between 0.0 and 1.0 based on the absolute movement towards the edge.
      double progressDelta = delta / dimension;

      if (_currentSwipeDirection == SwipeDirection.left ||
          _currentSwipeDirection == SwipeDirection.up) {
        // For left/up swipes, a positive delta means moving away from the target edge.
        // A negative delta means moving towards the target edge (progress).
        // We accumulate the *negative* delta and take the absolute value for progress.
        _swipeProgress += progressDelta;
        // Clamp progress between 0.0 (start) and 1.0 (fully swiped).
        _swipeProgress = _swipeProgress.clamp(-1.0, 0.0);
      } else {
        // For right/down swipes, a positive delta means moving towards the target edge.
        _swipeProgress += progressDelta;
        // Clamp progress between 0.0 (start) and 1.0 (fully swiped).
        _swipeProgress = _swipeProgress.clamp(0.0, 1.0);
      }

      // Update the controller value with the absolute progress.
      // The AnimatedBuilder listening to _swipeTransitionController will rebuild.
      // No setState is needed here.
      _swipeTransitionController.value = _swipeProgress.abs();
    }
  }

  /// Determines the swipe direction based on drag start position and initial movement.
  ///
  /// Checks if the gesture started within the defined detection areas before
  /// determining horizontal or vertical direction based on the larger axis delta.
  void _determineSwipeDirection(DragUpdateDetails details, Size screenSize) {
    final startX = _dragStartPosition!.dx;
    final startY = _dragStartPosition!.dy;
    final currentX = details.localPosition.dx;
    final currentY = details.localPosition.dy;
    final totalDeltaX = currentX - startX;
    final totalDeltaY = currentY - startY;
    final absDeltaX = totalDeltaX.abs();
    final absDeltaY = totalDeltaY.abs();

    // A small threshold to prevent minor jiggles from prematurely determining direction.
    const double directionLockThreshold = 5.0;

    // Only determine direction if there's significant movement
    if (absDeltaX > directionLockThreshold ||
        absDeltaY > directionLockThreshold) {
      if (absDeltaX > absDeltaY) {
        // Horizontal swipe detected
        // Check if swipe started within the horizontal detection area
        if (totalDeltaX > 0 && startX < widget.horizontalDetectionAreaWidth) {
          // Swipe right originating from the left edge area
          _currentSwipeDirection = SwipeDirection.right;
        } else if (totalDeltaX < 0 &&
            startX > screenSize.width - widget.horizontalDetectionAreaWidth) {
          // Swipe left originating from the right edge area
          _currentSwipeDirection = SwipeDirection.left;
        }
      } else {
        // Vertical swipe detected
        // Check if swipe started within the vertical detection area
        if (totalDeltaY > 0 && startY < widget.verticalDetectionAreaHeight) {
          // Swipe down originating from the top edge area
          _currentSwipeDirection = SwipeDirection.down;
        } else if (totalDeltaY < 0 &&
            startY > screenSize.height - widget.verticalDetectionAreaHeight) {
          // Swipe up originating from the bottom edge area
          _currentSwipeDirection = SwipeDirection.up;
        }
      }
      // Once direction is determined, the first update to _swipeTransitionController.value
      // happens in _handlePanUpdate, triggering the AnimatedBuilder.
    }
  }

  /// Handles the end of a pan gesture.
  ///
  /// Decides whether to animate to the target page (if threshold met) or snap
  /// back to the center page (if threshold not met).
  void _handlePanEnd(DragEndDetails details) {
    // Ignore if no valid swipe direction was determined, animation is running,
    // or we are currently returning from a pushed page.
    if (_currentSwipeDirection == null ||
        _swipeTransitionController.isAnimating ||
        _isReturningToCenter) {
      // If returning, state will be reset when the return animation finishes.
      // Otherwise, reset drag state immediately for a clean slate.
      if (!_isReturningToCenter) {
        _resetDragState();
      }
      return;
    }

    // Use the current value of the controller (which reflects _swipeProgress.abs())
    // to check against the threshold.
    final swipeProgress = _swipeTransitionController.value;

    if (swipeProgress >= widget.swipeThreshold) {
      _animateToPage(); // Animate to the target page
    } else {
      _animateBackToCenter(); // Animate back to the center
    }
  }

  /// Resets the state variables related to the drag gesture and forward animation.
  ///
  /// Called after a forward swipe gesture or animation is completed or cancelled.
  void _resetDragState() {
    if (mounted) {
      // Reset gesture tracking variables.
      _swipeProgress = 0.0;
      _currentSwipeDirection = null;
      _dragStartPosition = null;

      // Stop and reset the controller if it's animating. Setting value to 0.0
      // ensures the AnimatedBuilder redraws the center page in its default state.
      if (_swipeTransitionController.isAnimating) {
        _swipeTransitionController.stop();
      }
      _swipeTransitionController.value = 0.0;

      // _isReturningToCenter must remain false when resetting drag state.
    }
  }

  /// Resets the state variables related to the return animation after a pop.
  ///
  /// Called when the reverse animation back to the center page completes.
  void _resetReturnState() {
    if (mounted) {
      // Use setState as this changes flags that determine which state/widget
      // is built (_isReturningToCenter flag).
      setState(() {
        _isReturningToCenter = false;
        _returningFromPageType = null;
        // Clean up gesture-related state variables as well, just in case.
        _currentSwipeDirection = null;
        _swipeProgress = 0.0;
        _dragStartPosition = null;
      });

      // Ensure the controller is fully reset to 0.0 at the end of the animation.
      // AnimatedBuilder will handle the final rebuild.
      if (_swipeTransitionController.isAnimating) {
        _swipeTransitionController.stop();
      }
      _swipeTransitionController.value = 0.0;

      // The onPageChanged callback for PageType.center is already called
      // in _handleReturnFromPage when the reverse animation starts.
    }
  }

  // --- Animation and Navigation Logic ---

  /// Starts the animation to transition from the center page to a side page.
  ///
  /// Assumes a swipe direction has been determined and the threshold met.
  void _animateToPage() {
    // Ensure a direction is set and no animation is already running
    if (_currentSwipeDirection == null ||
        _swipeTransitionController.isAnimating) {
      return;
    }

    // Start the forward animation (from current value to 1.0).
    // The AnimatedBuilder uses the controller value to update the UI.
    // No setState needed here as _isReturningToCenter is already false and stays false.
    _swipeTransitionController
        .forward(from: _swipeTransitionController.value)
        .then((_) {
      // Animation finished successfully. Proceed to push the target page.
      if (mounted) {
        _navigateToPageActual();
        // Note: _resetDragState is called immediately after push, clearing
        // the temporary drag state while the pushed page is visible.
      }
    }).catchError((error) {
      // Handle potential animation errors (e.g., controller disposed) by resetting state.
      if (mounted) {
        debugPrint('Animation forward error: $error');
        _resetDragState();
      }
    });
  }

  /// Starts the animation to snap back to the center page.
  ///
  /// Called when a swipe gesture ends before reaching the threshold.
  void _animateBackToCenter() {
    // Ensure a direction is set and no animation is already running
    if (_currentSwipeDirection == null ||
        _swipeTransitionController.isAnimating) {
      return;
    }

    // Start the reverse animation (from current value back to 0.0).
    // The AnimatedBuilder uses the controller value to update the UI.
    // No setState needed here as _isReturningToCenter is already false and stays false.
    _swipeTransitionController
        .reverse(from: _swipeTransitionController.value)
        .then((_) {
      // Animation finished. Reset drag state.
      if (mounted) {
        _resetDragState();
      }
    }).catchError((error) {
      // Handle potential animation errors by resetting state.
      if (mounted) {
        debugPrint('Animation reverse error: $error');
        _resetDragState();
      }
    });
  }

  /// Handles the event when a pushed page is popped from the navigator stack.
  ///
  /// This is triggered by the [PopScope] in [PageWrapper] when the system back
  /// button is pressed, *unless* the pop was initiated by the side-page
  /// swipe-back gesture (which uses a custom result).
  void _handleReturnFromPage(PageType returnedFrom) {
    // Ensure the widget is mounted, not already animating, and not already in
    // the process of returning.
    if (!mounted ||
        _swipeTransitionController.isAnimating ||
        _isReturningToCenter) {
      return;
    }

    // Determine the swipe direction needed for the reverse animation.
    final reverseDirection = _getReverseSwipeDirection(returnedFrom);
    if (reverseDirection == null) {
      // Should not happen if 'returnedFrom' is a side page type.
      debugPrint('Error: _handleReturnFromPage called with center type.');
      _resetReturnState(); // Reset state just in case.
      return;
    }

    // Update state to indicate that the return animation is starting.
    // This changes which pages are rendered and how they animate in _buildSwipeContent.
    setState(() {
      _isReturningToCenter = true;
      _returningFromPageType = returnedFrom;
      _currentSwipeDirection =
          reverseDirection; // Set the direction for the reverse animation.
      // Ensure controller value is 1.0 at the start of the reverse animation
      // (representing the state where the side page is fully visible/center is off-screen).
      _swipeTransitionController.value = 1.0;
    });

    // Notify the listener that we are transitioning back to the center page.
    widget.onPageChanged?.call(PageType.center);

    // Start the reverse animation (from 1.0 back to 0.0).
    _swipeTransitionController.reverse(from: 1.0).then((_) {
      // Animation complete, reset the return state.
      if (mounted) {
        _resetReturnState();
      }
    }).catchError((error) {
      // Handle potential animation errors by resetting state.
      if (mounted) {
        debugPrint('Animation reverse error: $error');
        _resetReturnState();
      }
    });
  }

  /// Pushes the target page onto the Navigator stack.
  ///
  /// Called after the forward swipe animation (center to side) completes.
  void _navigateToPageActual() {
    if (_currentSwipeDirection == null) {
      _resetDragState(); // Should not happen if _animateToPage was called correctly
      return;
    }

    PageType targetPageType;
    Widget targetPageWidget;
    bool enableSwipeBackForTarget = false;

    // Determine the target page and its swipe-back setting based on the
    // direction of the swipe *away* from the center.
    switch (_currentSwipeDirection!) {
      case SwipeDirection.left: // Swiped left -> arrived at Right page
        targetPageType = PageType.right;
        targetPageWidget = widget.rightPage;
        enableSwipeBackForTarget = widget.enableRightPageSwipeBack;
        break;
      case SwipeDirection.right: // Swiped right -> arrived at Left page
        targetPageType = PageType.left;
        targetPageWidget = widget.leftPage;
        enableSwipeBackForTarget = widget.enableLeftPageSwipeBack;
        break;
      case SwipeDirection.up: // Swiped up -> arrived at Bottom page
        targetPageType = PageType.bottom;
        targetPageWidget = widget.bottomPage;
        enableSwipeBackForTarget = widget.enableBottomPageSwipeBack;
        break;
      case SwipeDirection.down: // Swiped down -> arrived at Top page
        targetPageType = PageType.top;
        targetPageWidget = widget.topPage;
        enableSwipeBackForTarget = widget.enableBottomPageSwipeBack;
        break;
    }

    // Use PageRouteBuilder with Duration.zero. The visual transition is already
    // handled by the swipe animation *before* the push. This route just
    // manages the Navigator stack and back button behavior.
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => PageWrapper(
          pageType: targetPageType,
          onReturnFromPage: (returnedFrom) {
            _handleReturnFromPage(returnedFrom);
          },
          enableSwipeBack: enableSwipeBackForTarget,
          centerPage: widget.centerPage,
          child: targetPageWidget,
        ),
        transitionDuration:
            Duration.zero, // No animation from the route builder
        reverseTransitionDuration:
            Duration.zero, // No animation from the route builder
      ),
      // The result from the popped page. We check for "gesture_pop" later.
    ).then((result) {
      // This code runs when the pushed page is popped from the navigator.
      // If the pop was triggered by the side-page swipe-back gesture,
      // the PageWrapper returns "gesture_pop". In this case, we should
      // skip the parent's return animation as the side page's own animation
      // handled the visual transition back.
      if (result == "gesture_pop") {
        // Clean up state without running the return animation
        _resetReturnState();
      }
      // If result IS null or anything else, it was likely a system back button
      // or Navigator.pop() call. The _handleReturnFromPage callback (triggered
      // by PopScope in PageWrapper) will already have initiated the animation.
    });

    // Reset drag state immediately after Navigator.push is called.
    // The visual state just before the push is maintained by the last frame
    // of the forward animation (_swipeTransitionController.value was 1.0).
    _resetDragState();

    // Notify listener that the target page is now active. This is called *before*
    // the actual page is fully built, but after the transition animation completes
    // and the push is initiated.
    widget.onPageChanged?.call(targetPageType);
  }

  // --- Helper Functions ---

  /// Returns the [SwipeDirection] required to animate back to the center
  /// from a given [PageType].
  SwipeDirection? _getReverseSwipeDirection(PageType fromPage) {
    switch (fromPage) {
      case PageType.left:
        return SwipeDirection
            .right; // From Left, swipe Right to go back to Center
      case PageType.right:
        return SwipeDirection
            .left; // From Right, swipe Left to go back to Center
      case PageType.top:
        return SwipeDirection.down; // From Top, swipe Down to go back to Center
      case PageType.bottom:
        return SwipeDirection.up; // From Bottom, swipe Up to go back to Center
      case PageType.center:
        return null; // Cannot return to center *from* center
    }
  }

  /// Calculates the final off-screen position of the center page when it is
  /// animated away during a forward swipe (center to side).
  Offset _getCenterPageEndOffset(SwipeDirection swipeDirection, Size size) {
    switch (swipeDirection) {
      case SwipeDirection.left:
        // Swiping left means the center page moves to the left off-screen.
        return Offset(-size.width, 0);
      case SwipeDirection.right:
        // Swiping right means the center page moves to the right off-screen.
        return Offset(size.width, 0);
      case SwipeDirection.up:
        // Swiping up means the center page moves upwards off-screen.
        return Offset(0, -size.height);
      case SwipeDirection.down:
        // Swiping down means the center page moves downwards off-screen.
        return Offset(0, size.height);
    }
  }

  /// Calculates the starting off-screen position for a side page that is
  /// animating onto the screen during a forward swipe (center to side).
  Offset _getOffScreenOffset(SwipeDirection direction, Size size) {
    switch (direction) {
      case SwipeDirection.left:
        // Swiping left brings the Right page from the right edge.
        return Offset(size.width, 0);
      case SwipeDirection.right:
        // Swiping right brings the Left page from the left edge.
        return Offset(-size.width, 0);
      case SwipeDirection.up:
        // Swiping up brings the Bottom page from the bottom edge.
        return Offset(0, size.height);
      case SwipeDirection.down:
        // Swiping down brings the Top page from the top edge.
        return Offset(0, -size.height);
    }
  }

  /// Returns the target side page widget based on the current forward swipe direction.
  Widget _getSwipingPage() {
    if (_currentSwipeDirection == null) {
      // Should not be called if _currentSwipeDirection is null, but handle defensively.
      return const SizedBox.shrink();
    }
    switch (_currentSwipeDirection!) {
      case SwipeDirection.left: // Swiping left shows the Right page
        return widget.rightPage;
      case SwipeDirection.right: // Swiping right shows the Left page
        return widget.leftPage;
      case SwipeDirection.up: // Swiping up shows the Bottom page
        return widget.bottomPage;
      case SwipeDirection.down: // Swiping down shows the Top page
        return widget.topPage;
    }
  }

  /// Returns a page widget based on its [PageType].
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

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    // Determine the current state and build the appropriate view.
    // This is managed by [_isInitialZoomCompleted].

    if (!_isInitialZoomCompleted) {
      // If initial zoom is not complete, show the zoomed-out state.
      // AnimatedBuilder listens to the _initialZoomController and rebuilds
      // _buildInitialZoomContent whenever the controller's value changes.
      return AnimatedBuilder(
        animation: _initialZoomController,
        builder: (context, child) {
          // The animation value goes from 0.0 to 1.0 during the forward animation.
          return _buildInitialZoomContent(_initialZoomController.value);
        },
      );
    }

    // If initial zoom is complete, show the interactive swipe view.
    // GestureDetector handles swipe input.
    // AnimatedBuilder listens to _swipeTransitionController and rebuilds
    // _buildSwipeContent during drags and animations.
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      // opaque ensures that gestures are captured even if there are no visible
      // widgets in parts of the container.
      behavior: HitTestBehavior.opaque,
      child: Container(
        // Clip ensures pages are contained within the bounds during transformation.
        clipBehavior: Clip.hardEdge,
        width: double.infinity,
        height: double.infinity,
        // No decoration needed unless intentional
        decoration: BoxDecoration(),
        child: AnimatedBuilder(
          animation: _swipeTransitionController,
          builder: (context, child) {
            // The animation value reflects the current swipe progress (0.0 to 1.0).
            // _buildSwipeContent uses this value along with the state flags
            // (_isReturningToCenter, _currentSwipeDirection) to determine
            // the positions and scales of the pages.
            return _buildSwipeContent(_swipeTransitionController.value);
          },
        ),
      ),
    );
  }

  /// Builds the content displayed during the initial zoom-out animation.
  ///
  /// [animationProgress] ranges from 0.0 (fully zoomed out) to 1.0 (zoomed into center).
  Widget _buildInitialZoomContent(double animationProgress) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    // Constants for the initial layout
    const double initialViewScale = 0.5; // Initial scale of all pages
    const double spacing = 15.0; // Spacing between pages in the initial view

    // Interpolate scale:
    // Side pages scale from initialViewScale down to near zero.
    final sideScale = lerpDouble(initialViewScale, 0.0, animationProgress)!;
    // Center page scales from initialViewScale up to 1.0 (full screen).
    final centerScale = lerpDouble(initialViewScale, 1.0, animationProgress)!;

    // Calculate initial positions of all pages in the zoomed-out view.
    // These are relative to the screen top-left.
    final initialCenterWidth = screenWidth * initialViewScale;
    final initialCenterHeight = screenHeight * initialViewScale;
    final initialCenterX = (screenWidth - initialCenterWidth) / 2;
    final initialCenterY = (screenHeight - initialCenterHeight) / 2;

    final initialSideWidth = screenWidth * initialViewScale;
    final initialSideHeight = screenHeight * initialViewScale;

    final initialLeftX = initialCenterX - initialSideWidth - spacing;
    final initialRightX = initialCenterX + initialCenterWidth + spacing;
    final initialTopY = initialCenterY - initialSideHeight - spacing;
    final initialBottomY = initialCenterY + initialCenterHeight + spacing;
    final initialSideY = initialCenterY; // Y alignment for left/right pages
    final initialSideX = initialCenterX; // X alignment for top/bottom pages

    // Calculate final positions when zoomed into the center.
    // Side pages are off-screen, center page is at (0,0).
    final finalLeftX = -initialSideWidth;
    final finalRightX = screenWidth;
    final finalTopY = -initialSideHeight;
    final finalBottomY = screenHeight;
    // Final center position is (0,0) relative to the screen
    const finalCenterX = 0.0;
    const finalCenterY = 0.0;
    // Final side alignment positions (centered relative to the final center position)
    // These offsets are only relevant if side pages were to scale/translate relative
    // to the center, but they are just translated off-screen here.
    // However, using them in lerpDouble maintains consistency in the interpolation.
    final finalSideY = finalCenterY + (screenHeight - initialSideHeight) / 2;
    final finalSideX = finalCenterX + (screenWidth - initialSideWidth) / 2;

    // Interpolate current positions based on animation progress (0.0 -> 1.0).
    // As animationProgress goes from 0 to 1, position goes from initial to final.
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

    final currentCenterX =
        lerpDouble(initialCenterX, finalCenterX, animationProgress)!;
    final currentCenterY =
        lerpDouble(initialCenterY, finalCenterY, animationProgress)!;

    // Optimization: If side pages are scaled down significantly, only draw the center page.
    // Using a small threshold instead of checking for scale <= 0.
    if (sideScale < 0.05) {
      return Transform.translate(
        offset: Offset(currentCenterX, currentCenterY),
        child: Transform.scale(
          scale: centerScale,
          alignment: Alignment.center,
          child: SizedBox(
            // Ensure page covers full screen when scale is 1.0
            width: screenWidth,
            height: screenHeight,
            child: widget.centerPage,
          ),
        ),
      );
    }

    // Draw all pages during the animation (when side pages are still visible).
    return Stack(
      children: [
        // Side Pages (positioned and scaled). Use Positioned for explicit placement.
        Positioned(
          left: currentLeftX,
          top: currentSideY,
          width: initialSideWidth,
          height: initialSideHeight,
          child: Transform.scale(scale: sideScale, child: widget.leftPage),
        ),
        Positioned(
          left: currentRightX,
          top: currentSideY,
          width: initialSideWidth,
          height: initialSideHeight,
          child: Transform.scale(scale: sideScale, child: widget.rightPage),
        ),
        Positioned(
          left: currentSideX,
          top: currentTopY,
          width: initialSideWidth,
          height: initialSideHeight,
          child: Transform.scale(scale: sideScale, child: widget.topPage),
        ),
        Positioned(
          left: currentSideX,
          top: currentBottomY,
          width: initialSideWidth,
          height: initialSideHeight,
          child: Transform.scale(scale: sideScale, child: widget.bottomPage),
        ),

        // Center Page (positioned and scaled).
        Positioned(
          left: currentCenterX,
          top: currentCenterY,
          // Dimensions scale with the centerScale
          width: screenWidth * centerScale,
          height: screenHeight * centerScale,
          child: widget.centerPage,
        ),
      ],
    );
  }

  /// Builds the content displayed during swipe (drag) and swipe transitions
  /// (animating between center and side pages).
  ///
  /// [animationProgress] is the value of [_swipeTransitionController], ranging
  /// from 0.0 to 1.0. The meaning of this progress depends on whether we are
  /// swiping away from the center or returning to the center.
  Widget _buildSwipeContent(double animationProgress) {
    // If no swipe is in progress and no animation is running (controller value is 0.0),
    // and we are not returning, simply show the center page. This is the idle state.
    if (_currentSwipeDirection == null &&
        !_isReturningToCenter &&
        !_swipeTransitionController.isAnimating &&
        animationProgress == 0.0) {
      return widget.centerPage;
    }

    // Determine which page is coming on screen and which is going off.
    // This depends on whether we are initiating a swipe from center or returning from a side page.
    Widget pageComingOnScreen;
    Widget pageGoingOffScreen;
    // The effective direction dictates the translation and scale logic.
    // If returning, it's the reverse of the direction that pushed the side page.
    // If swiping forward, it's the current swipe direction.
    SwipeDirection effectiveDirection;

    if (_isReturningToCenter) {
      // We are animating back to the center page (e.g., after a pop).
      // The center page is coming on screen, the side page is going off.
      pageComingOnScreen = widget.centerPage;
      // We need the widget of the page we are returning *from*.
      // _returningFromPageType must be non-null here.
      pageGoingOffScreen = _getPageWidgetByType(_returningFromPageType!);
      // The effective direction for calculating offsets is the *reverse*
      // direction of the original swipe that led to the side page.
      effectiveDirection = _currentSwipeDirection!;
    } else {
      // We are swiping or animating away from the center page.
      // The target side page is coming on screen, the center page is going off.
      pageComingOnScreen = _getSwipingPage();
      pageGoingOffScreen = widget.centerPage;
      // The effective direction is the detected swipe direction.
      effectiveDirection = _currentSwipeDirection!;
    }

    final size = MediaQuery.sizeOf(context);

    // Calculate offsets based on the animation progress (0.0 to 1.0).
    Offset offsetForOnScreen;
    Offset offsetForOffScreen;
    // Keep both pages at full scale (1.0) for the pushing effect
    const double scaleForOnScreen = 1.0;
    const double scaleForOffScreen = 1.0;

    if (_isReturningToCenter) {
      // Returning animation: progress goes from 1.0 (side page visible) to 0.0 (center visible).
      // Lerp calculations should go from the "end" state to the "start" state using the 0-1 progress.

      // Page Coming On Screen (Center Page): Starts off-screen (where it was pushed to)
      // and ends at (0,0). The 'start' for lerp is the end offset of the center page
      // when it was pushed off, and the 'end' is Offset.zero.
      final centerPushedOffset = _getCenterPageEndOffset(
          effectiveDirection, size); // Use the reverse direction
      offsetForOnScreen = Offset.lerp(centerPushedOffset, Offset.zero,
          1.0 - animationProgress)!; // Lerp from start (pushed) to end (0,0)
      // scaleForOnScreen = lerpDouble(widget.zoomOutScale, 1.0,
      //     1.0 - animationProgress)!; // Scale from zoomOutScale to 1.0

      // Page Going Off Screen (Side Page): Starts at (0,0) and ends off-screen
      // (where the incoming page would originate from). The 'start' for lerp is
      // Offset.zero, and the 'end' is the off-screen offset based on the
      // reverse direction.
      final sideOffScreenOffset = _getOffScreenOffset(
          effectiveDirection, size); // Use the reverse direction
      offsetForOffScreen = Offset.lerp(
          Offset.zero,
          sideOffScreenOffset,
          1.0 -
              animationProgress)!; // Lerp from start (0,0) to end (off-screen)
      // scaleForOffScreen = lerpDouble(1.0, widget.zoomOutScale,
      //     1.0 - animationProgress)!; // Scale from 1.0 to zoomOutScale
    } else {
      // Swiping/Animating forward: progress goes from 0.0 (center visible) to 1.0 (side page visible).
      // Lerp calculations should go from the "start" state to the "end" state using the 0-1 progress.

      // Page Going Off Screen (Center Page): Starts at (0,0) and ends off-screen.
      // The 'start' for lerp is Offset.zero, and the 'end' is the offset
      // where the center page is pushed off.
      final centerEndOffset = _getCenterPageEndOffset(effectiveDirection, size);
      offsetForOffScreen =
          Offset.lerp(Offset.zero, centerEndOffset, animationProgress)!;
      // scaleForOffScreen =
      //     lerpDouble(1.0, widget.zoomOutScale, animationProgress)!;

      // Page Coming On Screen (Side Page): Starts off-screen and ends at (0,0).
      // The 'start' for lerp is the off-screen offset, and the 'end' is Offset.zero.
      final sideStartOffset = _getOffScreenOffset(effectiveDirection, size);
      offsetForOnScreen =
          Offset.lerp(sideStartOffset, Offset.zero, animationProgress)!;
      // scaleForOnScreen =
      //     lerpDouble(widget.zoomOutScale, 1.0, animationProgress)!;
    }

    // Use a Stack to layer the pages. The page coming on screen is typically
    // rendered on top of the page going off screen to give the illusion of one
    // page sliding over the other.
    return Stack(
      children: [
        // Page going off screen (rendered below the incoming page)
        Transform.translate(
          offset: offsetForOffScreen,
          child: Transform.scale(
            scale: scaleForOffScreen,
            alignment: Alignment.center,
            child: pageGoingOffScreen,
          ),
        ),

        // Page coming on screen (rendered above the outgoing page)
        Transform.translate(
          offset: offsetForOnScreen,
          child: Transform.scale(
            scale: scaleForOnScreen,
            alignment: Alignment.center,
            child: pageComingOnScreen,
          ),
        ),
      ],
    );
  }
}

/// A wrapper widget for the pages displayed as side pages in the [FivePageNavigator].
///
/// It handles the system back button press (via [PopScope]) to notify the
/// parent navigator to start the return animation. It also optionally handles
/// a swipe gesture from the edge to perform a swipe-back animation and pop
/// itself from the navigator stack.
class PageWrapper extends StatefulWidget {
  /// The actual content of the page.
  final Widget child;

  /// The type of this page (e.g., PageType.left, PageType.right).
  ///
  /// Used to identify which page is being returned from.
  final PageType pageType;

  /// Callback invoked when the system back button is pressed and this page is
  /// popped from the navigator stack.
  ///
  /// Reports the [PageType] of this page so the parent navigator can animate
  /// back to the center. This callback is *not* called when the page is popped
  /// via the swipe-back gesture handled within this wrapper.
  final Function(PageType returnedFrom)? onReturnFromPage;

  /// Whether to enable the swipe-back gesture on this specific side page.
  final bool enableSwipeBack;

  final Widget centerPage;

  /// Creates a [PageWrapper].
  const PageWrapper({
    super.key,
    required this.child,
    required this.pageType,
    this.onReturnFromPage,
    this.enableSwipeBack = false,
    required this.centerPage,
  });

  @override
  State<PageWrapper> createState() => _PageWrapperState();
}

/// The state for [PageWrapper], managing the optional swipe-back animation.
class _PageWrapperState extends State<PageWrapper>
    with TickerProviderStateMixin {
  // --- Animation Controller ---

  /// Controller for the swipe-back animation within the PageWrapper.
  ///
  /// Used when [enableSwipeBack] is true. Controls the translation of the page
  /// as the user swipes to dismiss it.
  late AnimationController _swipeBackController;

  // --- Gesture State ---

  /// The starting position of the swipe-back drag gesture.
  double _swipeBackDragStart = 0.0;

  /// True if a valid swipe-back drag is currently in progress.
  bool _isSwipeBackDragging = false;

  // --- Lifecycle Methods ---

  @override
  void initState() {
    super.initState();
    // Initialize the controller for the swipe-back animation.
    _swipeBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    // Dispose of the controller to prevent resource leaks.
    _swipeBackController.dispose();
    super.dispose();
  }

  // --- Gesture Handling for Swipe-Back ---

  /// Handles the start of a pan gesture for the swipe-back.
  ///
  /// Checks if [enableSwipeBack] is true and if the drag started within
  /// the defined edge detection area for this page type.
  void _handlePanStart(DragStartDetails details) {
    // Ignore gesture if swipe-back is not enabled for this page.
    if (!widget.enableSwipeBack) return;

    // Define the width/height threshold for edge detection. Swipes must
    // start near the edge opposite the page's position relative to center.
    // This value determines how far from the edge the user must start swiping.
    // Note: This is different from FivePageNavigator's detection area.
    // It's the edge of the SIDE page itself.
    const double edgeThreshold = 200.0;
    final size = MediaQuery.sizeOf(context);
    bool isValidSwipeStart = false;

    // Determine the edge area based on the page type.
    switch (widget.pageType) {
      case PageType.left:
        // Left page: swipe back by swiping left from the *right* edge of the page.
        if (details.localPosition.dx >= size.width - edgeThreshold) {
          _swipeBackDragStart = details.localPosition.dx;
          isValidSwipeStart = true;
        }
        break;
      case PageType.right:
        // Right page: swipe back by swiping right from the *left* edge of the page.
        if (details.localPosition.dx <= edgeThreshold) {
          _swipeBackDragStart = details.localPosition.dx;
          isValidSwipeStart = true;
        }
        break;
      case PageType.top:
        // Top page: swipe back by swiping up from the *bottom* edge of the page.
        if (details.localPosition.dy >= size.height - edgeThreshold) {
          _swipeBackDragStart = details.localPosition.dy;
          isValidSwipeStart = true;
        }
        break;
      case PageType.bottom:
        // Bottom page: swipe back by swiping down from the *top* edge of the page.
        if (details.localPosition.dy <= edgeThreshold) {
          _swipeBackDragStart = details.localPosition.dy;
          isValidSwipeStart = true;
        }
        break;
      case PageType.center:
        // Swipe-back is not handled by PageWrapper for the center page.
        break;
    }

    // Set the flag indicating if a valid swipe-back drag has started.
    _isSwipeBackDragging = isValidSwipeStart;
  }

  /// Handles updates during the swipe-back pan gesture.
  ///
  /// Calculates the drag progress (0.0 to 1.0) and updates the animation
  /// controller value.
  void _handlePanUpdate(DragUpdateDetails details) {
    // Ignore updates if a valid swipe-back drag is not in progress.
    if (!_isSwipeBackDragging) return;

    final size = MediaQuery.sizeOf(context);
    double delta; // Change in position along the swipe axis relative to start.
    double maxSize; // The screen dimension along the swipe axis.
    double progress; // Calculated swipe progress (0.0 to 1.0).

    // Calculate delta and max size based on the page type and swipe direction.
    switch (widget.pageType) {
      case PageType.left:
        // Left page, swiping left from right edge. Delta is positive as user moves left.
        delta = _swipeBackDragStart - details.localPosition.dx;
        maxSize = size.width;
        break;
      case PageType.right:
        // Right page, swiping right from left edge. Delta is positive as user moves right.
        delta = details.localPosition.dx - _swipeBackDragStart;
        maxSize = size.width;
        break;
      case PageType.top:
        // Top page, swiping up from bottom edge. Delta is positive as user moves up.
        delta = _swipeBackDragStart - details.localPosition.dy;
        maxSize = size.height;
        break;
      case PageType.bottom:
        // Bottom page, swiping down from top edge. Delta is positive as user moves down.
        delta = details.localPosition.dy - _swipeBackDragStart;
        maxSize = size.height;
        break;
      case PageType.center:
        // Should not reach here if _isSwipeBackDragging is false for center page.
        delta = 0.0;
        maxSize = 1.0;
        break;
    }

    // Calculate the progress as a fraction of the screen size, clamped between 0.0 and 1.0.
    progress = (delta / maxSize).clamp(0.0, 1.0);

    // Update the controller value. This automatically triggers the AnimatedBuilder.
    // No setState is needed here.
    _swipeBackController.value = progress;
  }

  /// Handles the end of the swipe-back pan gesture.
  ///
  /// Decides whether to complete the swipe-back animation and pop the page
  /// (if threshold met, implicitly 0.5 based on animation value) or snap back
  /// to the full-screen state.
  void _handlePanEnd(DragEndDetails details) {
    // Ignore if a valid swipe-back drag was not in progress.
    if (!_isSwipeBackDragging) return;

    // Reset the dragging flag regardless of whether animation completes or snaps back.
    _isSwipeBackDragging = false;

    // Check if the swipe progress exceeded the halfway point.
    if (_swipeBackController.value >= 0.5) {
      // Swipe threshold met (implicitly 0.5 for this controller).
      // Animate the controller to 1.0 (fully off-screen).
      _swipeBackController.animateTo(1.0).then((_) {
        if (mounted) {
          // Animation complete, pop the page from the navigator stack.
          // Use a custom string result to signal the parent FivePageNavigator
          // that this was a gesture pop, so it shouldn't start *its* return animation.
          Navigator.of(context).pop("gesture_pop");
        }
      });
    } else {
      // Swipe threshold not met. Animate the controller back to 0.0 (fully visible).
      _swipeBackController.reverse();
    }
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    // Skip directly to the build with swipe-back enabled case
    if (!widget.enableSwipeBack) {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop && result != "gesture_pop") {
            widget.onReturnFromPage?.call(widget.pageType);
          }
        },
        child: widget.child,
      );
    }

    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _swipeBackController,
        builder: (context, child) {
          final size = MediaQuery.sizeOf(context);

          double sidePageTranslateX = 0.0;
          double sidePageTranslateY = 0.0;
          double centerPageTranslateX = 0.0;
          double centerPageTranslateY = 0.0;

          // Calculate both side page and center page translations
          switch (widget.pageType) {
            case PageType.left:
              // Side page moves left
              sidePageTranslateX = -_swipeBackController.value * size.width;
              // Center page moves right-to-center
              centerPageTranslateX =
                  size.width * (1.0 - _swipeBackController.value);
              break;
            case PageType.right:
              // Side page moves right
              sidePageTranslateX = _swipeBackController.value * size.width;
              // Center page moves left-to-center
              centerPageTranslateX =
                  -size.width * (1.0 - _swipeBackController.value);
              break;
            case PageType.top:
              // Side page moves up
              sidePageTranslateY = -_swipeBackController.value * size.height;
              // Center page moves bottom-to-center
              centerPageTranslateY =
                  size.height * (1.0 - _swipeBackController.value);
              break;
            case PageType.bottom:
              // Side page moves down
              sidePageTranslateY = _swipeBackController.value * size.height;
              // Center page moves top-to-center
              centerPageTranslateY =
                  -size.height * (1.0 - _swipeBackController.value);
              break;
            case PageType.center:
              break;
          }

          // Use a Stack to show both the side page and center page
          return Stack(
            children: [
              // Center page (underneath)
              Transform.translate(
                offset: Offset(centerPageTranslateX, centerPageTranslateY),
                child: widget.centerPage,
              ),
              // Side page (on top)
              Transform.translate(
                offset: Offset(sidePageTranslateX, sidePageTranslateY),
                child: PopScope(
                  canPop: true,
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
