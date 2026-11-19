import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/features/manager_requests/data/manager_requests_repo.dart';
import 'package:erp_sys/features/manager_requests/view/manager_requests_cubit.dart';
import 'package:erp_sys/features/manager_requests/view/manager_requests_page.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';

Map<String, dynamic> request(
  String id,
  String type, {
  String status = 'pending',
  String approver = 'manager',
  String name = 'موظف اختبار',
}) => {
  'id': id,
  'tenant_id': 'tenant',
  'employee_id': 'e1',
  'employee': {'full_name': name},
  'job_title': 'أخصائي تسويق',
  'request_type': type,
  'status': status,
  'current_approver_role': approver,
  'created_at': '2026-10-05T07:00:00Z',
  'payload': type == 'leave'
      ? {
          'type': 'annual',
          'start_date': '2026-10-20',
          'end_date': '2026-10-24',
          'notes': 'طلب إجازة عائلية',
        }
      : {
          'date': '2026-10-05',
          'proposed_check_in': '2026-10-05T07:00:00Z',
          'reason': 'تصحيح البصمة',
        },
};

class FakeRequestsRepo implements ManagerRequestsRepo {
  List<Map<String, dynamic>> rows = [
    request('leave-1', 'leave'),
    request('attendance-1', 'attendance_correction', name: 'موظف آخر'),
  ];
  int decisions = 0;
  String? reason;
  bool fail = false;
  bool failRefresh = false;
  bool failLoad = false;
  Completer<void>? pending;
  @override
  Future<ManagerRequestsData> load() async {
    if (failLoad) throw StateError('fixture refresh failure');
    return ManagerRequestsData(rows: rows);
  }

  @override
  Future<void> decide(String id, bool approve, String note) async {
    decisions++;
    reason = note;
    if (pending != null) await pending!.future;
    if (fail) throw StateError('fixture failure');
    if (failRefresh) failLoad = true;
    rows = rows
        .map(
          (r) => r['id'] == id
              ? {
                  ...r,
                  'status': approve ? 'pending' : 'rejected',
                  'current_approver_role': approve ? 'hr' : null,
                  'reject_reason': approve ? null : note,
                }
              : r,
        )
        .toList();
  }
}

void main() {
  Future<ManagerRequestsCubit> pump(
    WidgetTester tester,
    FakeRequestsRepo repo,
    double width,
    String lang, {
    GlobalKey? capture,
  }) async {
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = ManagerRequestsCubit(repo);
    await cubit.load();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(lang),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationDelegates,
        theme: EmployeeTheme.from(AppTheme.light()),
        home: RepaintBoundary(
          key: capture,
          child: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const ManagerRequestsView(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  test('Only pending assigned leave/correction requests can be decided', () {
    final row = request('r', 'leave');
    expect(managerCanDecideRequest(row, 'manager'), true);
    expect(managerCanDecideRequest(row, 'direct_manager'), true);
    expect(
      managerCanDecideRequest({
        ...row,
        'current_approver_role': 'hr',
      }, 'manager'),
      false,
    );
    expect(
      managerCanDecideRequest({...row, 'status': 'rejected'}, 'manager'),
      false,
    );
    expect(
      managerCanDecideRequest({
        ...row,
        'request_type': 'payroll_run',
      }, 'manager'),
      false,
    );
    expect(managerCanDecideRequest(row, 'employee'), false);
  });
  for (final language in ['ar', 'en']) {
    testWidgets('Manager sees sick-leave attachment action in $language', (
      tester,
    ) async {
      final row = request('sick', 'leave');
      final repo = FakeRequestsRepo()
        ..rows = [
          {
            ...row,
            'payload': {
              ...(row['payload'] as Map),
              'type': 'sick',
              'file_url': 'https://example.test/medical-report.pdf',
              'file_name': 'medical-report.pdf',
            },
          },
        ];
      await pump(tester, repo, 320, language);
      expect(
        find.byKey(const ValueKey('team-request-attachment')),
        findsOneWidget,
      );
      expect(find.text('medical-report.pdf'), findsOneWidget);
      expect(
        find.text(language == 'ar' ? 'عرض المرفق' : 'Open attachment'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('Team requests fit $lang $width', (tester) async {
        await pump(tester, FakeRequestsRepo(), width, lang);
        expect(tester.takeException(), isNull);
        expect(find.text('أخصائي تسويق'), findsOneWidget);
        final correction = find.byKey(
          const ValueKey('team-request-attendance-1'),
        );
        await tester.ensureVisible(correction);
        await tester.tap(correction);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.text(lang == 'ar' ? 'الحضور المقترح' : 'Proposed check-in'),
          findsOneWidget,
        );
        expect(
          find.text(lang == 'ar' ? 'الانصراف المقترح' : 'Proposed check-out'),
          findsOneWidget,
        );
      });
    }
  }
  testWidgets('Search and type filter change selected details', (tester) async {
    await pump(tester, FakeRequestsRepo(), 1440, 'ar');
    await tester.enterText(
      find.widgetWithText(TextField, 'ابحث في الطلبات…'),
      'موظف آخر',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('team-request-leave-1')), findsNothing);
    expect(
      find.byKey(const ValueKey('team-request-attendance-1')),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'ابحث في الطلبات…'),
      '',
    );
    await tester.tap(find.text('إجازات'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('team-request-attendance-1')),
      findsNothing,
    );
  });
  testWidgets(
    'Reject requires reason, failure retains it, selection clears it',
    (tester) async {
      final repo = FakeRequestsRepo()..fail = true;
      await pump(tester, repo, 1440, 'ar');
      final reject = find.byKey(const ValueKey('team-request-reject'));
      await tester.ensureVisible(reject);
      await tester.tap(reject);
      await tester.pumpAndSettle();
      expect(repo.decisions, 0);
      expect(find.text('اكتب سبب الرفض أولًا'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('team-rejection-reason')),
        'غير مناسب',
      );
      await tester.ensureVisible(reject);
      await tester.tap(reject);
      await tester.pumpAndSettle();
      expect(repo.reason, 'غير مناسب');
      expect(find.text('غير مناسب'), findsOneWidget);
      expect(
        find.text('تعذر حفظ القرار. حدّث الطلبات ثم حاول مرة أخرى.'),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('team-request-attendance-1')),
      );
      await tester.tap(find.byKey(const ValueKey('team-request-attendance-1')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('team-rejection-reason')),
            )
            .controller!
            .text,
        isEmpty,
      );
    },
  );
  testWidgets(
    'Approval moves request to HR and prevents another manager decision',
    (tester) async {
      final repo = FakeRequestsRepo();
      await pump(tester, repo, 1440, 'ar');
      final approve = find.byKey(const ValueKey('team-request-approve'));
      await tester.ensureVisible(approve);
      await tester.tap(approve);
      await tester.pumpAndSettle();
      expect(repo.decisions, 1);
      expect(find.byKey(const ValueKey('team-request-approve')), findsNothing);
      expect(find.text('بانتظار الموارد البشرية'), findsOneWidget);
    },
  );
  test(
    'Saving is serialized and a failed refresh cannot resubmit a saved decision',
    () async {
      final repo = FakeRequestsRepo()
        ..pending = Completer<void>()
        ..failRefresh = true;
      final cubit = ManagerRequestsCubit(repo);
      await cubit.load();
      final saved = cubit.decide('leave-1', true, '');
      expect(cubit.state.saving, true);
      expect(await cubit.decide('leave-1', true, ''), false);
      repo.pending!.complete();
      expect(await saved, true);
      expect(repo.decisions, 1);
      expect(cubit.state.failed, true);
      expect(await cubit.decide('leave-1', true, ''), false);
      expect(repo.decisions, 1);
      await cubit.close();
    },
  );
  testWidgets('Export team requests preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_REQUESTS_PREVIEW')) return;
    await tester.runAsync(() async {
      for (final entry in {
        'Roboto': 'C:/Windows/Fonts/segoeui.ttf',
        'MaterialIcons':
            'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      }.entries) {
        final loader = FontLoader(entry.key)
          ..addFont(
            Future.value(
              ByteData.sublistView(await File(entry.value).readAsBytes()),
            ),
          );
        await loader.load();
      }
    });
    final key = GlobalKey();
    await pump(tester, FakeRequestsRepo(), 1440, 'ar', capture: key);
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final picture = await boundary.toImage();
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/manager_requests_preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  });
}
