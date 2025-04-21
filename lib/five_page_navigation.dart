import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;

/// Represents the direction of a swipe gesture.
enum SwipeDirection {
  left,
  right,
  up,
  down,
}

/// Represents the type of a page in the navigator.
enum PageType {
  center,
  left,
  right,
  top,
  bottom,
}

/// A custom navigator widget that allows swiping between a center page
/// and four surrounding pages (left, right, top, bottom).
///
/// Includes an initial zoom-out animation showing all pages.
/// Supports navigating to side pages via swipe and returning via the back button.
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
  final Duration animationDuration;

  /// The initial delay before the zoom-out animation starts.
  final Duration initialWaitDuration;

  /// The fraction of the screen width/height that must be swiped
  /// to trigger a page transition (0.0 to 1.0).
  final double swipeThreshold;

  /// The scale factor for the inactive pages during swipe animations.
  /// A value of 1.0 means no zoom effect.
  final double zoomOutScale;

  /// Whether to show an AppBar on the side pages when navigated to.
  final bool showAppBar;

  /// Callback function invoked when the active page changes.
  /// Called with the target PageType after a successful navigation (push or pop).
  final Function(PageType)? onPageChanged;

  /// The height area at the top and bottom edges of the screen
  /// within which vertical swipes are detected. Swipes originating
  /// outside this area will not be registered as vertical swipes.
  final double verticalDetectionAreaHeight;

  /// The width area at the left and right edges of the screen
  /// within which horizontal swipes are detected. Swipes originating
  /// outside this area will not be registered as horizontal swipes.
  final double horizontalDetectionAreaWidth;

  /// Creates a [FivePageNavigator].
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
    this.showAppBar = false,
    this.onPageChanged,
    this.verticalDetectionAreaHeight = 200.0,
    this.horizontalDetectionAreaWidth = 100.0,
  });

  @override
  State<FivePageNavigator> createState() => _FivePageNavigatorState();
}

class _FivePageNavigatorState extends State<FivePageNavigator>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _zoomController;
  late AnimationController _swipeController;

  // State variables for gesture and animation management
  double _swipeOffset = 0;
  SwipeDirection? _currentSwipeDirection;
  Offset? _dragStartPosition;

  // Flags to manage overall state transitions
  bool _isInitialZoomCompleted = false;
  bool _isReturning = false; // True if animating back to center after pop
  PageType? _returnFromPageType; // Which page we are returning from

  @override
  void initState() {
    super.initState();

    // Controller for the initial zoom animation
    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Controller for swipe animations (drag and forward/reverse)
    _swipeController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Start the initial zoom animation after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(widget.initialWaitDuration, () {
        if (mounted) {
          _zoomController.forward().then((_) {
            if (mounted) {
              setState(() {
                _isInitialZoomCompleted = true;
              });
              // Notify listener that the center page is now active after zoom
              widget.onPageChanged?.call(PageType.center);
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  // --- Gesture Handling ---

  /// Handles the start of a pan gesture.
  /// Prevents gestures if initial zoom is not complete or an animation is running.
  void _handlePanStart(DragStartDetails details) {
    // Block gestures during initial zoom, during any swipe animation (forward or reverse),
    // or if currently in the process of returning from a pushed page.
    if (!_isInitialZoomCompleted ||
        _swipeController.isAnimating ||
        _isReturning) {
      _dragStartPosition = null;
      return;
    }

    _dragStartPosition = details.localPosition;
    _currentSwipeDirection = null;
    _swipeOffset = 0;
    // Reset controller value to 0 at the start of a new drag
    _swipeController.value = 0.0;
  }

  /// Handles updates during a pan gesture.
  /// Determines swipe direction and updates animation controller value based on drag progress.
  void _handlePanUpdate(DragUpdateDetails details) {
    // Continue blocking if drag wasn't properly started or animation is running
    if (_dragStartPosition == null ||
        _swipeController.isAnimating ||
        _isReturning) {
      return;
    }

    final screenSize = MediaQuery.of(context).size;

    // Determine direction if not already determined
    if (_currentSwipeDirection == null) {
      _determineSwipeDirection(details, screenSize);
      // If direction is determined, the AnimatedBuilder will start reacting
      // as soon as the controller value is updated.
    }

    // If direction is determined, update swipe offset and controller value
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

      // Accumulate swipe offset based on delta relative to screen dimension
      _swipeOffset += delta / dimension;

      // Clamp offset based on direction (0.0 to 1.0 or -1.0 to 0.0)
      if (_currentSwipeDirection == SwipeDirection.left ||
          _currentSwipeDirection == SwipeDirection.up) {
        _swipeOffset =
            _swipeOffset.clamp(-1.0, 0.0); // Negative progress for left/up
      } else {
        _swipeOffset =
            _swipeOffset.clamp(0.0, 1.0); // Positive progress for right/down
      }

      // Update the controller value. This automatically triggers the AnimatedBuilder.
      _swipeController.value = _swipeOffset.abs();
      // No setState needed here because AnimatedBuilder listens to _swipeController
    }
  }

  /// Determines the swipe direction based on drag start position and initial movement.
  /// Considers detection area limits.
  void _determineSwipeDirection(DragUpdateDetails details, Size screenSize) {
    final startX = _dragStartPosition!.dx;
    final startY = _dragStartPosition!.dy;
    final currentX = details.localPosition.dx;
    final currentY = details.localPosition.dy;
    final totalDeltaX = currentX - startX;
    final totalDeltaY = currentY - startY;
    final absDeltaX = totalDeltaX.abs();
    final absDeltaY = totalDeltaY.abs();

    // A small threshold to prevent minor jiggles from determining direction
    const double directionLockThreshold = 5.0; // Reduced threshold slightly

    if (absDeltaX > directionLockThreshold ||
        absDeltaY > directionLockThreshold) {
      if (absDeltaX > absDeltaY) {
        // Horizontal swipe detected
        // Check if swipe started within the horizontal detection area
        if (totalDeltaX > 0 && startX < widget.horizontalDetectionAreaWidth) {
          _currentSwipeDirection = SwipeDirection.right;
        } else if (totalDeltaX < 0 &&
            startX > screenSize.width - widget.horizontalDetectionAreaWidth) {
          _currentSwipeDirection = SwipeDirection.left;
        }
      } else {
        // Vertical swipe detected
        // Check if swipe started within the vertical detection area
        if (totalDeltaY > 0 && startY < widget.verticalDetectionAreaHeight) {
          _currentSwipeDirection = SwipeDirection.down;
        } else if (totalDeltaY < 0 &&
            startY > screenSize.height - widget.verticalDetectionAreaHeight) {
          _currentSwipeDirection = SwipeDirection.up;
        }
      }
      // Once direction is determined, _swipeController.value is set in _handlePanUpdate
    }
  }

  /// Handles the end of a pan gesture.
  /// Decides whether to animate to the target page or snap back to the center.
  void _handlePanEnd(DragEndDetails details) {
    // Ignore if no direction was determined or if an animation is already running
    if (_currentSwipeDirection == null ||
        _swipeController.isAnimating ||
        _isReturning) {
      // If returning, state will be reset when return animation finishes.
      // Otherwise, reset drag state immediately.
      if (!_isReturning) {
        _resetDragState();
      }
      return;
    }

    // Use the current value of the controller as the swipe progress
    final swipeProgress = _swipeController.value;

    if (swipeProgress >= widget.swipeThreshold) {
      _animateToPage(); // Animate to the target page
    } else {
      _animateBackToCenter(); // Animate back to the center
    }
  }

  /// Resets the state variables related to the drag gesture and forward animation.
  /// Called when a forward swipe is cancelled or completes successfully (leading to push).
  void _resetDragState() {
    if (mounted) {
      // No setState needed for controller value and flags here, as
      // the build method logic or animation completion handlers manage state.
      // Setting controller value directly and letting AnimatedBuilder react.
      _swipeOffset = 0;
      _currentSwipeDirection = null;
      _dragStartPosition = null;
      if (_swipeController.isAnimating) {
        _swipeController.stop();
      }
      _swipeController.value = 0.0;
      // _isReturning remains false
    }
  }

  /// Resets the state variables related to the return animation.
  /// Called when the return animation from a pushed page completes.
  void _resetReturnState() {
    if (mounted) {
      setState(() {
        _isReturning = false;
        _returnFromPageType = null;
        _currentSwipeDirection = null; // Clean up direction
        _swipeOffset = 0; // Clean up offset
        if (_swipeController.isAnimating) {
          _swipeController.stop();
        }
        _swipeController.value = 0.0; // Ensure controller is reset
        _dragStartPosition = null; // Clean up drag start
      });
      // onPageChanged callback for PageType.center is already called in _handleReturnFromPage
    }
  }

  // --- Animation Logic ---

  /// Starts the animation to transition from the center page to a side page.
  void _animateToPage() {
    if (_currentSwipeDirection == null || _swipeController.isAnimating) return;

    // State change to indicate animation is running.
    // No setState needed here, _swipeController.forward drives the AnimatedBuilder.
    _isReturning = false;

    // Start animation from current value to 1.0
    _swipeController.forward(from: _swipeController.value).then((_) {
      // Animation finished, proceed to navigate (push the new page)
      if (mounted) {
        _navigateToPageActual();
        // State cleanup (_resetDragState) will happen indirectly via
        // the logic flow after push/pop, or is no longer needed here.
      }
    }).catchError((error) {
      // Handle potential animation errors
      if (mounted) _resetDragState();
    });
  }

  /// Starts the animation to snap back to the center page after a swipe gesture
  /// did not reach the threshold.
  void _animateBackToCenter() {
    if (_currentSwipeDirection == null || _swipeController.isAnimating) return;

    // State change to indicate animation is running.
    // No setState needed here, _swipeController.reverse drives the AnimatedBuilder.
    _isReturning = false;

    // Start animation from current value back to 0.0
    _swipeController.reverse(from: _swipeController.value).then((_) {
      // Animation finished, reset drag state
      if (mounted) {
        _resetDragState();
      }
    }).catchError((error) {
      // Handle potential animation errors
      if (mounted) _resetDragState();
    });
  }

  /// Handles the event when a pushed page is popped (e.g., via back button).
  /// Starts the reverse animation to transition back to the center page.
  void _handleReturnFromPage(PageType returnedFrom) {
    if (!mounted || _swipeController.isAnimating || _isReturning) return;

    final reverseDirection = _getReverseSwipeDirection(returnedFrom);
    if (reverseDirection == null) {
      // This case shouldn't happen if returnedFrom is one of the side pages
      _resetReturnState();
      return;
    }

    // Update state to indicate return animation is starting
    setState(() {
      _isReturning = true;
      _returnFromPageType = returnedFrom;
      _currentSwipeDirection = reverseDirection;
      // Ensure controller value is 1.0 at the start of the reverse animation
      _swipeController.value = 1.0;
    });

    // Notify listener that we are transitioning back to the center page
    widget.onPageChanged?.call(PageType.center);

    // Start the reverse animation (1.0 -> 0.0)
    _swipeController.reverse(from: 1.0).then((_) {
      // Animation complete, reset return state
      if (mounted) {
        _resetReturnState();
      }
    }).catchError((error) {
      // Handle potential animation errors
      if (mounted) {
        _resetReturnState();
      }
    });
  }

  // --- Navigation ---

  /// Pushes the target page onto the Navigator stack.
  void _navigateToPageActual() {
    if (_currentSwipeDirection == null) {
      _resetDragState();
      return;
    }

    PageType targetPage;
    Widget targetWidget;

    switch (_currentSwipeDirection!) {
      case SwipeDirection.left:
        targetPage = PageType.right;
        targetWidget = widget.rightPage;
        break;
      case SwipeDirection.right:
        targetPage = PageType.left;
        targetWidget = widget.leftPage;
        break;
      case SwipeDirection.up:
        targetPage = PageType.bottom;
        targetWidget = widget.bottomPage;
        break;
      case SwipeDirection.down:
        targetPage = PageType.top;
        targetWidget = widget.topPage;
        break;
    }

    // The swipe animation (_swipeController.forward) is already complete here.
    // Now, navigate to the target page.
    // The state variables related to the forward swipe (_swipeOffset, _currentSwipeDirection)
    // are intentionally NOT reset immediately. They are needed for the visual
    // state just before the push happens (the side page is fully on screen, center is off).
    // They will be reset implicitly or explicitly later.

    // Use PageRouteBuilder with Duration.zero to prevent default navigation animation.
    // The visual transition is handled by the swipe animation *before* the push.
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false, // Keep the underlying FivePageNavigator visible
        pageBuilder: (context, animation, secondaryAnimation) => PageWrapper(
          pageType: targetPage,
          showAppBar: widget.showAppBar,
          onReturnFromPage: (returnedFrom) {
            // This callback is triggered by PopScope when the page is popped
            _handleReturnFromPage(returnedFrom);
          },
          child: targetWidget,
        ),
        // Zero duration ensures no default push/pop animation
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) {
      // This .then block is called when the PUSHED page is popped.
      // The logic to handle the return animation is in _handleReturnFromPage,
      // triggered by PopScope. So, nothing specifically needed here.
      // The drag state is also reset as part of the return animation cleanup.
    });

    // Reset drag state immediately after Navigator.push is called.
    // The visual state before push is held by the last frame of the forward animation.
    _resetDragState();
    // Note: onPageChanged callback for the target page is called just before push in _animateToPage.
  }

  // --- Helper Functions ---

  /// Returns the reverse swipe direction for a given page type.
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
        return null; // Should not happen
    }
  }

  /// Calculates the final offset of the center page when it's pushed off-screen.
  Offset _getCenterPageEndOffset(SwipeDirection swipeDirection, Size size) {
    switch (swipeDirection) {
      case SwipeDirection.left:
        return Offset(-size.width, 0); // Swipe left, center moves left
      case SwipeDirection.right:
        return Offset(size.width, 0); // Swipe right, center moves right
      case SwipeDirection.up:
        return Offset(0, -size.height); // Swipe up, center moves up
      case SwipeDirection.down:
        return Offset(0, size.height); // Swipe down, center moves down
    }
  }

  /// Calculates the starting offset for the incoming page (off-screen).
  Offset _getOffScreenOffset(SwipeDirection direction, Size size) {
    switch (direction) {
      case SwipeDirection.left:
        return Offset(size.width, 0); // Right page comes from right
      case SwipeDirection.right:
        return Offset(-size.width, 0); // Left page comes from left
      case SwipeDirection.up:
        return Offset(0, size.height); // Bottom page comes from bottom
      case SwipeDirection.down:
        return Offset(0, -size.height); // Top page comes from top
    }
  }

  /// Returns the target page widget based on the current swipe direction (forward swipe).
  Widget _getSwipingPage() {
    if (_currentSwipeDirection == null) return const SizedBox.shrink();
    switch (_currentSwipeDirection!) {
      case SwipeDirection.left:
        return widget.rightPage;
      case SwipeDirection.right:
        return widget.leftPage;
      case SwipeDirection.up:
        return widget.bottomPage;
      case SwipeDirection.down:
        return widget.topPage;
    }
  }

  /// Returns a page widget based on its type.
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
    // Show the initial zoom animation view until it completes
    if (!_isInitialZoomCompleted) {
      // AnimatedBuilder listens to the zoom controller and rebuilds the view
      return AnimatedBuilder(
        animation: _zoomController,
        builder: (context, child) {
          return _buildInitialZoomContent(_zoomController.value);
        },
      );
    }

    // Once initial zoom is complete, show the interactive swipe view
    // AnimatedBuilder listens to the swipe controller for drag and animation updates
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      behavior: HitTestBehavior.opaque, // Capture gestures over the entire area
      child: Container(
        clipBehavior: Clip.hardEdge,
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(),
        child: AnimatedBuilder(
          animation: _swipeController,
          builder: (context, child) {
            // _buildSwipeContent handles both drag state and animation state
            return _buildSwipeContent(_swipeController.value);
          },
        ),
      ),
    );
  }

  /// Builds the content for the initial zoom-out animation.
  /// Uses the animationProgress (0.0 to 1.0) to calculate transformations.
  Widget _buildInitialZoomContent(double animationProgress) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const double initialViewScale = 0.5;
    const double spacing = 15.0;

    // Scale interpolation: side pages scale from initialViewScale down to near zero,
    // center page scales from initialViewScale up to 1.0.
    final sideScale = lerpDouble(initialViewScale, 0.0, animationProgress)!;
    final centerScale = lerpDouble(initialViewScale, 1.0, animationProgress)!;

    // Calculate initial positions of all pages in the zoomed-out view
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
    final initialSideY = initialCenterY; // Y alignment for left/right
    final initialSideX = initialCenterX; // X alignment for top/bottom

    // Calculate final off-screen positions for side pages
    final finalLeftX = -initialSideWidth;
    final finalRightX = screenWidth;
    final finalTopY = -initialSideHeight;
    final finalBottomY = screenHeight;
    // Final center position is (0,0) relative to the screen
    const finalCenterX = 0.0;
    const finalCenterY = 0.0;
    // Final side alignment positions (centered relative to final center position)
    final finalSideY = finalCenterY + (screenHeight - initialSideHeight) / 2;
    final finalSideX = finalCenterX + (screenWidth - initialSideWidth) / 2;

    // Interpolate positions based on animation progress
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

    // If side pages are scaled down significantly, only draw the center page for performance
    if (sideScale < 0.05) {
      // Use a small threshold instead of 0.01
      return Transform.translate(
        offset: Offset(currentCenterX, currentCenterY),
        child: Transform.scale(
          scale: centerScale,
          alignment: Alignment.center,
          child: SizedBox(
            width:
                screenWidth, // Ensure page covers full screen when scale is 1
            height: screenHeight,
            child: widget.centerPage,
          ),
        ),
      );
    }

    // Draw all pages during the animation
    return Stack(
      children: [
        // Side Pages (positioned and scaled)
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

        // Center Page (positioned and scaled)
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

  /// Builds the content during swipe (drag) and swipe animations (forward/reverse).
  /// Uses the animationProgress (_swipeController.value) to calculate transformations.
  Widget _buildSwipeContent(double animationProgress) {
    // If not dragging or animating, just show the center page.
    // This covers the idle state.
    if (_currentSwipeDirection == null &&
        !_isReturning &&
        !_swipeController.isAnimating) {
      return widget.centerPage;
    }

    // Determine which page is coming on screen and which is going off
    Widget pageComingOnScreen;
    Widget pageGoingOffScreen;
    SwipeDirection effectiveDirection; // The direction governing the animation

    if (_isReturning) {
      // Returning to center: center page comes on, side page goes off
      pageComingOnScreen = widget.centerPage;
      pageGoingOffScreen = _getPageWidgetByType(_returnFromPageType!);
      effectiveDirection =
          _currentSwipeDirection!; // This is the reverse direction set in _handleReturnFromPage
    } else {
      // Swiping/Animating away from center: side page comes on, center page goes off
      pageComingOnScreen = _getSwipingPage();
      pageGoingOffScreen = widget.centerPage;
      effectiveDirection =
          _currentSwipeDirection!; // This is the forward swipe direction
    }

    final size = MediaQuery.of(context).size;

    // Calculate offsets and scales based on animation progress (0.0 to 1.0)
    // The interpretation of progress depends on whether we are returning or not.

    Offset offsetForOnScreen;
    Offset offsetForOffScreen;
    double scaleForOnScreen;
    double scaleForOffScreen;

    if (_isReturning) {
      // Returning: progress goes 1.0 -> 0.0. Lerps should use (end, start, progress)
      // Coming on screen (Center): Lerp from pushed position to (0,0)
      final centerEndOffset = _getCenterPageEndOffset(
          effectiveDirection, size); // Use reverse direction
      offsetForOnScreen = Offset.lerp(Offset.zero, centerEndOffset,
          animationProgress)!; // (0,0) is end, centerEnd is start for reverse
      scaleForOnScreen = lerpDouble(1.0, widget.zoomOutScale,
          animationProgress)!; // 1.0 is end, zoomOutScale is start for reverse

      // Going off screen (Side): Lerp from (0,0) to off-screen position
      final sideEndOffset = _getOffScreenOffset(
          effectiveDirection, size); // Use reverse direction
      offsetForOffScreen = Offset.lerp(sideEndOffset, Offset.zero,
          animationProgress)!; // off-screen is end, (0,0) is start for reverse
      scaleForOffScreen = lerpDouble(widget.zoomOutScale, 1.0,
          animationProgress)!; // zoomOutScale is end, 1.0 is start for reverse
    } else {
      // Swiping/Animating forward: progress goes 0.0 -> 1.0. Lerps use (start, end, progress)
      // Going off screen (Center): Lerp from (0,0) to pushed position
      final centerEndOffset = _getCenterPageEndOffset(effectiveDirection, size);
      offsetForOffScreen =
          Offset.lerp(Offset.zero, centerEndOffset, animationProgress)!;
      scaleForOffScreen =
          lerpDouble(1.0, widget.zoomOutScale, animationProgress)!;

      // Coming on screen (Side): Lerp from off-screen position to (0,0)
      final targetStartOffset = _getOffScreenOffset(effectiveDirection, size);
      offsetForOnScreen =
          Offset.lerp(targetStartOffset, Offset.zero, animationProgress)!;
      scaleForOnScreen =
          lerpDouble(widget.zoomOutScale, 1.0, animationProgress)!;
    }

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

/// A wrapper widget for the pages displayed in the FivePageNavigator.
///
/// Includes an optional AppBar and handles the back button press
/// to notify the navigator to start the return animation.
class PageWrapper extends StatelessWidget {
  /// The content of the page.
  final Widget child;

  /// The type of this page (e.g., PageType.left, PageType.right).
  final PageType pageType;

  /// Whether to display a standard AppBar.
  final bool showAppBar;

  /// Callback invoked when the back button is pressed and the page is popped.
  /// Reports which page type is being returned from.
  final Function(PageType returnedFrom)? onReturnFromPage;

  /// Creates a [PageWrapper].
  const PageWrapper({
    super.key,
    required this.child,
    required this.pageType,
    required this.showAppBar,
    this.onReturnFromPage,
  });

  @override
  Widget build(BuildContext context) {
    // PopScope detects when a pop gesture/event occurs
    return PopScope(
      canPop: true, // This page can be popped
      onPopInvoked: (didPop) {
        // If the pop was successful (not blocked by something else)
        if (didPop) {
          // Call the return callback to signal the FivePageNavigator
          onReturnFromPage?.call(pageType);
        }
      },
      child: showAppBar
          ? Scaffold(
              appBar: AppBar(
                // Automatically shows a back button when not on the first route
                title: Text(pageType.toString().split('.').last.toUpperCase()),
              ),
              body: child,
            )
          : child, // If showAppBar is false, just show the child
    );
  }
}
