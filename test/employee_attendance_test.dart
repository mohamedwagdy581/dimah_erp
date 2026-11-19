import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/core/widgets/app_scaffold.dart';
import 'package:erp_sys/features/attendance/domain/models/attendance_record.dart';
import 'package:erp_sys/features/attendance/domain/repos/employee_attendance_repo.dart';
import 'package:erp_sys/features/employee_portal/view/cubit/employee_attendance_cubit.dart';
import 'package:erp_sys/features/employee_portal/view/widgets/employee_attendance_view.dart';
import 'package:erp_sys/features/shell/view/sections/sidebar_section.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

AttendanceRecord record(
  int day, {
  String employee = 'employee',
  String status = 'present',
  bool missingOut = false,
  int month = 10,
}) => AttendanceRecord(
  id: 'record-$month-$day',
  tenantId: 'tenant',
  employeeId: employee,
  employeeName: '',
  date: DateTime(2026, month, day),
  status: status,
  checkIn: DateTime(2026, month, day, 8),
  checkOut: missingOut ? null : DateTime(2026, month, day, 16, 30),
  notes: 'note-$day',
  createdAt: DateTime(2026, month, day),
);

class Repo implements EmployeeAttendanceRepo {
  List<AttendanceRecord> records = [
    record(5, missingOut: true),
    record(4, status: 'late'),
    record(3),
  ];
  Set<String> pending = {};
  bool fail = false, ready = true;
  int saves = 0;
  String? reason, employee;
  DateTime? month;
  Completer<EmployeeAttendanceMonth>? loadGate;
  Completer<void>? saveGate;
  @override
  Future<EmployeeAttendanceMonth> fetchMonth({
    required String employeeId,
    required DateTime month,
  }) async {
    employee = employeeId;
    this.month = month;
    if (loadGate != null) return loadGate!.future;
    if (fail) throw StateError('Unavailable');
    return EmployeeAttendanceMonth(
      records: records,
      pendingRecordIds: pending,
      correctionsReady: ready,
    );
  }

  @override
  Future<void> requestCorrection({
    required AttendanceRecord record,
    required DateTime checkIn,
    required DateTime checkOut,
    required String reason,
  }) async {
    saves++;
    this.reason = reason;
    await saveGate?.future;
    if (fail) throw StateError('Unavailable');
  }
}

EmployeeAttendanceCubit cubit(Repo repo) => EmployeeAttendanceCubit(
  repo,
  employeeId: 'employee',
  now: DateTime(2026, 10, 5),
);
Widget view() =>
    EmployeeAttendanceView(now: DateTime(2026, 10, 5), onRequests: () {});
Widget app(
  EmployeeAttendanceCubit cubit, {
  String language = 'ar',
  double scale = 1,
}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: appLocalizationDelegates,
  theme: EmployeeTheme.from(AppTheme.light()),
  home: Scaffold(
    body: BlocProvider.value(
      value: cubit,
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: view(),
        ),
      ),
    ),
  ),
);

void main() {
  test(
    'Unchanged UTC times are rejected when proposed in local time',
    () async {
      final utc = AttendanceRecord(
        id: 'utc',
        tenantId: 'tenant',
        employeeId: 'employee',
        employeeName: '',
        date: DateTime(2026, 10, 5),
        status: 'present',
        checkIn: DateTime.utc(2026, 10, 5, 5),
        checkOut: DateTime.utc(2026, 10, 5, 13),
        createdAt: DateTime(2026),
      );
      final repo = Repo()..records = [utc];
      final controller = cubit(repo);
      addTearDown(controller.close);
      await controller.load();
      await expectLater(
        controller.requestCorrection(
          record: utc,
          checkIn: utc.checkIn!.toLocal(),
          checkOut: utc.checkOut!.toLocal(),
          reason: 'No time change',
        ),
        throwsArgumentError,
      );
      expect(repo.saves, 0);
    },
  );
  test('Overlapping records do not inflate attendance duration', () {
    final base = record(3);
    final extra = AttendanceRecord(
      id: 'duplicate-time',
      tenantId: base.tenantId,
      employeeId: base.employeeId,
      employeeName: '',
      date: base.date,
      status: base.status,
      checkIn: base.checkIn,
      checkOut: base.checkOut!.add(const Duration(hours: 1)),
      createdAt: base.createdAt,
    );
    final state = EmployeeAttendanceState(
      month: DateTime(2026, 10),
      records: [base, extra],
    );
    expect(state.recordedDays, 1);
    expect(state.recordedDuration, const Duration(hours: 9, minutes: 30));
  });
  test('Duration preserves overnight and missing or invalid times', () {
    expect(
      recordedAttendanceDuration(record(1)),
      const Duration(hours: 8, minutes: 30),
    );
    expect(recordedAttendanceDuration(record(1, missingOut: true)), isNull);
    final overnight = AttendanceRecord(
      id: 'night',
      tenantId: 'tenant',
      employeeId: 'employee',
      employeeName: '',
      date: DateTime(2026, 10, 1),
      status: 'present',
      checkIn: DateTime.utc(2026, 10, 1, 22),
      checkOut: DateTime.utc(2026, 10, 2, 6),
      createdAt: DateTime(2026),
    );
    expect(recordedAttendanceDuration(overnight), const Duration(hours: 8));
  });
  test(
    'Records are scoped, deduplicated and summaries include only completed duration',
    () async {
      final repo = Repo()
        ..records.addAll([
          record(3),
          record(2, employee: 'foreign'),
          record(1, month: 9),
        ]);
      final controller = cubit(repo);
      addTearDown(controller.close);
      await controller.load();
      expect(controller.state.records.length, 3);
      expect(controller.state.recordedDays, 3);
      expect(controller.state.daysWithStatus('late'), 1);
      expect(controller.state.recordedDuration, const Duration(hours: 17));
      expect(repo.employee, 'employee');
    },
  );
  test('Older month response cannot overwrite newer month', () async {
    final repo = Repo()..loadGate = Completer<EmployeeAttendanceMonth>();
    final controller = cubit(repo);
    addTearDown(controller.close);
    final old = controller.load();
    final oldGate = repo.loadGate!;
    repo.loadGate = null;
    repo.records = [record(1, month: 9)];
    await controller.load(month: DateTime(2026, 9, 15));
    oldGate.complete(EmployeeAttendanceMonth(records: [record(5)]));
    await old;
    expect(controller.state.month, DateTime(2026, 9));
    expect(controller.state.records.single.date.month, 9);
  });
  test(
    'Correction prevents duplicate submission and retains pending on success',
    () async {
      final repo = Repo()..saveGate = Completer<void>();
      final controller = cubit(repo);
      addTearDown(controller.close);
      await controller.load();
      final r = controller.state.records.first;
      final save = controller.requestCorrection(
        record: r,
        checkIn: r.checkIn!,
        checkOut: DateTime(2026, 10, 5, 17),
        reason: ' reason ',
      );
      await expectLater(
        controller.requestCorrection(
          record: r,
          checkIn: r.checkIn!,
          checkOut: DateTime(2026, 10, 5, 17),
          reason: 'reason',
        ),
        throwsStateError,
      );
      repo.saveGate!.complete();
      await save;
      expect(repo.saves, 1);
      expect(repo.reason, 'reason');
      expect(controller.state.pending, contains(r.id));
      expect(r.checkOut, isNull);
    },
  );
  test(
    'Rejected save allows retry and blocks invalid or foreign records',
    () async {
      final repo = Repo();
      final controller = cubit(repo);
      addTearDown(controller.close);
      await controller.load();
      final r = controller.state.records.first;
      Future<void> save(String reason, {AttendanceRecord? other}) =>
          controller.requestCorrection(
            record: other ?? r,
            checkIn: r.checkIn!,
            checkOut: DateTime(2026, 10, 5, 17),
            reason: reason,
          );
      await expectLater(save(''), throwsArgumentError);
      await expectLater(
        save('reason', other: record(5, employee: 'foreign')),
        throwsStateError,
      );
      repo.fail = true;
      await expectLater(save('reason'), throwsStateError);
      expect(controller.state.saving, isFalse);
      expect(controller.state.pending, isEmpty);
      repo.fail = false;
      await save('reason');
      expect(controller.state.pending, contains(r.id));
    },
  );
  test('Leaving during asynchronous load is safe', () async {
    final repo = Repo()..loadGate = Completer<EmployeeAttendanceMonth>();
    final controller = cubit(repo);
    final load = controller.load();
    await controller.close();
    repo.loadGate!.complete(EmployeeAttendanceMonth(records: [record(1)]));
    await load;
  });
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1024.0, 1440.0]) {
      testWidgets('Attendance $width $language adapts without overflow', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = cubit(Repo());
        addTearDown(controller.close);
        await controller.load();
        await tester.pumpWidget(
          app(controller, language: language, scale: width == 320 ? 1.5 : 1),
        );
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -1800));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('Load error offers retry without fabricated statistics', (
    tester,
  ) async {
    final repo = Repo()..fail = true;
    final controller = cubit(repo);
    addTearDown(controller.close);
    await controller.load();
    await tester.pumpWidget(app(controller, language: 'en'));
    await tester.pumpAndSettle();
    expect(find.text('Days with records'), findsNothing);
    expect(find.textContaining('Unable to load data'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(controller.state.records.length, 3);
  });
  testWidgets(
    'Correction form validates reason then submits and shows pending',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = Repo()..records = [record(4)];
      final controller = cubit(repo);
      addTearDown(controller.close);
      await controller.load();
      await tester.pumpWidget(app(controller, language: 'en'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('attendance-correct-record-10-4')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('attendance-correct-record-10-4')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('attendance-correction-submit')),
      );
      await tester.pumpAndSettle();
      expect(repo.saves, 0);
      expect(find.text('Enter a reason'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('attendance-correction-reason')),
        'Correct recorded time',
      );
      await tester.tap(find.byKey(const ValueKey('correction-out')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('attendance-correction-submit')),
      );
      await tester.pumpAndSettle();
      expect(repo.saves, 1);
      expect(find.text('Correction pending'), findsOneWidget);
    },
  );
  testWidgets('Filters, pagination and month navigation use actual data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = Repo()..records = [for (var d = 1; d <= 20; d++) record(d)];
    final controller = cubit(repo);
    addTearDown(controller.close);
    await controller.load();
    await tester.pumpWidget(app(controller, language: 'en'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('attendance-next-page')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('attendance-next-page')));
    await tester.pumpAndSettle();
    expect(find.text('20 records · Page 2 of 2'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('attendance-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('attendance-search')),
      'note-19',
    );
    await tester.pumpAndSettle();
    expect(find.text('1 records · Page 1 of 1'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('attendance-prev-month')));
    await tester.pumpAndSettle();
    expect(repo.month, DateTime(2026, 9));
  });
  for (final language in ['ar', 'en']) {
    testWidgets(
      'Attendance navigation follows $language layout and newest-first order',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 1500);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = Repo()
          ..records = [for (var day = 1; day <= 20; day++) record(day)];
        final controller = cubit(repo);
        addTearDown(controller.close);
        await controller.load();
        await tester.pumpWidget(app(controller, language: language));
        await tester.pumpAndSettle();
        final previous = find.byKey(const ValueKey('attendance-prev-page'));
        final next = find.byKey(const ValueKey('attendance-next-page'));
        await tester.ensureVisible(next);
        await tester.pumpAndSettle();
        expect(
          tester.getCenter(previous).dx > tester.getCenter(next).dx,
          false,
        );
        expect(tester.widget<IconButton>(previous).onPressed, isNull);
        expect(
          tester.widget<IconButton>(next).tooltip,
          contains(language == 'ar' ? 'أقدم' : 'Older'),
        );
        expect(find.text('2026/10/19'), findsWidgets);
        expect(find.text('2026/10/01'), findsNothing);
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(find.text('2026/10/01'), findsWidgets);
        expect(find.text('2026/10/19'), findsNothing);
        expect(tester.widget<IconButton>(next).onPressed, isNull);
        await tester.tap(previous);
        await tester.pumpAndSettle();
        expect(find.text('2026/10/19'), findsWidgets);
        await tester.drag(find.byType(ListView), const Offset(0, 2000));
        await tester.pumpAndSettle();
        final previousMonth = find.byKey(
          const ValueKey('attendance-prev-month'),
        );
        final nextMonth = find.byKey(const ValueKey('attendance-next-month'));
        expect(
          tester.getCenter(previousMonth).dx > tester.getCenter(nextMonth).dx,
          false,
        );
        await tester.tap(nextMonth);
        await tester.pumpAndSettle();
        expect(repo.month, DateTime(2026, 11));
        await tester.tap(previousMonth);
        await tester.pumpAndSettle();
        expect(repo.month, DateTime(2026, 10));
        await tester.tap(previousMonth);
        await tester.pumpAndSettle();
        expect(repo.month, DateTime(2026, 9));
        await tester.tap(nextMonth);
        await tester.pumpAndSettle();
        expect(repo.month, DateTime(2026, 10));
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Desktop attendance preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_ATTENDANCE_PREVIEW')) return;
    await tester.runAsync(() async {
      for (final entry in {
        'Roboto': 'C:/Windows/Fonts/segoeui.ttf',
        'serif': 'C:/Windows/Fonts/times.ttf',
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
    tester.view.physicalSize = const Size(1536, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = Repo()
      ..records.addAll([
        record(2, status: 'absent', missingOut: true),
        record(1, status: 'on_leave', missingOut: true),
      ]);
    final controller = cubit(repo);
    addTearDown(controller.close);
    await controller.load();
    final key = GlobalKey();
    final router = GoRouter(
      initialLocation: '/my?tab=attendance',
      routes: [
        GoRoute(
          path: '/my',
          builder: (context, state) => RepaintBoundary(
            key: key,
            child: AppScaffold(
              title: AppLocalizations.of(context)!.myAttendance,
              employeeStyle: true,
              isCollapsed: false,
              onToggle: () {},
              sidebar: SidebarSection(
                isCollapsed: false,
                onToggle: () {},
                role: 'employee',
                email: 'fixture@example.test',
              ),
              body: BlocProvider.value(value: controller, child: view()),
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
        localizationsDelegates: appLocalizationDelegates,
        theme: EmployeeTheme.from(AppTheme.light()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/employee_attendance_preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
