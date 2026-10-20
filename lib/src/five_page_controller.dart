part of 'five_page_navigator.dart';

/// Controls a [FivePageNavigator] from outside its subtree.
///
/// Create the controller in a [State], pass it to
/// [FivePageNavigator.controller] and dispose it in [State.dispose].
///
/// The controller is a [ChangeNotifier]: listeners are notified when a
/// transition starts and when the active page changes, so it can drive a
/// [ListenableBuilder] that shows [currentPage].
///
/// Descendants of the navigator can use [FivePageNavigator.of] instead.
class FivePageController extends ChangeNotifier {
  FivePageNavigatorState? _state;
  bool _disposed = false;

  /// Whether the controller is attached to a mounted [FivePageNavigator].
  bool get isAttached => _state != null;

  /// The active page. [PageType.center] when the controller is not attached.
  ///
  /// During a transition this is still the page the transition started
  /// from; it changes once the transition completes.
  PageType get currentPage => _state?.currentPage ?? PageType.center;

  /// Whether a drag or an animation between pages is in progress.
  bool get isTransitioning => _state?.isTransitioning ?? false;

  /// Whether [page] is configured on the attached navigator.
  bool canNavigateTo(PageType page) => _state?.canNavigateTo(page) ?? false;

  /// Shows [page]. See [FivePageNavigatorState.navigateTo].
  ///
  /// Completes with `false` when the controller is not attached.
  Future<bool> navigateTo(PageType page, {bool animate = true}) {
    return _state?.navigateTo(page, animate: animate) ??
        Future<bool>.value(false);
  }

  /// Shows the left page.
  Future<bool> navigateLeft({bool animate = true}) =>
      navigateTo(PageType.left, animate: animate);

  /// Shows the right page.
  Future<bool> navigateRight({bool animate = true}) =>
      navigateTo(PageType.right, animate: animate);

  /// Shows the top page.
  Future<bool> navigateTop({bool animate = true}) =>
      navigateTo(PageType.top, animate: animate);

  /// Shows the bottom page.
  Future<bool> navigateBottom({bool animate = true}) =>
      navigateTo(PageType.bottom, animate: animate);

  /// Returns to the center page.
  Future<bool> returnToCenter({bool animate = true}) =>
      navigateTo(PageType.center, animate: animate);

  void _attach(FivePageNavigatorState state) => _state = state;

  void _detach(FivePageNavigatorState state) {
    if (identical(_state, state)) _state = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _state = null;
    super.dispose();
  }
}
