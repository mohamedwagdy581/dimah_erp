import 'dart:io';
import 'dart:ui' as ui;
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/core/widgets/app_scaffold.dart';
import 'package:erp_sys/features/approvals/domain/models/approval_request.dart';
import 'package:erp_sys/features/approvals/domain/repos/approvals_repo.dart';
import 'package:erp_sys/features/employee_portal/view/cubit/employee_request_history_cubit.dart';
import 'package:erp_sys/features/employee_portal/view/widgets/employee_requests/employee_request_history_view.dart';
import 'package:erp_sys/features/employee_portal/view/widgets/employee_requests/request_history_labels.dart';
import 'package:erp_sys/features/shell/view/sections/sidebar_section.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

ApprovalRequest fixture(int index) => ApprovalRequest(
  id: 'actual-$index',
  tenantId: 'tenant',
  requestType: index == 2 ? 'attendance_correction' : 'leave',
  employeeId: 'employee',
  employeeName: '',
  status: index == 0
      ? 'rejected'
      : index == 1
      ? 'approved'
      : 'pending',
  createdAt: DateTime(2026, 10, 4, 10, index),
  rejectReason: index == 0 ? 'تعارض الموعد مع جدول العمل' : null,
  currentApproverRole: 'manager',
  payload: index == 2
      ? {
          'date': '2026-10-03',
          'proposed_check_in': '2026-10-03T08:15:00',
          'proposed_check_out': '2026-10-03T16:30:00',
          'reason': 'تصحيح وقت تسجيل الحضور',
        }
      : {
          'leave_id': 'leave-$index',
          'type': 'annual',
          'start_date': '2026-10-10',
          'end_date': '2026-10-12',
          'notes': 'متابعة موعد شخصي unique-$index',
          'file_url': 'https://example.test/file-$index.pdf',
        },
);

class _Repo extends Fake implements ApprovalsRepo {
  _Repo({this.count = 3});
  final int count;
  bool fails = false;
  final pages = <int>[];
  final employees = <String?>[];
  @override
  Future<({List<ApprovalRequest> items, int total})> fetchApprovals({
    required int page,
    required int pageSize,
    String? status,
    String? requestType,
    String? employeeId,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    pages.add(page);
    employees.add(employeeId);
    if (fails) throw StateError('Load failed');
    final end = ((page + 1) * pageSize).clamp(0, count);
    final start = (page * pageSize).clamp(0, count);
    return (
      items: [for (var i = start; i < end; i++) fixture(i)],
      total: end - start,
    );
  }
}

Widget _view({
  Future<void> Function(ApprovalRequest)? onResubmit,
  ValueChanged<String>? onAttachment,
}) => EmployeeRequestHistoryView(
  onLeave: () {},
  onAttendance: () {},
  onResubmit: onResubmit ?? (_) async {},
  onAttachment: onAttachment ?? (_) {},
);
Widget _app(
  EmployeeRequestHistoryCubit cubit, {
  String language = 'ar',
  double scale = 1,
  Widget? child,
}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  theme: EmployeeTheme.from(AppTheme.light()),
  home: Scaffold(
    body: BlocProvider.value(
      value: cubit,
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? _view(),
        ),
      ),
    ),
  ),
);

void main() {
  test(
    'History loads beyond first page despite page-only total, scoped to employee',
    () async {
      final repo = _Repo(count: 101);
      final cubit = EmployeeRequestHistoryCubit(repo, employeeId: 'employee');
      addTearDown(cubit.close);
      await cubit.load();
      expect(repo.pages, [0, 1]);
      expect(repo.employees, everyElement('employee'));
      expect(cubit.state.items.length, 101);
    },
  );
  test(
    'Only rejected leave with stored identity and dates is resubmittable',
    () {
      expect(historyResubmittableLeave(fixture(0))!.id, 'leave-0');
      expect(historyResubmittableLeave(fixture(1)), isNull);
      expect(historyResubmittableLeave(fixture(2)), isNull);
      expect(historyPeriod(fixture(2)), contains('08:15'));
      expect(historyPeriod(fixture(2)), contains('16:30'));
    },
  );
  for (final width in [320.0, 768.0, 1024.0, 1440.0]) {
    for (final language in ['ar', 'en']) {
      testWidgets('History $width $language has no overflow', (tester) async {
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final cubit = EmployeeRequestHistoryCubit(
          _Repo(),
          employeeId: 'employee',
        );
        addTearDown(cubit.close);
        await cubit.load();
        await tester.pumpWidget(_app(cubit, language: language));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('history-details-actual-0')),
          findsOneWidget,
        );
        expect(find.textContaining('LE-20261005'), findsNothing);
      });
    }
  }
  for (final language in ['ar', 'en']) {
    testWidgets('Phone history with large text $language has no overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 2500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cubit = EmployeeRequestHistoryCubit(
        _Repo(),
        employeeId: 'employee',
      );
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpWidget(_app(cubit, language: language, scale: 1.5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'Search finds requests beyond page one and reset restores first page',
    (tester) async {
      final cubit = EmployeeRequestHistoryCubit(
        _Repo(count: 101),
        employeeId: 'employee',
      );
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpWidget(_app(cubit, language: 'en'));
      await tester.enterText(
        find.byKey(const ValueKey('request-history-search')),
        'unique-100',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('history-details-actual-100')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('history-details-actual-0')),
        findsNothing,
      );
      await tester.ensureVisible(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('history-details-actual-0')),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'Selected request controls rejection details and existing resubmit action',
    (tester) async {
      final cubit = EmployeeRequestHistoryCubit(
        _Repo(),
        employeeId: 'employee',
      );
      addTearDown(cubit.close);
      await cubit.load();
      String? resubmitted;
      await tester.pumpWidget(
        _app(cubit, child: _view(onResubmit: (r) async => resubmitted = r.id)),
      );
      final resubmit = find.byKey(const ValueKey('request-resubmit-actual-0'));
      await tester.ensureVisible(resubmit);
      await tester.pumpAndSettle();
      await tester.tap(resubmit);
      await tester.pumpAndSettle();
      expect(resubmitted, 'actual-0');
      final approved = find.byKey(const ValueKey('history-details-actual-1'));
      await tester.ensureVisible(approved);
      await tester.pumpAndSettle();
      await tester.tap(approved);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('request-resubmit-actual-0')),
        findsNothing,
      );
      expect(find.text('تعارض الموعد مع جدول العمل'), findsNothing);
    },
  );
  testWidgets('History failure offers retry without zero-data claim', (
    tester,
  ) async {
    final repo = _Repo()..fails = true;
    final cubit = EmployeeRequestHistoryCubit(repo, employeeId: 'employee');
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(_app(cubit, language: 'en'));
    expect(find.text('Unable to load data'), findsOneWidget);
    repo.fails = false;
    await tester.ensureVisible(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('history-details-actual-0')),
      findsOneWidget,
    );
  });
  testWidgets('Type and status combine, then reset restores the history', (
    tester,
  ) async {
    final cubit = EmployeeRequestHistoryCubit(_Repo(), employeeId: 'employee');
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(_app(cubit, language: 'en'));
    final type = find.byKey(const ValueKey('history-type-all'));
    await tester.ensureVisible(type);
    await tester.pumpAndSettle();
    await tester.tap(type);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Attendance correction').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('history-details-actual-0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('history-details-actual-2')),
      findsOneWidget,
    );
    final status = find.byKey(const ValueKey('history-status-all'));
    final rejected = AppLocalizations.of(
      tester.element(find.byType(EmployeeRequestHistoryView)),
    )!.statusRejected;
    await tester.ensureVisible(status);
    await tester.pumpAndSettle();
    await tester.tap(status);
    await tester.pumpAndSettle();
    await tester.tap(find.text(rejected).last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('history-details-actual-2')),
      findsNothing,
    );
    expect(find.text('No matching results'), findsOneWidget);
    await tester.ensureVisible(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('history-details-actual-0')),
      findsOneWidget,
    );
  });
  testWidgets('Desktop history preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_HISTORY_PREVIEW')) return;
    await tester.runAsync(() async {
      for (final entry in {
        'Roboto': 'C:/Windows/Fonts/segoeui.ttf',
        'serif': 'C:/Windows/Fonts/times.ttf',
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
    tester.view.physicalSize = const Size(1536, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = EmployeeRequestHistoryCubit(
      _Repo(count: 5),
      employeeId: 'employee',
    );
    addTearDown(cubit.close);
    await cubit.load();
    final key = GlobalKey();
    final router = GoRouter(
      initialLocation: '/my?tab=requests',
      routes: [
        GoRoute(
          path: '/my',
          builder: (context, state) => RepaintBoundary(
            key: key,
            child: AppScaffold(
              title: AppLocalizations.of(context)!.myRequests,
              employeeStyle: true,
              isCollapsed: false,
              onToggle: () {},
              sidebar: SidebarSection(
                isCollapsed: false,
                onToggle: () {},
                role: 'employee',
                email: 'fixture@example.test',
              ),
              body: BlocProvider.value(value: cubit, child: _view()),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: EmployeeTheme.from(AppTheme.light()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final preview = await boundary.toImage();
      final bytes = await preview.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/employee_request_history_preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      preview.dispose();
    });
  });
}
