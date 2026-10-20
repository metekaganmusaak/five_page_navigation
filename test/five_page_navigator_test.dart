import 'dart:async';

import 'package:five_page_navigation/five_page_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// The default test surface is 800x600.
const Offset _leftEdge = Offset(10, 300);
const Offset _rightEdge = Offset(790, 300);
const Offset _topEdge = Offset(400, 10);
const Offset _bottomEdge = Offset(400, 590);

class _Page extends StatelessWidget {
  const _Page(this.label, {this.withAppBar = false});

  final String label;
  final bool withAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: withAppBar ? AppBar(title: Text('$label bar')) : null,
      body: Center(child: Text(label)),
    );
  }
}

class _Counter extends StatefulWidget {
  const _Counter(this.label);

  final String label;

  static int initCount = 0;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _Counter.initCount++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => setState(() => _count++),
          child: Text('${widget.label} $_count'),
        ),
      ),
    );
  }
}

Widget _app({
  FivePageController? controller,
  FivePageTransition? transition,
  bool swipeBack = false,
  bool previews = false,
  bool returnButton = false,
  bool maintainState = false,
  bool autofocus = false,
  Widget center = const _Page('center'),
  Widget? left = const _Page('left'),
  Widget? right = const _Page('right'),
  Widget? top = const _Page('top'),
  Widget? bottom = const _Page('bottom'),
  ValueChanged<PageType>? onPageChanged,
  VoidCallback? onLeftPageOpened,
  VoidCallback? onReturnCenterPage,
}) {
  return MaterialApp(
    home: FivePageNavigator(
      controller: controller,
      transition: transition,
      centerPage: center,
      leftPage: left,
      rightPage: right,
      topPage: top,
      bottomPage: bottom,
      enableLeftPageSwipeBack: swipeBack,
      enableRightPageSwipeBack: swipeBack,
      enableTopPageSwipeBack: swipeBack,
      enableBottomPageSwipeBack: swipeBack,
      showSidePagePreviews: previews,
      showReturnToCenterButton: returnButton,
      maintainSidePageState: maintainState,
      autofocus: autofocus,
      onPageChanged: onPageChanged,
      onLeftPageOpened: onLeftPageOpened,
      onReturnCenterPage: onReturnCenterPage,
    ),
  );
}

void main() {
  testWidgets('only the center page is built initially', (tester) async {
    await tester.pumpWidget(_app());
    expect(find.text('center'), findsOneWidget);
    expect(find.text('left', skipOffstage: false), findsNothing);
    expect(find.text('right', skipOffstage: false), findsNothing);
  });

  group('swipes from the center page', () {
    final cases = <String, (Offset, Offset, String)>{
      'left': (_leftEdge, const Offset(400, 0), 'left'),
      'right': (_rightEdge, const Offset(-400, 0), 'right'),
      'top': (_topEdge, const Offset(0, 300), 'top'),
      'bottom': (_bottomEdge, const Offset(0, -300), 'bottom'),
    };
    for (final MapEntry(key: name, value: (start, offset, label))
        in cases.entries) {
      testWidgets('open the $name page', (tester) async {
        final changes = <PageType>[];
        await tester.pumpWidget(_app(onPageChanged: changes.add));
        await tester.dragFrom(start, offset);
        await tester.pumpAndSettle();
        expect(find.text(label), findsOneWidget);
        expect(find.text('center'), findsNothing);
        expect(changes, [PageType.values.byName(name)]);
      });
    }
  });

  testWidgets('a short drag snaps back to the center', (tester) async {
    await tester.pumpWidget(_app());
    final gesture = await tester.startGesture(_leftEdge);
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('center'), findsOneWidget);
    expect(find.text('left', skipOffstage: false), findsNothing);
  });

  testWidgets('a fast fling opens the page below the threshold',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.flingFrom(_leftEdge, const Offset(100, 0), 2000);
    await tester.pumpAndSettle();
    expect(find.text('left'), findsOneWidget);
  });

  testWidgets('drags outside the edge zones are ignored', (tester) async {
    await tester.pumpWidget(_app());
    await tester.dragFrom(const Offset(400, 300), const Offset(350, 0));
    await tester.pumpAndSettle();
    expect(find.text('center'), findsOneWidget);
  });

  testWidgets('drags in the wrong direction are ignored', (tester) async {
    await tester.pumpWidget(_app(left: null));
    await tester.dragFrom(_leftEdge, const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text('center'), findsOneWidget);
  });

  testWidgets('canSwipeFromCenter can block swipes', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: FivePageNavigator(
        centerPage: const _Page('center'),
        leftPage: const _Page('left'),
        canSwipeFromCenter: () => false,
      ),
    ));
    await tester.dragFrom(_leftEdge, const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text('center'), findsOneWidget);
  });

  testWidgets('edge swipes win against a scrollable center page',
      (tester) async {
    await tester.pumpWidget(_app(
      center: Scaffold(
        body: ListView.builder(
          itemCount: 100,
          itemBuilder: (_, i) => ListTile(title: Text('item $i')),
        ),
      ),
    ));
    // The middle of the list still scrolls.
    await tester.dragFrom(const Offset(400, 300), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('item 0'), findsNothing);
    // A swipe from the top edge opens the top page.
    await tester.dragFrom(_topEdge, const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('top'), findsOneWidget);
  });

  group('swipe back', () {
    testWidgets('returns to the center when enabled', (tester) async {
      final controller = FivePageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller: controller, swipeBack: true));
      await controller.navigateLeft(animate: false);
      await tester.pumpAndSettle();
      expect(find.text('left'), findsOneWidget);

      await tester.dragFrom(_rightEdge, const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('center'), findsOneWidget);
      expect(controller.currentPage, PageType.center);
    });

    testWidgets('is ignored when disabled', (tester) async {
      final controller = FivePageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller: controller));
      await controller.navigateLeft(animate: false);
      await tester.pumpAndSettle();
      await tester.dragFrom(_rightEdge, const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('left'), findsOneWidget);
    });
  });

  group('controller', () {
    testWidgets('navigates and notifies listeners', (tester) async {
      final controller = FivePageController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      await tester.pumpWidget(_app(controller: controller));
      expect(controller.isAttached, isTrue);

      final result = controller.navigateRight();
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      expect(controller.currentPage, PageType.right);
      expect(find.text('right'), findsOneWidget);
      expect(notifications, greaterThan(0));

      final back = controller.returnToCenter();
      await tester.pumpAndSettle();
      expect(await back, isTrue);
      expect(find.text('center'), findsOneWidget);
    });

    testWidgets('goes from one side page to another through the center',
        (tester) async {
      final controller = FivePageController();
      addTearDown(controller.dispose);
      final changes = <PageType>[];
      await tester.pumpWidget(
        _app(controller: controller, onPageChanged: changes.add),
      );
      await controller.navigateTop(animate: false);
      final result = controller.navigateBottom();
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      expect(changes, [PageType.top, PageType.center, PageType.bottom]);
    });

    testWidgets('ignores pages that are not configured', (tester) async {
      final controller = FivePageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller: controller, left: null));
      expect(controller.canNavigateTo(PageType.left), isFalse);
      expect(await controller.navigateLeft(), isFalse);
    });

    testWidgets('detaches when the navigator is disposed', (tester) async {
      final controller = FivePageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpWidget(const SizedBox());
      expect(controller.isAttached, isFalse);
      expect(await controller.navigateLeft(), isFalse);
    });
  });

  testWidgets('FivePageNavigator.of works from inside a page', (tester) async {
    await tester.pumpWidget(_app(
      center: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => FivePageNavigator.of(context).navigateTo(
              PageType.bottom,
            ),
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('bottom'), findsOneWidget);
  });

  group('back button', () {
    testWidgets('system back returns to the center', (tester) async {
      final controller = FivePageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller: controller));
      await controller.navigateLeft(animate: false);
      await tester.pumpAndSettle();

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(handled, isTrue);
      expect(find.text('center'), findsOneWidget);
      expect(controller.currentPage, PageType.center);
    });

    testWidgets('side page AppBar shows a back button that returns',
        (tester) async {
      final controller = FivePageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(
        controller: controller,
        center: const _Page('center', withAppBar: true),
        right: const _Page('right', withAppBar: true),
      ));
      expect(find.byType(BackButton), findsNothing);

      await controller.navigateRight(animate: false);
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('center'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);

      // The leaving page keeps its back button until it is off screen.
      await controller.navigateRight(animate: false);
      await tester.pumpAndSettle();
      unawaited(controller.returnToCenter());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(BackButton), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('Navigator.pop inside a side page returns to the center',
        (tester) async {
      final controller = FivePageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(
        controller: controller,
        top: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('pop'),
            ),
          ),
        ),
      ));
      await controller.navigateTop(animate: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('pop'));
      await tester.pumpAndSettle();
      expect(find.text('center'), findsOneWidget);
    });
  });

  group('state', () {
    testWidgets('the center page keeps its state', (tester) async {
      final controller = FivePageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(controller: controller, center: const _Counter('center')),
      );
      await tester.tap(find.text('center 0'));
      await tester.pump();
      await controller.navigateLeft(animate: false);
      await tester.pumpAndSettle();
      await controller.returnToCenter(animate: false);
      await tester.pumpAndSettle();
      expect(find.text('center 1'), findsOneWidget);
    });

    testWidgets('a side page is built once per visit', (tester) async {
      _Counter.initCount = 0;
      await tester.pumpWidget(_app(left: const _Counter('left')));
      final gesture = await tester.startGesture(_leftEdge);
      await gesture.moveBy(const Offset(30, 0));
      await gesture.moveBy(const Offset(300, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('left 0'), findsOneWidget);
      expect(_Counter.initCount, 1);
    });

    testWidgets('maintainSidePageState keeps side pages alive', (tester) async {
      final controller = FivePageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(
        controller: controller,
        maintainState: true,
        left: const _Counter('left'),
      ));
      await controller.navigateLeft(animate: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('left 0'));
      await controller.returnToCenter(animate: false);
      await tester.pumpAndSettle();
      expect(find.text('left 1', skipOffstage: false), findsOneWidget);
      await controller.navigateLeft(animate: false);
      await tester.pumpAndSettle();
      expect(find.text('left 1'), findsOneWidget);
    });

    testWidgets('side pages are disposed by default', (tester) async {
      final controller = FivePageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller: controller));
      await controller.navigateLeft(animate: false);
      await controller.returnToCenter(animate: false);
      await tester.pumpAndSettle();
      expect(find.text('left', skipOffstage: false), findsNothing);
    });

    testWidgets('removing the active page returns to the center',
        (tester) async {
      final controller = FivePageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller: controller));
      await controller.navigateLeft(animate: false);
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(controller: controller, left: null));
      await tester.pumpAndSettle();
      expect(find.text('center'), findsOneWidget);
      expect(controller.currentPage, PageType.center);
    });
  });

  testWidgets('pages with visible tooltips survive transitions',
      (tester) async {
    // Moving a page into its transition wrapper reparents it. That must
    // happen during build, not layout, or OverlayPortals (tooltips, menus)
    // inside the page break the framework.
    final controller = FivePageController();
    addTearDown(controller.dispose);
    final tooltips = [GlobalKey<TooltipState>(), GlobalKey<TooltipState>()];
    Widget pageWithTooltip(String label, GlobalKey<TooltipState> key) =>
        Scaffold(
          body: Center(
            child: Tooltip(key: key, message: 'tip', child: Text(label)),
          ),
        );
    await tester.pumpWidget(_app(
      controller: controller,
      center: pageWithTooltip('center', tooltips[0]),
      right: pageWithTooltip('right', tooltips[1]),
    ));
    tooltips[0].currentState!.ensureTooltipVisible();
    await tester.pumpAndSettle();
    unawaited(controller.navigateRight());
    await tester.pumpAndSettle();
    expect(find.text('right'), findsOneWidget);

    tooltips[1].currentState!.ensureTooltipVisible();
    await tester.pumpAndSettle();
    unawaited(controller.returnToCenter());
    await tester.pumpAndSettle();
    expect(find.text('center'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('return button', () {
    testWidgets('is shown on side pages and returns', (tester) async {
      final controller = FivePageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(controller: controller, returnButton: true),
      );
      await controller.navigateLeft(animate: false);
      await tester.pumpAndSettle();
      final button = find.byIcon(Icons.chevron_right_rounded);
      expect(button, findsOneWidget);
      // Placed on the edge facing the center page.
      expect(tester.getCenter(button).dx, greaterThan(700));

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('center'), findsOneWidget);
    });

    testWidgets('moves below the AppBar of the page', (tester) async {
      final controller = FivePageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(
        controller: controller,
        returnButton: true,
        bottom: const _Page('bottom', withAppBar: true),
        top: const _Page('top'),
      ));
      await controller.navigateBottom(animate: false);
      await tester.pumpAndSettle();
      final appBarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
      final buttonTop =
          tester.getTopLeft(find.byIcon(Icons.expand_less_rounded)).dy;
      expect(buttonTop, greaterThanOrEqualTo(appBarBottom));

      await controller.navigateTop(animate: false);
      await tester.pumpAndSettle();
      // Without an AppBar the button sits at the bottom edge.
      expect(
        tester.getCenter(find.byIcon(Icons.expand_more_rounded)).dy,
        greaterThan(500),
      );
    });
  });

  group('previews', () {
    testWidgets('show a chip while dragging and open on release',
        (tester) async {
      await tester.pumpWidget(_app(previews: true));
      final gesture = await tester.startGesture(_leftEdge);
      await gesture.moveBy(const Offset(30, 0));
      await gesture.moveBy(const Offset(200, 0));
      await tester.pump();
      expect(find.text('Left'), findsOneWidget);
      // The pages do not move while previewing.
      expect(find.text('left', skipOffstage: false), findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('left'), findsOneWidget);
      expect(find.text('Left'), findsNothing);
    });

    testWidgets('hide again when released early', (tester) async {
      await tester.pumpWidget(_app(previews: true));
      final gesture = await tester.startGesture(_leftEdge);
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Left'), findsNothing);
      expect(find.text('center'), findsOneWidget);
    });
  });

  testWidgets('keyboard shortcuts navigate', (tester) async {
    await tester.pumpWidget(_app(autofocus: true));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(find.text('top'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('center'), findsOneWidget);
  });

  testWidgets('reduced motion switches pages instantly', (tester) async {
    final controller = FivePageController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: _app(controller: controller),
    ));
    final result = controller.navigateLeft();
    await tester.pump();
    expect(await result, isTrue);
    expect(find.text('left'), findsOneWidget);
  });

  testWidgets('callbacks fire after transitions', (tester) async {
    var opened = 0;
    var returned = 0;
    final controller = FivePageController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(
      controller: controller,
      onLeftPageOpened: () => opened++,
      onReturnCenterPage: () => returned++,
    ));
    unawaited(controller.navigateLeft());
    await tester.pump(const Duration(milliseconds: 100));
    expect(opened, 0);
    await tester.pumpAndSettle();
    expect(opened, 1);
    unawaited(controller.returnToCenter());
    await tester.pumpAndSettle();
    expect(returned, 1);
  });

  group('transitions', () {
    const transitions = <String, FivePageTransition>{
      'slide': FivePageTransition.slide(incomingOpacityStart: 0.3),
      'parallax': FivePageTransition.parallax(),
      'cover': FivePageTransition.cover(),
      'depth': FivePageTransition.depth(),
      'reveal': FivePageTransition.reveal(),
      'fade': FivePageTransition.fade(),
      'fadeThrough': FivePageTransition.fadeThrough(),
      'sharedAxis': FivePageTransition.sharedAxis(),
      'zoom': FivePageTransition.zoom(),
      'scale': FivePageTransition.scale(),
      'cube': FivePageTransition.cube(),
      'flip': FivePageTransition.flip(),
      'rotate': FivePageTransition.rotate(),
      'none': FivePageTransition.none(),
    };

    for (final MapEntry(key: name, value: transition) in transitions.entries) {
      testWidgets('$name animates every page in and out', (tester) async {
        final controller = FivePageController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _app(controller: controller, transition: transition),
        );
        for (final page in [
          PageType.left,
          PageType.right,
          PageType.top,
          PageType.bottom,
        ]) {
          unawaited(controller.navigateTo(page));
          for (var i = 0; i < 4; i++) {
            await tester.pump(const Duration(milliseconds: 60));
          }
          await tester.pumpAndSettle();
          expect(find.text(page.name), findsOneWidget);
          unawaited(controller.returnToCenter());
          await tester.pumpAndSettle();
          expect(find.text('center'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('custom transitions receive the details', (tester) async {
      final seen = <FivePageTransitionDetails>[];
      final controller = FivePageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(
        controller: controller,
        transition: FivePageTransition.custom(
          incomingBuilder: (context, details, child) {
            seen.add(details);
            return Opacity(opacity: details.progress, child: child);
          },
          outgoingBuilder: (context, details, child) => child,
        ),
      ));
      unawaited(controller.navigateTop());
      await tester.pumpAndSettle();
      expect(seen, isNotEmpty);
      expect(seen.first.from, PageType.center);
      expect(seen.first.to, PageType.top);
      expect(seen.first.direction, SwipeDirection.down);
      expect(seen.last.progress, 1.0);
    });
  });
}
