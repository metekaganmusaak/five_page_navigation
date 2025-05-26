# Five Page Navigation

This package allows you to navigate between screen from one central page. You can swipe up, down, left and right with ease.

![Example](https://github.com/user-attachments/assets/c61374d6-1d58-456a-9333-ef02a799753e)

## Features

- Navigate to TopPage with scrolling top-to-bottom from top edge of the CenterPage. To navigate back, swipe bottom-to-top from bottom edge of the TopPage.
- Navigate to LeftPage with scrolling left-to-right from left edge of the CenterPage. To navigate back, swipe right-to-left from right edge of the LeftPage.
- Navigate to BottomPage with scrolling bottom-to-top from bottom edge of the CenterPage. To navigate back, swipe top-to-bottom from top edge of the BottomPage.
- Navigate to RightPage with scrolling right-to-left from right edge of the CenterPage. To navigate back, swipe left-to-right from left edge of the RightPage.
- You can control swipe threshold, animation durations and more.

## Getting started

In the `pubspec.yaml` of your flutter project, add the following dependency:

```yaml
dependencies:
  five_page_navigation: ^latest
```

Import these:

```dart
import 'package:five_page_navigation/five_page_navigation.dart';
```

## Usage

You can use sample code below.

```dart
class BasePage extends StatelessWidget {
  const BasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FivePageNavigator(
      centerPage: CenterPage(),
      leftPage: LeftPage(),
      rightPage: RightPage(),
      topPage: TopPage(),
      bottomPage: BottomPage(),
      enableLeftPageSwipeBack: true,
      enableBottomPageSwipeBack: true,
      enableRightPageSwipeBack: true,
      enableTopPageSwipeBack: true,
      swipeThreshold: .2,
      thresholdFeedback: ThresholdFeedback.heavyImpact,
      animateCenterPageEntranceOpacity: true,
      zoomOutScale: 1,

      verticalDetectionAreaHeight: 200,
      horizontalDetectionAreaWidth: 100,

      incomingPageOpacityStart: .2,
      centerPageEntranceAnimationDuration: Duration(seconds: 1),

      /// You can control swiping feature of the CenterPage. Default, enabled.
      canSwipeFromCenter: () {
        return true;
      },
      onBottomPageOpened: () {
        print('bottom page opened');
      },
      onLeftPageOpened: () {
        print('left page opened');
      },
      onRightPageOpened: () {
        print('right page opened');
      },
      onTopPageOpened: () async {
        print('top page opened');
      },
      onReturnCenterPage: () {
        print('return center page');
      },
      onPageChanged: (p0) {
        print('page changed: $p0');
      },
    );
  }
}
```
