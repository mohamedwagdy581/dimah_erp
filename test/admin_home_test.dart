import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/features/admin_home/admin_home_page.dart';
import 'package:erp_sys/features/admin_home/admin_home_repo.dart';
import 'package:erp_sys/features/payroll/domain/models/payroll_run.dart';

class AdminFixture implements AdminHomeRepo {
  bool fail = false, usersFail = false, empty = false;
  @override
  Future<AdminHomeData> load(DateTime month) async {
    if (fail) throw StateError('SocketException');
    return AdminHomeData(
      name: 'مدير النظام',
      month: month,
      employees: AdminSection.value(
        empty
            ? []
            : [
                {
                  'id': 'employee',
                  'full_name': 'Mohamed Mahrous Allam',
                  'status': 'active',
                  'department_id': 'finance',
                },
                {
                  'id': 'old',
                  'full_name': 'موظف سابق',
                  'status': 'inactive',
                  'department_id': 'finance',
                },
              ],
      ),
      departments: const AdminSection.value([
        {'id': 'finance', 'name': 'المالية والمحاسبة'},
      ]),
      approvals: AdminSection.value(
        empty
            ? []
            : [
                {
                  'id': 'leave',
                  'request_type': 'leave',
                  'employee_id': 'employee',
                  'created_at': '2026-10-08T12:00:00Z',
                },
                {
                  'id': 'payroll',
                  'request_type': 'payroll_run',
                  'employee_id': 'employee',
                  'created_at': '2026-10-08T12:00:00Z',
                },
              ],
      ),
      payroll: AdminSection.value(
        empty
            ? []
            : [
                for (final status in [
                  'pending_admin_approval',
                  'draft',
                  'approved',
                ])
                  PayrollRun(
                    id: status,
                    tenantId: 'tenant',
                    periodStart: DateTime(2026, 10),
                    periodEnd: DateTime(2026, 10, 31),
                    status: status,
                    totalEmployees: 12,
                    totalAmount: 67200,
                    createdAt: DateTime(2026, 10),
                  ),
              ],
      ),
      journal: AdminSection.value(
        empty
            ? []
            : [
                {'id': 'journal', 'status': 'draft'},
              ],
      ),
      users: usersFail
          ? const AdminSection.failure('SocketException')
          : AdminSection.value(
              empty
                  ? []
                  : [
                      {'id': 'admin', 'is_active': true},
                      {'id': 'disabled', 'is_active': false},
                    ],
            ),
    );
  }
}

Future<void> mount(
  WidgetTester tester,
  Widget child,
  double width,
  String language,
) async {
  tester.view.physicalSize = Size(width, 1050);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      ),
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('Admin dashboard responsive $language $width', (
        tester,
      ) async {
        await mount(
          tester,
          AdminHomePage(
            repo: AdminFixture(),
            now: DateTime(2026, 10),
            onOpen: (_) {},
          ),
          width,
          language,
        );
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -2400),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'Only management-pending payroll opens exact run; no dashboard approval mutation',
    (tester) async {
      final opened = <String>[];
      await mount(
        tester,
        AdminHomePage(repo: AdminFixture(), onOpen: opened.add),
        1440,
        'ar',
      );
      expect(find.byKey(const ValueKey('admin-open-run-draft')), findsNothing);
      expect(
        find.byKey(const ValueKey('admin-open-run-approved')),
        findsNothing,
      );
      final target = find.byKey(
        const ValueKey('admin-open-run-pending_admin_approval'),
      );
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(opened, ['/payroll/pending_admin_approval']);
    },
  );
  testWidgets(
    'User read error stays unavailable, other sections still show; refresh recovers',
    (tester) async {
      final fixture = AdminFixture()..usersFail = true;
      await mount(
        tester,
        AdminHomePage(repo: fixture, onOpen: (_) {}),
        1440,
        'ar',
      );
      expect(find.text('تعذر التحميل'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('admin-open-run-pending_admin_approval')),
        findsOneWidget,
      );
      fixture.usersFail = false;
      await tester.tap(find.byKey(const Key('admin-home-refresh')));
      await tester.pumpAndSettle();
      expect(find.text('تعذر التحميل'), findsNothing);
    },
  );
  testWidgets('Whole load failure has retry; empty dashboard remains useful', (
    tester,
  ) async {
    final fixture = AdminFixture()
      ..fail = true
      ..empty = true;
    await mount(
      tester,
      AdminHomePage(repo: fixture, onOpen: (_) {}),
      768,
      'en',
    );
    fixture.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      find.text('No payroll currently awaits your approval.'),
      findsOneWidget,
    );
    expect(find.text('Open approvals'), findsOneWidget);
  });
  test(
    'Payroll approvals excluded from non-payroll request count and inactive staff excluded',
    () async {
      final data = await AdminFixture().load(DateTime(2026, 10));
      expect(data.otherApprovals.length, 1);
      expect(data.activeEmployees, 1);
      expect(data.awaitingApproval.length, 1);
    },
  );
  if (const bool.fromEnvironment('EXPORT_ADMIN_HOME')) {
    testWidgets('Export admin dashboard', (tester) async {
      await tester.runAsync(() async {
        for (final entry in {
          'Roboto': 'assets/fonts/DINNextLTArabic-Regular-2.ttf',
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
      final key = GlobalKey();
      await mount(
        tester,
        RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFFF8F7FB),
            child: AdminHomePage(
              repo: AdminFixture(),
              now: DateTime(2026, 10),
              onOpen: (_) {},
            ),
          ),
        ),
        1440,
        'ar',
      );
      await tester.runAsync(() async {
        final picture =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/admin_home_preview.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
    });
  }
}
