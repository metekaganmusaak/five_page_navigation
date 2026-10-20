# Five Page Navigation

[![pub package](https://img.shields.io/pub/v/five_page_navigation.svg)](https://pub.dev/packages/five_page_navigation)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Snapchat-style navigation for Flutter: one center page and up to four side pages (left, right, top, bottom), opened with edge swipes and animated with any of 14 built-in transitions.

![Example](https://github.com/user-attachments/assets/c61374d6-1d58-456a-9333-ef02a799753e)

## Features

- **Edge swipes** from the center page open the page on that side; side pages can be swiped back.
- **14 transitions**: slide, parallax, cover, depth, reveal, fade, fade through, shared axis, zoom, scale, cube, flip, rotate and none, plus fully custom ones.
- **Gestures that play well with your content**: swipes only start inside configurable edge zones and in the right direction, so lists, page views and buttons keep working. Flings are supported.
- **Back button and `AppBar` integration**: the Android back button, `Navigator.pop` and the `AppBar` back arrow on a side page all return to the center page.
- **State is kept**: the center page is never rebuilt from scratch, side pages keep their state during transitions and optionally after them.
- **Controller** (`FivePageController`) and `FivePageNavigator.of(context)` for programmatic navigation, with `Future`s that complete when a transition ends.
- **Side page previews**, an optional **return button** that avoids app bars, **haptic feedback**, **keyboard shortcuts** and **reduced motion** support.
- Works on **Android, iOS, web, macOS, Windows and Linux**. Pure Dart, no platform plugins.

## Getting started

```yaml
dependencies:
  five_page_navigation: ^3.0.0
```

```dart
import 'package:five_page_navigation/five_page_navigation.dart';
```

## Usage

```dart
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _controller = FivePageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FivePageNavigator(
      controller: _controller,
      transition: const FivePageTransition.parallax(),
      centerPage: const CameraPage(),
      leftPage: const ChatPage(),
      rightPage: const StoriesPage(),
      topPage: const MemoriesPage(),
      bottomPage: const SpotlightPage(),
      enableLeftPageSwipeBack: true,
      enableRightPageSwipeBack: true,
      enableTopPageSwipeBack: true,
      enableBottomPageSwipeBack: true,
      onPageChanged: (page) => debugPrint('Now on ${page.name}'),
    );
  }
}
```

Every side page is optional. Pages are regular widgets, usually a `Scaffold`.

The navigator sizes itself to its constraints, so it can be the `home` of your app, the body of a tab, or a fixed-size box.

### Navigating from code

```dart
await _controller.navigateLeft();         // or navigateRight / navigateTop / navigateBottom
await _controller.navigateTo(PageType.top, animate: false);
await _controller.returnToCenter();

_controller.currentPage;                  // PageType.center, PageType.left, ...
_controller.isTransitioning;
```

Every method returns a `Future<bool>` that completes with `true` once the page is shown. Navigating from one side page to another goes through the center page.

`FivePageController` is a `ChangeNotifier`, so you can rebuild UI when the page changes:

```dart
ListenableBuilder(
  listenable: _controller,
  builder: (context, _) => Text(_controller.currentPage.name),
)
```

Inside a page you don't need a controller:

```dart
FivePageNavigator.of(context).returnToCenter();
```

## Transitions

Pass any of these to `transition`:

| Transition | Effect |
| --- | --- |
| `FivePageTransition.slide()` (default) | Both pages slide together. Optional fade with `incomingOpacityStart` / `outgoingOpacityEnd`. |
| `FivePageTransition.parallax()` | The new page slides over the old one, which moves slower and dims (iOS style). |
| `FivePageTransition.cover()` | The new page slides over the old one, which stays in place and dims. |
| `FivePageTransition.depth()` | Like cover, but the old page shrinks and gets rounded corners. |
| `FivePageTransition.reveal()` | The old page slides away and uncovers the new one. |
| `FivePageTransition.fade()` | Cross-fade. |
| `FivePageTransition.fadeThrough()` | Material fade through. |
| `FivePageTransition.sharedAxis()` | Material shared axis: short slide with fades. |
| `FivePageTransition.zoom()` | The new page zooms in, the old one zooms out. |
| `FivePageTransition.scale()` | The new page grows from the edge it comes from. |
| `FivePageTransition.cube()` | 3D cube rotation. |
| `FivePageTransition.flip()` | 3D card flip. |
| `FivePageTransition.rotate()` | Pages swing around a pivot. |
| `FivePageTransition.none()` | Instant switch. |

Most transitions take parameters, for example `FivePageTransition.depth(outgoingScale: 0.8, borderRadius: 32)`.

Timing is controlled by `transitionDuration` (default 300 ms) and `transitionCurve` (default `Curves.easeOutCubic`). After a drag, only the remaining part of the duration is used. When the platform asks to reduce motion, pages switch instantly.

Transitions that scale, fade or rotate show what is behind the pages; set `backgroundColor` to control it.

### Custom transitions

```dart
FivePageNavigator(
  transition: FivePageTransition.custom(
    incomingBuilder: (context, details, child) => Opacity(
      opacity: details.progress,
      child: Transform.scale(scale: 0.9 + 0.1 * details.progress, child: child),
    ),
    outgoingBuilder: (context, details, child) => FractionalTranslation(
      translation: details.vector * details.progress,
      child: child,
    ),
  ),
  // ...
)
```

`details` contains the linear `progress` (0 to 1, following the finger during a drag), the `direction` the content moves in, its unit `vector`, the navigator `size`, and the `from` and `to` pages. You can also extend `FivePageTransition` directly. Keep the widget structure the same for every `progress` value and only change the values, so pages are not rebuilt on every frame.

## Gestures

| Parameter | Default | Description |
| --- | --- | --- |
| `horizontalDetectionAreaWidth` | `100` | Width of the left and right edge zones of the center page. |
| `verticalDetectionAreaHeight` | `200` | Height of the top and bottom edge zones of the center page. |
| `swipeThreshold` | `0.25` | Fraction of the width or height a drag must cover to open a page. |
| `swipeBackThreshold` | `swipeThreshold` | Same, for swiping a side page back. |
| `enableLeftPageSwipeBack` (and right, top, bottom) | `false` | Allow swiping a side page back to the center. |
| `swipeBackDetectionAreaFraction` | `0.4` | Size of the swipe-back zone on the edge of a side page that faces the center. |
| `flingVelocityThreshold` | `700` | A faster release commits (or cancels) regardless of the threshold. |
| `canSwipeFromCenter` | `null` | Return `false` to ignore swipes from the center page. |
| `prioritizeEdgeSwipes` | `true` | Edge swipes win against scrollables inside the edge zones. Set to `false` to let same-axis scrollables win. |
| `swipeDeviceKinds` | all | Restrict which pointer kinds can swipe, e.g. `{PointerDeviceKind.touch}`. |
| `thresholdFeedback` | `heavy` | Haptic played when a drag crosses its threshold (`none`, `soft`, `medium`, `heavy`, `selection`). |

A drag only starts when the pointer goes down inside an edge zone **and** moves in the direction of a configured page. Any other gesture goes to your page content untouched.

## App bars and the back button

All pages live inside the route that contains the navigator. While a side page is open the navigator adds a `LocalHistoryEntry` to that route, which gives you:

- **The Android back button, `Navigator.maybePop` and `Navigator.pop(context)`** inside a side page return to the center page instead of leaving the screen.
- **`AppBar` back arrow**: a side page with an `AppBar` automatically shows a back button that returns to the center page. Disable it with `implyAppBarBackButton: false`, or per page with `AppBar(automaticallyImplyLeading: false)`.
- **iOS**: the swipe-back gesture of the enclosing `CupertinoPageRoute` is disabled while a side page is open, so it does not fight with the navigator.
- Pages **without an `AppBar`** are fine: handle the status bar with `SafeArea` as usual.
- If the navigator is the first route of your app and the **center page has an `AppBar`**, give it `automaticallyImplyLeading: false`. Otherwise it would briefly show a back arrow while it slides away, because all pages share one route.

Turn the whole behaviour off with `handleBackButton: false`. It also does nothing when the navigator is not inside a route (for example in `MaterialApp.builder`).

## Return button

`showReturnToCenterButton: true` adds a button to each side page, on the edge that faces the center page. It is useful on desktop and web, where edge swipes with a mouse are not obvious.

```dart
returnButtonStyle: const ReturnButtonStyle(
  backgroundColor: Colors.black54,
  iconColor: Colors.white,
  tooltip: 'Back',
  elevation: 2,
  respectScaffoldBars: true,
),
```

With `respectScaffoldBars` (default), the navigator measures the `AppBar` / `CupertinoNavigationBar` and `bottomNavigationBar` of each side page's outermost `Scaffold` and moves the button below or above them, so it never covers the title or the tabs. Without bars, the button only avoids the safe area.

Use `customButtonBuilder: (context, onPressed, pageType) => ...` to build your own button, `icon` to change the icon and `alignment` to move it.

## Previews

With `showSidePagePreviews: true`, dragging from the center page doesn't move the pages. Instead a small preview slides in from the edge; release past the threshold to open the page. The default preview is a labelled chip:

```dart
pagePreviewStyle: const PagePreviewStyle(
  leftPageLabel: 'Chat',
  rightPageLabel: 'Stories',
  defaultChipBackgroundColor: Colors.black54,
  previewOffsetFromEdge: 24,
),
```

Pass `leftPagePreviewWidget` (and friends) to show any widget instead.

## Keyboard

With `enableKeyboardShortcuts` (default `true`):

- <kbd>Alt</kbd> + <kbd>←</kbd> <kbd>→</kbd> <kbd>↑</kbd> <kbd>↓</kbd> on the center page opens the page in that direction.
- <kbd>Esc</kbd>, or <kbd>Alt</kbd> + the arrow pointing back to the center, returns from a side page.

Shortcuts work while the focus is inside the navigator and are skipped while a text field is being edited. Clicking the navigator with a mouse moves the focus into it; set `autofocus: true` to make them work right away.

## State and performance

- Pages are mounted under stable keys and never rebuilt by the animation. Each page is wrapped in a `RepaintBoundary`, so transitions mostly re-composite instead of repainting.
- The center page stays alive (offstage, with its animations paused) while a side page is open.
- A side page is built when its transition starts and disposed after you return. Set `maintainSidePageState: true` to keep visited side pages alive.
- Offstage pages are excluded from focus and from the accessibility tree.

## Platform notes

| Platform | Notes |
| --- | --- |
| Android | The back button returns to the center page. With gesture navigation, the system back gesture owns a narrow strip at the left and right screen edges, so keep `horizontalDetectionAreaWidth` wider than that (the default 100 is). |
| iOS | The home indicator sits at the very bottom edge; the default 200 pt bottom zone leaves plenty of room above it. |
| Web | Mouse and touch drags work. On mobile browsers, horizontal swipes from the very edge can trigger the browser's own back/forward navigation. |
| macOS, Windows, Linux | Drag with the mouse, use the keyboard shortcuts, or enable the return button. Haptics are skipped. |

## Callbacks

`onPageChanged(PageType)`, `onLeftPageOpened`, `onRightPageOpened`, `onTopPageOpened`, `onBottomPageOpened` and `onReturnCenterPage` are called once the transition has finished.

## Migrating from 2.x

- Side pages are no longer pushed as routes. `Navigator.pop(context)` inside a side page still returns to the center page, but `ModalRoute.of(context)` in a side page is now the route of the navigator.
- `incomingPageOpacityStart` is deprecated. Use `transition: FivePageTransition.slide(incomingOpacityStart: 0.3, outgoingOpacityEnd: 0.3)`. The default slide no longer fades.
- `FivePageController.navigateLeft()` and friends now return `Future<bool>`.
- `ThresholdVibration` gained `none` and `selection`. Exhaustive `switch` statements over it need the new cases.
- Swipe-back now uses `swipeBackThreshold` (defaults to `swipeThreshold`) instead of a fixed 50%.
- The `PagePreviewStyle` scale and appearance options are now applied.
- `centerPageEntranceAnimationDuration` can now be set without `animateCenterPageEntranceOpacity` (it used to throw an assertion error).

See the [changelog](CHANGELOG.md) for the full list.

## Example

The [example app](example/lib/main.dart) shows every transition, pages with and without app bars, previews, return buttons, swipe back and the controller. Run it on any platform:

```sh
cd example
flutter run -d chrome   # or macos, windows, linux, an emulator...
```
