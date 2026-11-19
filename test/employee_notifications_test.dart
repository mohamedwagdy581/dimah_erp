import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/features/notifications/domain/models/notification_item.dart';
import 'package:erp_sys/features/notifications/view/widgets/employee_notifications_view.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const items = [
  NotificationItem(
    title: 'Review accepted',
    subtitle: 'Task report',
    icon: Icons.verified_outlined,
    color: Colors.green,
    category: 'reviews',
    route: '/task',
  ),
  NotificationItem(
    title: 'Due soon',
    subtitle: 'Prepare report',
    icon: Icons.schedule_outlined,
    color: Colors.orange,
    category: 'deadlines',
    route: '/task',
  ),
];
void main() {
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('Employee notifications $lang fits $width and filters', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var refreshed = false;
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                body: EmployeeNotificationsView(
                  items: items,
                  onRefresh: () => refreshed = true,
                ),
              ),
            ),
            GoRoute(
              path: '/task',
              builder: (_, _) => const Scaffold(body: Text('Task destination')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: appLocalizationDelegates,
            theme: EmployeeTheme.from(AppTheme.light()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip(lang == 'ar' ? 'تحديث' : 'Refresh'));
        expect(refreshed, isTrue);
        await tester.tap(
          find.text(lang == 'ar' ? 'المراجعات (1)' : 'Reviews (1)'),
        );
        await tester.pumpAndSettle();
        expect(find.text('Review accepted'), findsOneWidget);
        expect(find.text('Due soon'), findsNothing);
        await tester.enterText(find.byType(TextField), 'missing');
        await tester.pumpAndSettle();
        expect(
          find.text(
            lang == 'ar'
                ? 'لا توجد إشعارات مطابقة'
                : 'No matching notifications',
          ),
          findsOneWidget,
        );
        await tester.enterText(find.byType(TextField), 'report');
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(lang == 'ar' ? 'عرض التفاصيل' : 'View details'),
        );
        await tester.pumpAndSettle();
        expect(find.text('Task destination'), findsOneWidget);
      });
    }
  }
  testWidgets('Failure gives retry without empty-success message', (
    tester,
  ) async {
    var retry = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmployeeNotificationsView(
            items: const [],
            failed: true,
            onRefresh: () => retry = true,
          ),
        ),
      ),
    );
    expect(find.text('Unable to load data'), findsOneWidget);
    expect(find.text('No notifications yet'), findsNothing);
    await tester.ensureVisible(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    expect(retry, isTrue);
  });
}
