import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the D-pad opens every side page and returns', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FivePageExampleApp());
    await tester.pumpAndSettle();
    expect(find.text('Five Page Navigation'), findsOneWidget);

    const pages = {
      'Profile': 'Profile',
      'Messages': 'Messages',
      'Notifications': 'Notifications',
      'Discover': 'Discover',
    };
    for (final MapEntry(key: tooltip, value: title) in pages.entries) {
      await tester.tap(find.byTooltip(tooltip));
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets);

      await tester.tap(find.byTooltip('Back to home'));
      await tester.pumpAndSettle();
      expect(find.text('Five Page Navigation'), findsOneWidget);
    }
  });

  testWidgets('the transition picker changes the transition', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FivePageExampleApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Cube'), 100);
    await tester.tap(find.text('Cube'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Cube'))
          .selected,
      isTrue,
    );
  });
}
