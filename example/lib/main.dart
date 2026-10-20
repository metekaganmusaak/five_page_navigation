import 'package:five_page_navigation/five_page_navigation.dart';
import 'package:flutter/material.dart';

import 'demo_settings.dart';
import 'pages/discover_page.dart';
import 'pages/home_page.dart';
import 'pages/messages_page.dart';
import 'pages/notifications_page.dart';
import 'pages/profile_page.dart';

void main() => runApp(const FivePageExampleApp());

class FivePageExampleApp extends StatelessWidget {
  const FivePageExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Five Page Navigation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const ShowcasePage(),
    );
  }
}

class ShowcasePage extends StatefulWidget {
  const ShowcasePage({super.key});

  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage> {
  final FivePageController _controller = FivePageController();
  DemoSettings _settings = const DemoSettings();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swipeBack = _settings.swipeBack;
    return FivePageNavigator(
      controller: _controller,
      transition: demoTransitions[_settings.transition],
      backgroundColor: Colors.black,
      // The center page has an AppBar, so the top zone covers it.
      verticalDetectionAreaHeight: 140,
      horizontalDetectionAreaWidth: 60,
      enableLeftPageSwipeBack: swipeBack,
      enableRightPageSwipeBack: swipeBack,
      enableTopPageSwipeBack: swipeBack,
      enableBottomPageSwipeBack: swipeBack,
      swipeBackDetectionAreaFraction: 0.3,
      thresholdFeedback: _settings.haptics
          ? ThresholdVibration.medium
          : ThresholdVibration.none,
      showSidePagePreviews: _settings.previews,
      pagePreviewStyle: const PagePreviewStyle(
        leftPageLabel: 'Profile',
        rightPageLabel: 'Messages',
        topPageLabel: 'Notifications',
        bottomPageLabel: 'Discover',
      ),
      showReturnToCenterButton: _settings.returnButtons,
      returnButtonStyle: const ReturnButtonStyle(
        tooltip: 'Back to home',
        elevation: 2,
      ),
      animateCenterPageEntranceOpacity: true,
      centerPageEntranceAnimationDuration: const Duration(milliseconds: 600),
      autofocus: isDesktopOrWeb,
      onPageChanged: (page) => debugPrint('Page changed: ${page.name}'),
      centerPage: HomePage(
        controller: _controller,
        settings: _settings,
        onSettingsChanged: (settings) => setState(() => _settings = settings),
      ),
      // No AppBar: the return button only avoids the safe area.
      leftPage: const ProfilePage(),
      // AppBar: its automatic back button returns to the center page.
      rightPage: const MessagesPage(),
      // Long list: swipe up from its lower part to go back.
      topPage: const NotificationsPage(),
      // AppBar + bottom bar: the return button is placed below the AppBar.
      bottomPage: const DiscoverPage(),
    );
  }
}
