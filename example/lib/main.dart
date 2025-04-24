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
    );
  }
}
