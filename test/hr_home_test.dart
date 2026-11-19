import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/core/routing/app_routes.dart';
import 'package:erp_sys/features/hr_home/hr_home_repo.dart';
import 'package:erp_sys/features/hr_home/hr_home_page.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const data = HrHomeData(
  name: 'خالد',
  employees: 86,
  newEmployees: 5,
  attendanceIssues: 8,
  documents: [
    {
      'doc_type': 'id_card',
      'expires_at': '2026-10-08',
      'employee': {'full_name': 'موظف اختبار'},
    },
  ],
  leaves: [
    {
      'payload': {
        'leave_type': 'annual',
        'start_date': '2026-10-12',
        'end_date': '2026-10-16',
      },
      'employee': {'full_name': 'سارة أحمد'},
      'current_approver_role': 'hr',
    },
  ],
);

void main() {
  testWidgets('Export HR preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_HR_PREVIEW')) return;
    await tester.runAsync(() async {
      for (final entry in {
        'Roboto': 'C:/Windows/Fonts/segoeui.ttf',
        'MaterialIcons':
            'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(entry.key)..addFont(
              Future.value(
                ByteData.sublistView(await File(entry.value).readAsBytes()),
              ),
            ))
            .load();
      }
    });
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationDelegates,
        theme: EmployeeTheme.from(AppTheme.light()),
        home: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: HrHomeView(
              data: data,
              onRefresh: () {},
              now: DateTime(2026, 10, 6),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/hr_home_preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('HR home $lang fits $width and opens payroll', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                body: HrHomeView(
                  data: data,
                  onRefresh: () {},
                  now: DateTime(2026, 10, 6),
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.payroll,
              builder: (_, _) =>
                  const Scaffold(body: Text('Payroll destination')),
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
        expect(find.text('2026/10/08'), findsOneWidget);
        expect(find.text('سارة أحمد'), findsOneWidget);
        final button = find.text(
          lang == 'ar' ? 'بدء التجهيز' : 'Start preparation',
        );
        await tester.scrollUntilVisible(
          button,
          500,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.text('Payroll destination'), findsOneWidget);
      });
    }
  }
}
