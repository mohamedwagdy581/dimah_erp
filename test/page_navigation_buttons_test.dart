import 'package:erp_sys/core/widgets/page_navigation_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final direction in [TextDirection.rtl, TextDirection.ltr]) {
    testWidgets('Right advances and left goes back in $direction', (
      tester,
    ) async {
      var page = 2;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: PageNavigationButtons(
                previousTooltip: 'Previous',
                nextTooltip: 'Next',
                center: const Text('October 2026'),
                onPrevious: () => page--,
                onNext: () => page++,
              ),
            ),
          ),
        ),
      );
      final previous = find.byTooltip('Previous');
      final next = find.byTooltip('Next');
      final monthX = tester.getCenter(find.text('October 2026')).dx;
      expect(monthX, greaterThan(tester.getCenter(previous).dx));
      expect(monthX, lessThan(tester.getCenter(next).dx));
      expect(
        tester.getCenter(next).dx,
        greaterThan(tester.getCenter(previous).dx),
      );
      await tester.tapAt(tester.getCenter(next));
      expect(page, 3);
      await tester.tapAt(tester.getCenter(previous));
      expect(page, 2);
      for (final icon in tester.widgetList<Icon>(find.byType(Icon))) {
        expect(icon.textDirection, TextDirection.ltr);
      }
    });
  }
}
