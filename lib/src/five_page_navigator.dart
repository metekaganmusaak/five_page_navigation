import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'configs/page_preview_style.dart';
import 'configs/return_button_style.dart';
import 'enums/page_type.dart';
import 'enums/swipe_direction.dart';
import 'enums/threshold_vibration.dart';
import 'gestures/edge_swipe_recognizer.dart';
import 'transitions/five_page_transition.dart';
import 'utils/haptics.dart';
import 'widgets/return_button.dart';

part 'five_page_controller.dart';

const Duration _kPreviewHideDuration = Duration(milliseconds: 180);
const Duration _kPreviewArmDuration = Duration(milliseconds: 150);

/// Navigates between a center page and up to four side pages (left, right,
/// top and bottom) with edge swipes, like Snapchat.
///
/// * Drag from an edge of the center page to open the page on that side.
///   Edge zones are configured with [horizontalDetectionAreaWidth] and
///   [verticalDetectionAreaHeight].
/// * Drag a side page back towards the center to close it, when enabled with
///   [enableLeftPageSwipeBack] and friends.
/// * Use a [FivePageController], [FivePageNavigator.of], the optional return
///   button ([showReturnToCenterButton]), the system back button, the
///   `AppBar` back button or the keyboard to navigate.
///
/// All pages live in a single route. The center page keeps its state while a
/// side page is open, and a side page keeps its state for as long as it is
/// visible (or forever with [maintainSidePageState]).
///
/// The navigator sizes itself to the incoming constraints, so it does not
/// need to be full screen.
class FivePageNavigator extends StatefulWidget {
  /// Creates a five page navigator.
  const FivePageNavigator({
    super.key,
    required this.centerPage,
    this.leftPage,
    this.rightPage,
    this.topPage,
    this.bottomPage,
    this.controller,
    this.transition,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionCurve = Curves.easeOutCubic,
    this.swipeThreshold = 0.25,
    this.swipeBackThreshold,
    this.flingVelocityThreshold = 700.0,
    this.verticalDetectionAreaHeight = 200.0,
    this.horizontalDetectionAreaWidth = 100.0,
    this.swipeBackDetectionAreaFraction = 0.4,
    this.enableLeftPageSwipeBack = false,
    this.enableRightPageSwipeBack = false,
    this.enableTopPageSwipeBack = false,
    this.enableBottomPageSwipeBack = false,
    this.canSwipeFromCenter,
    this.prioritizeEdgeSwipes = true,
    this.swipeDeviceKinds,
    this.thresholdFeedback = ThresholdVibration.heavy,
    this.onPageChanged,
    this.onReturnCenterPage,
    this.onLeftPageOpened,
    this.onRightPageOpened,
    this.onTopPageOpened,
    this.onBottomPageOpened,
    this.showSidePagePreviews = false,
    this.pagePreviewStyle,
    @Deprecated(
      'Use transition: FivePageTransition.slide(incomingOpacityStart: x, '
      'outgoingOpacityEnd: x) instead. '
      'This feature was deprecated after v3.0.0.',
    )
    this.incomingPageOpacityStart,
    this.animateCenterPageEntranceOpacity = false,
    this.centerPageEntranceAnimationDuration = kThemeAnimationDuration,
    this.showReturnToCenterButton = false,
    this.returnButtonStyle,
    this.maintainSidePageState = false,
    this.handleBackButton = true,
    this.implyAppBarBackButton = true,
    this.enableKeyboardShortcuts = true,
    this.autofocus = false,
    this.backgroundColor,
    this.clipBehavior = Clip.hardEdge,
  })  : assert(swipeThreshold > 0 && swipeThreshold <= 1),
        assert(
          swipeBackThreshold == null ||
              (swipeBackThreshold > 0 && swipeBackThreshold <= 1),
        ),
        assert(flingVelocityThreshold > 0),
        assert(verticalDetectionAreaHeight >= 0),
        assert(horizontalDetectionAreaWidth >= 0),
        assert(
          swipeBackDetectionAreaFraction >= 0 &&
              swipeBackDetectionAreaFraction <= 1,
        ),
        assert(
          incomingPageOpacityStart == null ||
              (incomingPageOpacityStart >= 0 && incomingPageOpacityStart <= 1),
        );

  /// The page shown when no side page is open.
  final Widget centerPage;

  /// The page revealed by swiping right from the left edge. Optional.
  final Widget? leftPage;

  /// The page revealed by swiping left from the right edge. Optional.
  final Widget? rightPage;

  /// The page revealed by swiping down from the top edge. Optional.
  final Widget? topPage;

  /// The page revealed by swiping up from the bottom edge. Optional.
  final Widget? bottomPage;

  /// Controls the navigator programmatically and reports the active page.
  final FivePageController? controller;

  /// How the pages animate. Defaults to [FivePageTransition.slide].
  ///
  /// See [FivePageTransition] for the built-in transitions, or use
  /// [FivePageTransition.custom] to write your own.
  final FivePageTransition? transition;

  /// Duration of a complete transition. A transition that settles after a
  /// drag only takes the remaining fraction of this duration.
  ///
  /// Transitions are instant when the platform asks to reduce motion
  /// ([MediaQueryData.disableAnimations]).
  final Duration transitionDuration;

  /// Curve applied while a transition settles.
  final Curve transitionCurve;

  /// Fraction of the navigator's width or height a drag must cover to open a
  /// side page. Also used for swipe-back when [swipeBackThreshold] is `null`.
  final double swipeThreshold;

  /// Fraction of the navigator's width or height a swipe-back drag must
  /// cover to return to the center page. Defaults to [swipeThreshold].
  final double? swipeBackThreshold;

  /// Speed, in logical pixels per second, above which a released drag
  /// completes (or cancels, when flung backwards) regardless of the
  /// threshold.
  final double flingVelocityThreshold;

  /// Height of the zones at the top and bottom edges of the center page
  /// where vertical swipes can start.
  final double verticalDetectionAreaHeight;

  /// Width of the zones at the left and right edges of the center page where
  /// horizontal swipes can start.
  final double horizontalDetectionAreaWidth;

  /// Size of the zone, as a fraction of the navigator's width or height, from
  /// which a swipe-back gesture can start on a side page. The zone lies on
  /// the edge that faces the center page.
  final double swipeBackDetectionAreaFraction;

  /// Whether the left page can be closed by swiping left.
  final bool enableLeftPageSwipeBack;

  /// Whether the right page can be closed by swiping right.
  final bool enableRightPageSwipeBack;

  /// Whether the top page can be closed by swiping up.
  final bool enableTopPageSwipeBack;

  /// Whether the bottom page can be closed by swiping down.
  final bool enableBottomPageSwipeBack;

  /// Called when a pointer lands on an edge zone of the center page. Return
  /// `false` to ignore swipes, for example while a camera is recording.
  final bool Function()? canSwipeFromCenter;

  /// Whether swipes that start inside an edge zone win against scrollables
  /// and other drag gestures of the pages.
  ///
  /// When `true` (the default), the navigator claims a drag in the edge zone
  /// as soon as it moves half the usual touch slop in an allowed direction.
  /// When `false`, a scrollable under the pointer that scrolls along the same
  /// axis takes the gesture.
  final bool prioritizeEdgeSwipes;

  /// Pointer kinds that can swipe between pages. `null` allows all kinds,
  /// including the mouse on desktop and web.
  final Set<PointerDeviceKind>? swipeDeviceKinds;

  /// Haptic feedback played when a drag crosses its threshold and when the
  /// default return button is tapped. Only plays on Android and iOS.
  final ThresholdVibration thresholdFeedback;

  /// Called after a transition completes with the new active page.
  final ValueChanged<PageType>? onPageChanged;

  /// Called after returning to the center page.
  final VoidCallback? onReturnCenterPage;

  /// Called after the left page has opened.
  final VoidCallback? onLeftPageOpened;

  /// Called after the right page has opened.
  final VoidCallback? onRightPageOpened;

  /// Called after the top page has opened.
  final VoidCallback? onTopPageOpened;

  /// Called after the bottom page has opened.
  final VoidCallback? onBottomPageOpened;

  /// Whether dragging from the center page shows a preview of the side page
  /// instead of moving the pages. See [PagePreviewStyle].
  final bool showSidePagePreviews;

  /// Appearance of the previews shown when [showSidePagePreviews] is `true`.
  final PagePreviewStyle? pagePreviewStyle;

  /// Opacity of the incoming page when the default slide transition starts.
  @Deprecated(
    'Use transition: FivePageTransition.slide(incomingOpacityStart: x, '
    'outgoingOpacityEnd: x) instead. '
    'This feature was deprecated after v3.0.0.',
  )
  final double? incomingPageOpacityStart;

  /// Whether the center page fades in when the navigator is first shown.
  final bool animateCenterPageEntranceOpacity;

  /// Duration of the center page fade-in.
  final Duration centerPageEntranceAnimationDuration;

  /// Whether side pages show a button that returns to the center page.
  ///
  /// Recommended on desktop and web, where edge swipes with a mouse are not
  /// discoverable.
  final bool showReturnToCenterButton;

  /// Appearance of the return button.
  final ReturnButtonStyle? returnButtonStyle;

  /// Whether side pages stay alive (offstage, with their tickers paused)
  /// after the user returns to the center page.
  ///
  /// When `false` (the default), a side page is built when its transition
  /// starts and disposed after the user returns to the center page, which
  /// keeps memory usage low. The center page is always kept alive.
  final bool maintainSidePageState;

  /// Whether the system back button (Android, browser-less web) and
  /// `Navigator.maybePop` return to the center page while a side page is
  /// open.
  ///
  /// This uses a [LocalHistoryEntry] on the enclosing [ModalRoute], so it
  /// does nothing when the navigator is not inside a route (for example in
  /// `MaterialApp.builder`). It also disables the iOS swipe-back gesture of
  /// the enclosing route while a side page is open.
  final bool handleBackButton;

  /// Whether an `AppBar` on a side page shows its automatic back button,
  /// which returns to the center page.
  ///
  /// Only applies when [handleBackButton] is `true`. Set it to `false` when
  /// side pages show their own leading widget or the return button.
  final bool implyAppBarBackButton;

  /// Whether hardware keyboard shortcuts are enabled.
  ///
  /// * <kbd>Alt</kbd> + arrow key on the center page opens the page in that
  ///   direction.
  /// * <kbd>Esc</kbd>, or <kbd>Alt</kbd> + the arrow key pointing back to the
  ///   center, returns from a side page.
  ///
  /// Shortcuts are handled while the focus is inside the navigator and no
  /// text field is being edited. Clicking the navigator with a mouse moves the
  /// focus into it.
  final bool enableKeyboardShortcuts;

  /// Whether the navigator requests focus when it is first built, so the
  /// keyboard shortcuts work immediately.
  final bool autofocus;

  /// Color painted behind the pages. Visible through transparent pages and
  /// during transitions that scale, fade or rotate the pages.
  final Color? backgroundColor;

  /// How pages that move outside the navigator's bounds are clipped.
  final Clip clipBehavior;

  /// The state of the closest [FivePageNavigator] that encloses [context].
  ///
  /// Throws when there is none; see [maybeOf].
  static FivePageNavigatorState of(BuildContext context) {
    final state = maybeOf(context);
    assert(() {
      if (state == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('FivePageNavigator.of() called with a context that '
              'does not contain a FivePageNavigator.'),
          ErrorHint('Call it from a widget that is built inside one of the '
              'pages, or use a FivePageController.'),
          context.describeElement('The context used was'),
        ]);
      }
      return true;
    }());
    return state!;
  }

  /// The state of the closest [FivePageNavigator] that encloses [context],
  /// or `null`.
  static FivePageNavigatorState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<FivePageNavigatorState>();
  }

  @override
  State<FivePageNavigator> createState() => FivePageNavigatorState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('leftPage',
          value: leftPage != null, ifTrue: 'has left page'))
      ..add(FlagProperty('rightPage',
          value: rightPage != null, ifTrue: 'has right page'))
      ..add(FlagProperty('topPage',
          value: topPage != null, ifTrue: 'has top page'))
      ..add(FlagProperty('bottomPage',
          value: bottomPage != null, ifTrue: 'has bottom page'))
      ..add(DiagnosticsProperty<FivePageTransition>('transition', transition,
          defaultValue: null))
      ..add(DiagnosticsProperty<Duration>(
          'transitionDuration', transitionDuration))
      ..add(DoubleProperty('swipeThreshold', swipeThreshold))
      ..add(DoubleProperty('swipeBackThreshold', swipeBackThreshold,
          defaultValue: null))
      ..add(EnumProperty<ThresholdVibration>(
          'thresholdFeedback', thresholdFeedback))
      ..add(FlagProperty('showSidePagePreviews',
          value: showSidePagePreviews, ifTrue: 'previews'))
      ..add(FlagProperty('showReturnToCenterButton',
          value: showReturnToCenterButton, ifTrue: 'return button'))
      ..add(FlagProperty('maintainSidePageState',
          value: maintainSidePageState, ifTrue: 'maintain side page state'))
      ..add(DiagnosticsProperty<FivePageController>('controller', controller,
          defaultValue: null));
  }
}

/// The state of a [FivePageNavigator].
///
/// Obtain it with [FivePageNavigator.of] from inside a page to navigate
/// without a [FivePageController].
class FivePageNavigatorState extends State<FivePageNavigator>
    with TickerProviderStateMixin {
  late final AnimationController _transitionController;
  late final AnimationController _previewController;
  late final AnimationController _entranceController;
  late Animation<double> _entranceOpacity;

  final Map<PageType, GlobalKey> _pageKeys = <PageType, GlobalKey>{
    for (final type in PageType.values)
      type: GlobalKey(debugLabel: 'FivePageNavigator.${type.name}'),
  };
  final FocusNode _focusNode = FocusNode(
    debugLabel: 'FivePageNavigator',
    skipTraversal: true,
  );

  /// Side pages that were opened at least once, kept alive when
  /// [FivePageNavigator.maintainSidePageState] is `true`.
  final Set<PageType> _visitedPages = <PageType>{};

  PageType _currentPage = PageType.center;

  // The running transition, if any.
  PageType? _from;
  PageType? _to;
  SwipeDirection? _direction;
  Completer<bool>? _transitionCompleter;

  bool _isDragging = false;
  bool _thresholdReached = false;

  /// The side page whose preview is shown while dragging from the center.
  PageType? _previewTarget;

  ModalRoute<Object?>? _route;
  LocalHistoryEntry? _historyEntry;
  bool _removingHistoryEntry = false;

  Size _size = Size.zero;

  /// The active page. During a transition this is the page the transition
  /// started from.
  PageType get currentPage => _currentPage;

  /// Whether a drag or an animation between pages is in progress.
  bool get isTransitioning => _to != null || _isDragging;

  /// Whether [page] is configured.
  bool canNavigateTo(PageType page) => _pageWidget(page) != null;

  /// Shows [page] and completes with `true` once it is the active page.
  ///
  /// * Navigating to a side page from another side page returns to the
  ///   center first.
  /// * While the user drags, the call is ignored and completes with `false`.
  /// * While a transition runs, navigating to its destination waits for it,
  ///   and navigating to its origin reverses it. Other targets are ignored.
  /// * Completes with `false` when [page] is not configured or the
  ///   transition was interrupted (for example by the back button).
  Future<bool> navigateTo(PageType page, {bool animate = true}) async {
    if (!mounted || _isDragging) return false;
    if (_pageWidget(page) == null) return false;

    final running = _to;
    if (running != null) {
      if (running == page) return _transitionCompleter!.future;
      if (_from == page) {
        await _settle(commit: false, animate: animate);
        return mounted && _currentPage == page;
      }
      return false;
    }

    if (page == _currentPage) return true;

    if (page.isSide && _currentPage.isSide) {
      final returned = await navigateTo(PageType.center, animate: animate);
      if (!returned || !mounted) return false;
      return navigateTo(page, animate: animate);
    }

    _beginTransition(page);
    return _settle(commit: true, animate: animate);
  }

  /// Returns to the center page. See [navigateTo].
  Future<bool> returnToCenter({bool animate = true}) =>
      navigateTo(PageType.center, animate: animate);

  // --- Lifecycle -------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(vsync: this);
    _previewController = AnimationController(vsync: this);
    _entranceController = AnimationController(
      vsync: this,
      duration: widget.centerPageEntranceAnimationDuration,
      value: widget.animateCenterPageEntranceOpacity ? 0.0 : 1.0,
    );
    _entranceOpacity = _createEntranceOpacity();
    if (widget.animateCenterPageEntranceOpacity) _entranceController.forward();
    _focusNode.canRequestFocus = widget.enableKeyboardShortcuts;
    widget.controller?._attach(this);
  }

  Animation<double> _createEntranceOpacity() =>
      widget.animateCenterPageEntranceOpacity
          ? CurvedAnimation(parent: _entranceController, curve: Curves.easeIn)
          : kAlwaysCompleteAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      final hadEntry = _historyEntry != null;
      _removeHistoryEntry();
      _route = route;
      if (hadEntry) _scheduleHistorySync();
    }
  }

  @override
  void didUpdateWidget(FivePageNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }

    _entranceController.duration = widget.centerPageEntranceAnimationDuration;
    if (widget.animateCenterPageEntranceOpacity !=
        oldWidget.animateCenterPageEntranceOpacity) {
      _entranceOpacity = _createEntranceOpacity();
    }
    _focusNode.canRequestFocus = widget.enableKeyboardShortcuts;

    if (widget.handleBackButton != oldWidget.handleBackButton ||
        widget.implyAppBarBackButton != oldWidget.implyAppBarBackButton) {
      _removeHistoryEntry();
      _scheduleHistorySync();
    }

    _handleRemovedPages();
  }

  /// Leaves pages that are no longer configured.
  void _handleRemovedPages() {
    bool missing(PageType? type) => type != null && _pageWidget(type) == null;
    _visitedPages.removeWhere(missing);
    if (!missing(_from) &&
        !missing(_to) &&
        !missing(_currentPage) &&
        !missing(_previewTarget)) {
      return;
    }

    final previous = _currentPage;
    final completer = _transitionCompleter;
    _transitionController.stop();
    _transitionController.value = 0;
    _previewController.value = 0;
    _from = _to = _direction = _previewTarget = null;
    _transitionCompleter = null;
    _isDragging = false;
    if (missing(_currentPage)) _currentPage = PageType.center;
    completer?.complete(false);

    // Notify outside of the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncHistory();
      if (previous != _currentPage) _notifyPageChanged(_currentPage);
      widget.controller?._notify();
    }, debugLabel: 'FivePageNavigator.removedPages');
  }

  @override
  void dispose() {
    _removeHistoryEntry();
    widget.controller?._detach(this);
    if (!(_transitionCompleter?.isCompleted ?? true)) {
      _transitionCompleter!.complete(false);
    }
    _transitionController.dispose();
    _previewController.dispose();
    _entranceController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // --- Helpers ---------------------------------------------------------------

  Widget? _pageWidget(PageType type) => switch (type) {
        PageType.center => widget.centerPage,
        PageType.left => widget.leftPage,
        PageType.right => widget.rightPage,
        PageType.top => widget.topPage,
        PageType.bottom => widget.bottomPage,
      };

  bool _swipeBackEnabled(PageType type) => switch (type) {
        PageType.center => false,
        PageType.left => widget.enableLeftPageSwipeBack,
        PageType.right => widget.enableRightPageSwipeBack,
        PageType.top => widget.enableTopPageSwipeBack,
        PageType.bottom => widget.enableBottomPageSwipeBack,
      };

  /// The side page revealed by dragging the center page in [direction].
  PageType? _pageRevealedBy(SwipeDirection direction) {
    final type = switch (direction) {
      SwipeDirection.right => PageType.left,
      SwipeDirection.left => PageType.right,
      SwipeDirection.down => PageType.top,
      SwipeDirection.up => PageType.bottom,
    };
    return _pageWidget(type) != null ? type : null;
  }

  FivePageTransition get _effectiveTransition {
    final transition = widget.transition;
    if (transition != null) return transition;
    // ignore: deprecated_member_use_from_same_package
    final opacity = widget.incomingPageOpacityStart ?? 1.0;
    return FivePageSlideTransition(
      incomingOpacityStart: opacity,
      outgoingOpacityEnd: opacity,
    );
  }

  double get _activeThreshold => _to == PageType.center
      ? widget.swipeBackThreshold ?? widget.swipeThreshold
      : widget.swipeThreshold;

  void _notifyPageChanged(PageType page) {
    widget.onPageChanged?.call(page);
    switch (page) {
      case PageType.center:
        widget.onReturnCenterPage?.call();
      case PageType.left:
        widget.onLeftPageOpened?.call();
      case PageType.right:
        widget.onRightPageOpened?.call();
      case PageType.top:
        widget.onTopPageOpened?.call();
      case PageType.bottom:
        widget.onBottomPageOpened?.call();
    }
  }

  // --- Transitions -----------------------------------------------------------

  void _beginTransition(PageType target) {
    final from = _currentPage;
    setState(() {
      _from = from;
      _to = target;
      _direction =
          target.isCenter ? from.returnDirection : target.openDirection;
      _transitionCompleter = Completer<bool>();
      if (target.isSide) _visitedPages.add(target);
    });
    _transitionController.value = 0;
    _thresholdReached = false;
    widget.controller?._notify();
  }

  /// Animates the running transition to its end ([commit]) or back to its
  /// start, then completes it.
  Future<bool> _settle({required bool commit, bool animate = true}) {
    final completer = _transitionCompleter!;
    final target = commit ? 1.0 : 0.0;
    final distance = (target - _transitionController.value).abs();

    // When opening a side page, add the history entry right away so the
    // incoming page's AppBar shows its back button during the animation.
    // When returning, the entry is removed in [_finishTransition] instead, so
    // the leaving page's AppBar does not change while it is still visible.
    if (commit && _to!.isSide) _syncHistory(_to);

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!animate ||
        reduceMotion ||
        distance == 0 ||
        widget.transitionDuration == Duration.zero ||
        _effectiveTransition is FivePageNoTransition) {
      _transitionController.stop();
      _transitionController.value = target;
      _finishTransition(reached: commit);
      return completer.future;
    }

    _transitionController
        .animateTo(
          target,
          duration: widget.transitionDuration * distance,
          curve: widget.transitionCurve,
        )
        .orCancel
        .then<void>(
      (_) {
        if (mounted && identical(_transitionCompleter, completer)) {
          _finishTransition(reached: commit);
        }
      },
      // Interrupted by another settle call or by dispose.
      onError: (Object _) {},
    );
    return completer.future;
  }

  void _finishTransition({required bool reached}) {
    final from = _from;
    final to = _to;
    if (from == null || to == null) return;
    final completer = _transitionCompleter;
    final newPage = reached ? to : from;
    final changed = newPage != _currentPage;

    setState(() {
      _currentPage = newPage;
      _from = _to = _direction = null;
      _transitionCompleter = null;
      _isDragging = false;
    });
    _transitionController.value = 0;
    _syncHistory();

    completer?.complete(reached);
    if (changed) _notifyPageChanged(newPage);
    widget.controller?._notify();
  }

  // --- Back button -----------------------------------------------------------

  /// Adds or removes the local history entry so that it exists exactly while
  /// [page] (defaults to the active page) is a side page.
  void _syncHistory([PageType? page]) {
    final wantsEntry = (page ?? _currentPage).isSide &&
        widget.handleBackButton &&
        _route != null;
    if (wantsEntry == (_historyEntry != null)) return;

    if (!wantsEntry) {
      _removeHistoryEntry();
      return;
    }
    // Adding an entry rebuilds the route, which is not allowed during build.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      _scheduleHistorySync();
      return;
    }
    final entry = LocalHistoryEntry(
      onRemove: _handleHistoryEntryRemoved,
      impliesAppBarDismissal: widget.implyAppBarBackButton,
    );
    _historyEntry = entry;
    _route!.addLocalHistoryEntry(entry);
  }

  void _scheduleHistorySync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncHistory(_to ?? _currentPage);
    }, debugLabel: 'FivePageNavigator.syncHistory');
  }

  void _removeHistoryEntry() {
    final entry = _historyEntry;
    if (entry == null) return;
    _historyEntry = null;
    _removingHistoryEntry = true;
    try {
      entry.remove();
    } finally {
      _removingHistoryEntry = false;
    }
  }

  /// Called when the route pops our entry: the back button was pressed, or
  /// a side page called `Navigator.pop`.
  void _handleHistoryEntryRemoved() {
    if (_removingHistoryEntry) return;
    _historyEntry = null;
    if (!mounted) return;

    final to = _to;
    if (to == null) {
      if (_currentPage.isSide) {
        _beginTransition(PageType.center);
        _settle(commit: true);
      }
    } else {
      // A drag cannot continue after the page was popped.
      _isDragging = false;
      _settle(commit: to.isCenter);
    }
  }

  // --- Gestures --------------------------------------------------------------

  Set<SwipeDirection> _allowedDirectionsAt(Offset position) {
    if (isTransitioning || _size.isEmpty) return const <SwipeDirection>{};
    final width = _size.width;
    final height = _size.height;
    final directions = <SwipeDirection>{};

    if (_currentPage.isCenter) {
      if (!(widget.canSwipeFromCenter?.call() ?? true)) return directions;
      final h = widget.horizontalDetectionAreaWidth;
      final v = widget.verticalDetectionAreaHeight;
      if (widget.leftPage != null && position.dx <= h) {
        directions.add(SwipeDirection.right);
      }
      if (widget.rightPage != null && position.dx >= width - h) {
        directions.add(SwipeDirection.left);
      }
      if (widget.topPage != null && position.dy <= v) {
        directions.add(SwipeDirection.down);
      }
      if (widget.bottomPage != null && position.dy >= height - v) {
        directions.add(SwipeDirection.up);
      }
      return directions;
    }

    if (!_swipeBackEnabled(_currentPage)) return directions;
    final f = widget.swipeBackDetectionAreaFraction;
    final inZone = switch (_currentPage) {
      PageType.left => position.dx >= width * (1 - f),
      PageType.right => position.dx <= width * f,
      PageType.top => position.dy >= height * (1 - f),
      PageType.bottom => position.dy <= height * f,
      PageType.center => false,
    };
    if (inZone) directions.add(_currentPage.returnDirection!);
    return directions;
  }

  bool _handleDragStart(SwipeDirection direction) {
    if (isTransitioning) return false;

    if (_currentPage.isCenter) {
      final target = _pageRevealedBy(direction);
      if (target == null) return false;
      _isDragging = true;
      _thresholdReached = false;
      if (widget.showSidePagePreviews) {
        _previewController.stop();
        _previewController.value = 0;
        setState(() => _previewTarget = target);
      } else {
        _beginTransition(target);
      }
      return true;
    }

    if (direction != _currentPage.returnDirection) return false;
    _isDragging = true;
    _beginTransition(PageType.center);
    return true;
  }

  /// The direction and controller driven by the current drag.
  (SwipeDirection, AnimationController, double)? get _dragTarget {
    final preview = _previewTarget;
    if (preview != null && _to == null) {
      return (
        preview.openDirection!,
        _previewController,
        widget.swipeThreshold
      );
    }
    final direction = _direction;
    if (direction == null) return null;
    return (direction, _transitionController, _activeThreshold);
  }

  void _handleDragUpdate(Offset delta) {
    if (!_isDragging) return;
    final target = _dragTarget;
    if (target == null) return;
    final (direction, controller, threshold) = target;

    final extent =
        direction.axis == Axis.horizontal ? _size.width : _size.height;
    if (extent <= 0) return;
    final vector = direction.vector;
    final along = delta.dx * vector.dx + delta.dy * vector.dy;
    controller.value = (controller.value + along / extent).clamp(0.0, 1.0);

    final reached = controller.value >= threshold;
    if (reached && !_thresholdReached) {
      playThresholdFeedback(widget.thresholdFeedback);
    }
    _thresholdReached = reached;
  }

  void _handleDragEnd(Velocity velocity) {
    if (!_isDragging) return;
    final target = _dragTarget;
    _isDragging = false;
    _thresholdReached = false;
    if (target == null) return;
    final (direction, controller, threshold) = target;

    final vector = direction.vector;
    final speed = velocity.pixelsPerSecond.dx * vector.dx +
        velocity.pixelsPerSecond.dy * vector.dy;
    final commit = speed.abs() >= widget.flingVelocityThreshold
        ? speed > 0
        : controller.value >= threshold;

    if (identical(controller, _previewController)) {
      _endPreview(commit: commit);
    } else {
      _settle(commit: commit);
    }
  }

  void _handleDragCancel() {
    if (!_isDragging) return;
    _isDragging = false;
    _thresholdReached = false;
    if (_previewTarget != null && _to == null) {
      _endPreview(commit: false);
    } else if (_to != null) {
      _settle(commit: false);
    }
  }

  void _endPreview({required bool commit}) {
    final target = _previewTarget!;
    _previewController
        .animateTo(0, duration: _kPreviewHideDuration, curve: Curves.easeOut)
        .orCancel
        .then<void>(
      (_) {
        if (mounted && _previewTarget == target && !_isDragging) {
          setState(() => _previewTarget = null);
        }
      },
      onError: (Object _) {},
    );
    if (commit) {
      _beginTransition(target);
      _settle(commit: true);
    }
  }

  // --- Keyboard --------------------------------------------------------------

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enableKeyboardShortcuts &&
        event.kind == PointerDeviceKind.mouse &&
        !_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  bool get _isEditingText {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return false;
    return focusContext.widget is EditableText ||
        focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enableKeyboardShortcuts ||
        event is! KeyDownEvent ||
        isTransitioning ||
        _isEditingText) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (_currentPage.isCenter) return KeyEventResult.ignored;
      returnToCenter();
      return KeyEventResult.handled;
    }

    if (!HardwareKeyboard.instance.isAltPressed) return KeyEventResult.ignored;
    final PageType? page = switch (key) {
      LogicalKeyboardKey.arrowLeft => PageType.left,
      LogicalKeyboardKey.arrowRight => PageType.right,
      LogicalKeyboardKey.arrowUp => PageType.top,
      LogicalKeyboardKey.arrowDown => PageType.bottom,
      _ => null,
    };
    if (page == null) return KeyEventResult.ignored;

    if (_currentPage.isCenter) {
      if (!canNavigateTo(page)) return KeyEventResult.ignored;
      navigateTo(page);
      return KeyEventResult.handled;
    }
    // The arrow pointing from the side page towards the center.
    if (page.openDirection == _currentPage.openDirection) {
      returnToCenter();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // --- Build -----------------------------------------------------------------

  void _handleReturnButtonPressed() {
    if (isTransitioning) return;
    playThresholdFeedback(widget.thresholdFeedback);
    returnToCenter();
  }

  /// The pages that are currently mounted, in a stable order.
  Iterable<PageType> get _alivePages => PageType.values.where((type) {
        if (_pageWidget(type) == null) return false;
        return type.isCenter ||
            type == _currentPage ||
            type == _from ||
            type == _to ||
            (widget.maintainSidePageState && _visitedPages.contains(type));
      });

  /// The page itself, under a [GlobalKey] so that it keeps its state while it
  /// moves between the transition wrappers.
  Widget _buildPageContent(PageType type) {
    final page = _pageWidget(type)!;
    final Widget child;
    if (type.isCenter) {
      child = FadeTransition(opacity: _entranceOpacity, child: page);
    } else {
      child = Stack(
        fit: StackFit.expand,
        children: <Widget>[
          page,
          if (widget.showReturnToCenterButton)
            ReturnButtonOverlay(
              pageType: type,
              style: widget.returnButtonStyle ?? const ReturnButtonStyle(),
              onPressed: _handleReturnButtonPressed,
              pageKey: _pageKeys[type]!,
            ),
        ],
      );
    }
    return KeyedSubtree(
      key: _pageKeys[type],
      child: RepaintBoundary(child: child),
    );
  }

  Widget _buildSlot(
    PageType type, {
    required bool visible,
    Widget Function(Widget child)? wrap,
  }) {
    var child = _buildPageContent(type);
    if (wrap != null) child = wrap(child);
    return KeyedSubtree(
      key: ValueKey<PageType>(type),
      child: Offstage(
        offstage: !visible,
        child: TickerMode(
          enabled: visible,
          child: ExcludeFocus(
            excluding: !visible || type != _currentPage,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildPages(BuildContext context, Size size) {
    final from = _from;
    final to = _to;
    final direction = _direction;
    final children = <Widget>[
      for (final type in _alivePages)
        if (type != _currentPage && type != to)
          _buildSlot(type, visible: false),
    ];

    if (from != null && to != null && direction != null) {
      final transition = _effectiveTransition;
      final details = FivePageTransitionDetails(
        progress: _transitionController.value,
        direction: direction,
        size: size,
        from: from,
        to: to,
      );
      final outgoing = _buildSlot(
        from,
        visible: true,
        wrap: (child) => transition.buildOutgoing(context, details, child),
      );
      final incoming = _buildSlot(
        to,
        visible: true,
        wrap: (child) => transition.buildIncoming(context, details, child),
      );
      children.addAll(transition.incomingOnTop
          ? <Widget>[outgoing, incoming]
          : <Widget>[incoming, outgoing]);
    } else {
      children.add(_buildSlot(_currentPage, visible: true));
    }

    return IgnorePointer(
      ignoring: to != null,
      child: Stack(fit: StackFit.expand, children: children),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final target = _previewTarget;
    final value = _previewController.value;
    if (target == null || value <= 0) return const SizedBox.shrink();

    final style = widget.pagePreviewStyle ?? const PagePreviewStyle();
    final vector = target.openDirection!.vector;
    final appearAt = style.previewAppearanceThreshold;
    final appear = appearAt == null ? 1.0 : (value / appearAt).clamp(0.0, 1.0);
    final armed = value >= widget.swipeThreshold;

    final (custom, label) = switch (target) {
      PageType.left => (style.leftPagePreviewWidget, style.leftPageLabel),
      PageType.right => (style.rightPagePreviewWidget, style.rightPageLabel),
      PageType.top => (style.topPagePreviewWidget, style.topPageLabel),
      PageType.bottom => (style.bottomPagePreviewWidget, style.bottomPageLabel),
      PageType.center => (null, ''),
    };

    final preview = Material(
      type: MaterialType.transparency,
      child: custom ??
          DecoratedBox(
            decoration: BoxDecoration(
              color: style.defaultChipBackgroundColor,
              borderRadius: style.defaultChipBorderRadius,
            ),
            child: Padding(
              padding: style.defaultChipPadding,
              child: Text(
                label,
                style: style.defaultChipTextStyle ??
                    TextStyle(
                      color: style.defaultChipTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
    );

    return IgnorePointer(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(style.previewOffsetFromEdge),
          child: Align(
            alignment: Alignment(-vector.dx, -vector.dy),
            child: FractionalTranslation(
              translation: -vector * (1 - appear),
              child: Opacity(
                opacity: appear,
                child: AnimatedScale(
                  scale: armed ? style.previewScaleBeyondThresholdFactor : 1.0,
                  duration: _kPreviewArmDuration,
                  curve: Curves.easeOutBack,
                  child: Transform.scale(
                    scale: lerpDouble(
                      style.previewMinScale,
                      style.previewMaxScale,
                      appear,
                    )!,
                    child: preview,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The detector is a child-less layer above the pages. Being hit first,
    // its recognizer sees every pointer move before the pages' recognizers
    // do, so an edge swipe is not lost to a scrollable that crosses its slop
    // on the same event (the same trick Drawer uses).
    final edgeDetector = RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        EdgeSwipeGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<EdgeSwipeGestureRecognizer>(
          () => EdgeSwipeGestureRecognizer(debugOwner: this),
          (recognizer) => recognizer
            ..supportedDevices = widget.swipeDeviceKinds
            ..prioritize = widget.prioritizeEdgeSwipes
            ..resolveDirections = _allowedDirectionsAt
            ..onStart = _handleDragStart
            ..onUpdate = _handleDragUpdate
            ..onEnd = _handleDragEnd
            ..onCancel = _handleDragCancel,
        ),
      },
    );

    // Pages are built here, during the build phase, and never inside a
    // LayoutBuilder: moving a page between transition wrappers reparents its
    // GlobalKey, which must not happen during layout (pages may contain
    // OverlayPortals, for example tooltips).
    Widget content = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        AnimatedBuilder(
          animation: _transitionController,
          builder: (context, _) => _buildPages(context, _size),
        ),
        AnimatedBuilder(
          animation: _previewController,
          builder: (context, _) => _buildPreview(context),
        ),
        edgeDetector,
      ],
    );

    final background = widget.backgroundColor;
    if (background != null) {
      content = ColoredBox(color: background, child: content);
    }
    if (widget.clipBehavior != Clip.none) {
      content = ClipRect(clipBehavior: widget.clipBehavior, child: content);
    }

    return _NavigatorBox(
      fallbackSize: MediaQuery.maybeSizeOf(context) ?? Size.zero,
      onLayout: (size) => _size = size,
      child: Focus(
        focusNode: _focusNode,
        autofocus: widget.autofocus && widget.enableKeyboardShortcuts,
        onKeyEvent: _handleKeyEvent,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _handlePointerDown,
          child: content,
        ),
      ),
    );
  }
}

/// Sizes the navigator to its constraints (falling back to [fallbackSize]
/// on unbounded axes) and reports the size after each layout.
///
/// The size is only read by gestures and by transition frames built after
/// the first layout, so recording it without a rebuild is safe.
class _NavigatorBox extends SingleChildRenderObjectWidget {
  const _NavigatorBox({
    required this.fallbackSize,
    required this.onLayout,
    super.child,
  });

  final Size fallbackSize;
  final ValueChanged<Size> onLayout;

  @override
  _RenderNavigatorBox createRenderObject(BuildContext context) =>
      _RenderNavigatorBox(fallbackSize: fallbackSize, onLayout: onLayout);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderNavigatorBox renderObject,
  ) {
    renderObject
      ..fallbackSize = fallbackSize
      ..onLayout = onLayout;
  }
}

class _RenderNavigatorBox extends RenderProxyBox {
  _RenderNavigatorBox({
    required Size fallbackSize,
    required this.onLayout,
  }) : _fallbackSize = fallbackSize;

  ValueChanged<Size> onLayout;

  Size get fallbackSize => _fallbackSize;
  Size _fallbackSize;
  set fallbackSize(Size value) {
    if (value == _fallbackSize) return;
    _fallbackSize = value;
    if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
      markNeedsLayout();
    }
  }

  Size _resolveSize(BoxConstraints constraints) {
    return constraints.constrain(Size(
      constraints.hasBoundedWidth ? constraints.maxWidth : fallbackSize.width,
      constraints.hasBoundedHeight
          ? constraints.maxHeight
          : fallbackSize.height,
    ));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _resolveSize(constraints);

  @override
  void performLayout() {
    size = _resolveSize(constraints);
    child?.layout(BoxConstraints.tight(size));
    onLayout(size);
  }
}
