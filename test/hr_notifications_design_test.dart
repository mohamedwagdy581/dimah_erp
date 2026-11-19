import 'dart:io';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/notifications/domain/models/notification_item.dart';
import 'package:erp_sys/features/notifications/view/widgets/hr_notifications_view.dart';

final items = [
  NotificationItem(
    id: 'approval:one',
    title: 'يتطلب ردك على طلب',
    subtitle: 'يوجد طلب مراجعة بيانات موظف بانتظار ردك.',
    category: 'reviews',
    icon: Icons.fact_check_outlined,
    color: Colors.purple,
    occurredAt: DateTime(2026, 10, 25, 14, 30),
    route: '/approvals',
  ),
  NotificationItem(
    id: 'leave:two',
    title: 'طلب إجازة بانتظار الموافقة',
    subtitle: 'طلب إجازة سنوية يحتاج إلى المراجعة.',
    category: 'leave',
    icon: Icons.calendar_month_outlined,
    color: Colors.green,
    occurredAt: DateTime(2026, 10, 24, 9, 20),
  ),
  NotificationItem(
    id: 'payroll:three',
    title: 'تمت إعادة مسير الرواتب للمراجعة',
    subtitle: 'يرجى مراجعة الملاحظات وإعادة إرسال المسير.',
    category: 'payroll',
    icon: Icons.receipt_long_outlined,
    color: Colors.purple,
  ),
];
Widget app({
  String lang = 'ar',
  String scope = 'tenant:hr',
  bool failed = false,
  List<NotificationItem>? data,
  VoidCallback? refresh,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: appLocalizationDelegates,
  theme: EmployeeTheme.from(AppTheme.light()),
  home: Scaffold(
    body: HrNotificationsView(
      key: ValueKey(scope),
      items: data ?? items,
      scope: scope,
      failed: failed,
      onRefresh: refresh ?? () {},
    ),
  ),
);
Future<void> actions(WidgetTester tester) async {
  final scroll = tester.widget<SingleChildScrollView>(
    find.byKey(const ValueKey('hr-notifications-horizontal')),
  );
  scroll.controller!.jumpTo(scroll.controller!.position.maxScrollExtent);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets(
        'HR notifications $lang at $width exposes details and filters read items',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(app(lang: lang));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.text(lang == 'ar' ? 'غير مقروء (3)' : 'Unread (3)'),
            findsOneWidget,
          );
          await actions(tester);
          await tester.tap(
            find.byKey(const ValueKey('notification-details-approval:one')),
          );
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);
          await tester.tap(find.text(lang == 'ar' ? 'إغلاق' : 'Close'));
          await tester.pumpAndSettle();
          expect(
            find.text(lang == 'ar' ? 'غير مقروء (2)' : 'Unread (2)'),
            findsOneWidget,
          );
          await tester.tap(
            find.text(lang == 'ar' ? 'غير مقروء (2)' : 'Unread (2)'),
          );
          await tester.pumpAndSettle();
          expect(find.text(items.first.title), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('Read status survives remount and stays scoped to HR account', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await actions(tester);
    await tester.tap(
      find.byKey(const ValueKey('notification-details-approval:one')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('غير مقروء (2)'), findsOneWidget);
    await tester.pumpWidget(app(scope: 'tenant:another-hr'));
    await tester.pumpAndSettle();
    expect(find.text('غير مقروء (3)'), findsOneWidget);
  });
  testWidgets('Failure retries and empty notifications are usable', (
    tester,
  ) async {
    var refreshed = false;
    await tester.pumpWidget(app(failed: true, refresh: () => refreshed = true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إعادة المحاولة'));
    expect(refreshed, isTrue);
    await tester.pumpWidget(app(data: []));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد إشعارات حاليًا'), findsOneWidget);
  });
  testWidgets('Details link opens the real destination', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: HrNotificationsView(
              items: items,
              scope: 'tenant:hr',
              onRefresh: () {},
            ),
          ),
        ),
        GoRoute(
          path: '/approvals',
          builder: (_, _) =>
              const Scaffold(body: Text('Approvals destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationDelegates,
        theme: EmployeeTheme.from(AppTheme.light()),
      ),
    );
    await tester.pumpAndSettle();
    await actions(tester);
    await tester.tap(
      find.byKey(const ValueKey('notification-details-approval:one')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('الانتقال للشاشة'));
    await tester.pumpAndSettle();
    expect(find.text('Approvals destination'), findsOneWidget);
  });
  testWidgets('HR notifications visual preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_NOTIFICATIONS')) return;
    await tester.runAsync(() async {
      for (final font in {
        'Roboto': 'C:/Windows/Fonts/segoeui.ttf',
        'MaterialIcons':
            'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(font.key)..addFont(
              Future.value(
                ByteData.sublistView(await File(font.value).readAsBytes()),
              ),
            ))
            .load();
      }
    });
    await tester.binding.setSurfaceSize(const Size(1250, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: app()));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final picture =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/hr_notifications_preview.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  });
}
