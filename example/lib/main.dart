import 'package:example/pages/bottom_page.dart';
import 'package:example/pages/center_page.dart';
import 'package:example/pages/left_page.dart';
import 'package:example/pages/right_page.dart';
import 'package:example/pages/top_page.dart';
import 'package:five_page_navigation/five_page_navigation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: BasePage(),
    );
  }
}

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
