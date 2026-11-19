import 'dart:io';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/features/attendance/domain/models/attendance_record.dart';
import 'package:erp_sys/features/manager_team/domain/manager_team_data.dart';
import 'package:erp_sys/features/manager_attendance/manager_attendance_repo.dart';
import 'package:erp_sys/features/manager_attendance/manager_attendance_page.dart';
import 'package:erp_sys/features/manager_attendance/manager_attendance_cubit.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';

AttendanceRecord record(
  int id, {
  String employee = 'e1',
  String status = 'present',
  bool missing = false,
}) => AttendanceRecord(
  id: '$id',
  tenantId: 'tenant',
  employeeId: employee,
  employeeName: employee == 'e1' ? 'موظف اختبار' : 'موظف آخر',
  date: DateTime(2026, 10, 5),
  status: status,
  checkIn: DateTime.utc(2026, 10, 5, 7),
  checkOut: missing ? null : DateTime.utc(2026, 10, 5, 15),
  createdAt: DateTime.utc(2026, 10, 5),
);

class FakeAttendanceRepo implements ManagerAttendanceRepo {
  bool fail = false;
  DateTime? lastMonth;
  @override
  Future<ManagerAttendanceData> load(DateTime month) async {
    lastMonth = month;
    if (fail) throw StateError('fixture failure');
    return ManagerAttendanceData(
      members: const [
        TeamMember(id: 'e1', name: 'موظف اختبار'),
        TeamMember(id: 'e2', name: 'موظف آخر'),
      ],
      records: [
        record(1),
        record(2, employee: 'e2', status: 'late', missing: true),
      ],
    );
  }
}

void main() {
  Future<ManagerAttendanceCubit> pump(
    WidgetTester tester,
    double width,
    String lang,
    FakeAttendanceRepo repo, {
    GlobalKey? capture,
  }) async {
    tester.view.physicalSize = Size(width, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = ManagerAttendanceCubit(repo, now: DateTime(2026, 10, 6));
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
              child: const ManagerAttendanceView(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  test(
    'Complete duration requires both timestamps and excludes invalid order',
    () {
      expect(managerAttendanceDuration(record(1)), const Duration(hours: 8));
      expect(managerAttendanceDuration(record(2, missing: true)), isNull);
      final r = record(1);
      expect(
        managerAttendanceDuration(
          AttendanceRecord(
            id: r.id,
            tenantId: r.tenantId,
            employeeId: r.employeeId,
            employeeName: r.employeeName,
            date: r.date,
            status: r.status,
            checkIn: r.checkOut,
            checkOut: r.checkIn,
            createdAt: r.createdAt,
          ),
        ),
        isNull,
      );
    },
  );
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('Attendance layout $lang $width fits', (tester) async {
        await pump(tester, width, lang, FakeAttendanceRepo());
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('Next arrow moves forward and employee filter narrows records', (
    tester,
  ) async {
    final repo = FakeAttendanceRepo();
    await pump(tester, 1440, 'ar', repo);
    await tester.tap(find.byTooltip('الشهر التالي'));
    await tester.pumpAndSettle();
    expect(repo.lastMonth, DateTime(2026, 11));
    await tester.tap(find.byTooltip('الشهر السابق'));
    await tester.pumpAndSettle();
    expect(repo.lastMonth, DateTime(2026, 10));
    await tester.tap(find.byKey(const ValueKey('attendance-member-e1')));
    await tester.pumpAndSettle();
    expect(find.text('موظف آخر'), findsOneWidget);
    expect(find.text('كل الفريق'), findsOneWidget);
  });
  testWidgets('Failure does not display misleading zero summaries', (
    tester,
  ) async {
    await pump(tester, 1440, 'ar', FakeAttendanceRepo()..fail = true);
    expect(find.text('تعذّر تحميل البيانات'), findsOneWidget);
    expect(find.text('ملخص الموظفين'), findsNothing);
  });
  testWidgets('Export attendance preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_ATTENDANCE_PREVIEW')) return;
    await tester.runAsync(() async {
      for (final e in {
        'Roboto': 'C:/Windows/Fonts/segoeui.ttf',
        'MaterialIcons':
            'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      }.entries) {
        final loader = FontLoader(e.key)
          ..addFont(
            Future.value(
              ByteData.sublistView(await File(e.value).readAsBytes()),
            ),
          );
        await loader.load();
      }
    });
    final key = GlobalKey();
    await pump(tester, 1440, 'ar', FakeAttendanceRepo(), capture: key);
    await tester.runAsync(() async {
      final picture =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/manager_attendance_preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  });
}
