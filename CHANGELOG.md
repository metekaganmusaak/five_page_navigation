# Changelog

## 3.0.0

A rewrite focused on reliability, performance and customization. See "Migrating from 2.x" in the README.

### Breaking changes

- Side pages are no longer pushed as `Navigator` routes. All pages live in the navigator's own widget tree, so the center page and the side pages are no longer built twice during transitions and keep their state. `Navigator.pop(context)` inside a side page still returns to the center page.
- `FivePageController.navigateLeft()`, `navigateRight()`, `navigateTop()` and `navigateBottom()` now return `Future<bool>`; `returnToCenter()` returns `Future<bool>` instead of `Future<void>`.
- `ThresholdVibration` has two new values: `none` and `selection`.
- `onPageChanged` is now a `ValueChanged<PageType>` and every callback fires once, after the transition has finished.
- The default slide transition no longer fades the pages.
- Swipe-back uses `swipeBackThreshold` (defaults to `swipeThreshold`) instead of a fixed 50% threshold.
- Minimum versions are now Dart 3.5 and Flutter 3.24.
- The `exports.dart` barrel files were removed; import `package:five_page_navigation/five_page_navigation.dart`.

### New

- 14 built-in transitions through `FivePageTransition`: `slide`, `parallax`, `cover`, `depth`, `reveal`, `fade`, `fadeThrough`, `sharedAxis`, `zoom`, `scale`, `cube`, `flip`, `rotate` and `none`, plus `FivePageTransition.custom` and subclassing for your own.
- `transitionDuration` and `transitionCurve`. Transitions are instant when the platform asks to reduce motion.
- Flings: a fast release commits or cancels regardless of the threshold (`flingVelocityThreshold`).
- Back button and `AppBar` integration: the Android back button, `Navigator.maybePop`, `Navigator.pop` and the automatic `AppBar` back arrow on side pages return to the center page (`handleBackButton`, `implyAppBarBackButton`). The iOS swipe-back gesture of the enclosing route is disabled while a side page is open.
- The return button avoids each page's `AppBar`, `CupertinoNavigationBar` and `bottomNavigationBar` (`ReturnButtonStyle.respectScaffoldBars`). New `icon`, `tooltip`, `elevation` and `alignment` options, accessibility label, and `copyWith`.
- `FivePageNavigator.of(context)` / `maybeOf(context)` and the public `FivePageNavigatorState`.
- `FivePageController`: `navigateTo(page)`, `isAttached`, `isTransitioning`, `canNavigateTo(page)`, an `animate` flag, and listener notifications when the page changes. Navigating between two side pages goes through the center page.
- Keyboard shortcuts for desktop and web: Alt + arrow keys and Esc (`enableKeyboardShortcuts`, `autofocus`).
- `maintainSidePageState`, `swipeBackThreshold`, `swipeBackDetectionAreaFraction`, `prioritizeEdgeSwipes`, `swipeDeviceKinds`, `backgroundColor` and `clipBehavior`.
- `PageType.isCenter`, `isSide`, `openDirection`, `returnDirection` and `SwipeDirection.axis`, `opposite`, `vector`.
- `PagePreviewStyle.copyWith`.

### Fixes

- Swipes only start inside the edge zones and in the direction of a configured page, so scrollables, page views and buttons in the pages keep working. Edge swipes are no longer lost to a scrollable under the finger.
- Edge zones and animations use the navigator's own size instead of the screen size, so the navigator works inside layouts that are not full screen and when a desktop or web window is resized.
- `onReturnCenterPage` was called twice after a swipe-back gesture, and `onPageChanged(PageType.center)` was not called at all.
- `FivePageController` never notified its listeners.
- The previews' `previewMinScale`, `previewMaxScale`, `previewAppearanceThreshold`, `previewOffsetFromEdge` and `previewScaleBeyondThresholdFactor` options had no effect.
- The preview overlay shrank the more you dragged, and the pages jumped when a preview drag was released.
- The swipe-back edge zone could be read before it was initialized (`LateInitializationError`) and was never updated on resize.
- The return button covered the title of the bottom page's `AppBar`.
- The center page entrance fade was animated twice.
- Setting `centerPageEntranceAnimationDuration` without `animateCenterPageEntranceOpacity` threw an assertion error.
- Haptic feedback is no longer sent on desktop platforms, which have no haptic engine.

### Performance

- Pages are never rebuilt by animations: transitions only update their transform and opacity wrappers, and every page sits behind a `RepaintBoundary`.
- Side pages are built lazily and disposed after use (unless `maintainSidePageState` is set). Offstage pages have their tickers paused and are excluded from focus and semantics.

### Example and tooling

- New example app showing every transition, pages with and without app bars, previews, return buttons, swipe back and the controller. Platform folders were regenerated for Android, iOS, macOS, Windows, Linux and web.
- Widget tests for gestures, the controller, the back button, state preservation and every transition.
- Stricter analysis options, full API documentation and pub.dev topics.

## 2.0.1

- Nothing changed, just updated logo to get more attention to the package :)

## 2.0.0

- Refactor and bug fixes.
- Remove setState's and replace it with ValueNotifier's to improve smoothness.
- Add page preview feature: Swipe from the edges to see tiny tooltip before navigating the side pages.
- Change folder structure and separate the files.
- Add FivePageController to handle navigations.
- Change some namings to be more clear.
- Implemented FadeIn animations while sliding between pages.

## 1.1.0

- Initial zoom animation replaced with FadeIn animation.
- Add optional return button to the side pages.
- Implement opacity variable while navigating side pages.

## 1.0.12

- Implement threshold feedback variable.

## 1.0.11

- Update ReadMe.

## 1.0.10

- Update ReadMe.

## 1.0.9

- Update ReadMe.

## 1.0.8

- Update ReadMe.

## 1.0.7

- Update ReadMe.

## 1.0.6

- Update ReadMe.

## 1.0.5

- Update ReadMe.

## 1.0.4

- Update ReadMe.

## 1.0.3

- Add initial zoom scale variable to control beginning scaling.
- Add swiping control variable to disable/enable swiping gestures inside CenterPage.

## 1.0.2

- Implement haptic feedback when user triggers threshold while swiping.

## 1.0.1

- Update ReadMe.

## 1.0.0

- Initial release.
