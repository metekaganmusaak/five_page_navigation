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

      /// Side page swiping scale. Default 1.0
      zoomOutScale: 1,
      verticalDetectionAreaHeight: 200,
      horizontalDetectionAreaWidth: 100,

      /// Previews
      showSidePagePreviews: true,
      previewConfig: PagePreviewConfig(
        previewScaleBeyondThresholdFactor: 1.5,
        previewMaxScale: 1.5,
        previewMinScale: 0.5,
        shakeIntensity: 0,
        shakeFrequencyFactor: 0,
        bottomPagePreviewWidget: Chip(
          label: Text('Store'),
          avatar: Icon(Icons.store),
        ),
        leftPagePreviewWidget: Card(
          margin: EdgeInsets.only(left: 32),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(Icons.arrow_back),
                SizedBox(width: 10),
                Text('Pomodoros'),
              ],
            ),
          ),
        ),
        topPagePreviewWidget: Container(
          padding: EdgeInsets.all(8),
          margin: EdgeInsets.only(top: 32),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(120),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.store),
              SizedBox(height: 4),
              Text('Store'),
              SizedBox(height: 12),
              Icon(Icons.arrow_downward),
            ],
          ),
        ),
        rightPagePreviewWidget: CircleAvatar(
          backgroundColor: Colors.indigoAccent,
          child: Icon(Icons.settings),
        ),
      ),

      /// Initial wait duration before the first page is shown.
      /// All screens will seen for a wait duration before
      /// the first page (CenterPage) is shown.
      initialWaitDuration: const Duration(milliseconds: 500),

      /// Initial view scale of the center page.
      /// Defaults 1.0, no scaling. If initial view scale is set to 1.0,
      /// initialWaitDuration is unnecessary to use.
      initialViewScale: .5,

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
