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
class BasePage extends StatefulWidget {
  const BasePage({super.key});

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  late final FivePageController fivePageController;

  @override
  initState() {
    super.initState();
    fivePageController = FivePageController();
  }

  @override
  void dispose() {
    fivePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FivePageNavigator(
      controller: fivePageController,
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
      thresholdFeedback: ThresholdVibration.heavy,
      animateCenterPageEntranceOpacity: true,

      verticalDetectionAreaHeight: MediaQuery.sizeOf(context).height * .2,
      horizontalDetectionAreaWidth: MediaQuery.sizeOf(context).width * .2,

      incomingPageOpacityStart: 0.3,
      centerPageEntranceAnimationDuration: Duration(seconds: 1),

      /// You can control swiping feature of the CenterPage. Default, enabled.
      canSwipeFromCenter: () {
        return true;
      },
      onBottomPageOpened: () async {
        // print('bottom page opened');
        // await Future.delayed(Duration(seconds: 1));
        // fivePageController.returnToCenter();
      },
      onLeftPageOpened: () async {
        // print('left page opened');
        // await Future.delayed(Duration(seconds: 1));
        // fivePageController.returnToCenter();
      },
      onRightPageOpened: () async {
        // print('right page opened');
        // await Future.delayed(Duration(seconds: 1));
        // fivePageController.returnToCenter();
      },
      onTopPageOpened: () async {
        // print('on top page opened');
        // await Future.delayed(Duration(seconds: 1));
        // fivePageController.returnToCenter();
      },
      onReturnCenterPage: () async {
        // print('return center page');
        // await Future.delayed(Duration(seconds: 1));
        // fivePageController.returnToCenter();
      },
      onPageChanged: (p0) {
        print('page changed: $p0');
      },
      pagePreviewStyle: PagePreviewStyle(
        leftPagePreviewWidget: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            height: 160,
            width: 90,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: LeftPage()),
              ],
            ),
          ),
        ),
        leftPageLabel: "Left",
        rightPageLabel: "Right",
        topPageLabel: "Top",
        bottomPageLabel: "Bottom",
        defaultChipBackgroundColor: Colors.black54,
        defaultChipTextColor: Colors.white,
        defaultChipPadding:
            EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        defaultChipBorderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),

      showReturnToCenterButton: true,
      returnButtonStyle: ReturnButtonStyle(
        customButtonBuilder: (context, onPressed, pageType) {
          if (pageType == PageType.top) {
            return IconButton.filledTonal(
              color: Colors.black54,
              icon: Icon(Icons.arrow_downward, size: 32),
              onPressed: onPressed,
            );
          }

          if (pageType == PageType.bottom) {
            return IconButton.filledTonal(
              color: Colors.black54,
              icon: Icon(Icons.arrow_upward, size: 32),
              onPressed: onPressed,
            );
          }

          return SizedBox.shrink();
        },
      ),
      showSidePagePreviews: true,
    );
  }
}
```
