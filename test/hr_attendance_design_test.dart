import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/attendance/domain/models/attendance_record.dart';
import 'package:erp_sys/features/attendance/domain/repos/attendance_repo.dart';
import 'package:erp_sys/features/attendance/view/pages/hr_attendance_page.dart';
import 'package:erp_sys/features/employees/data/repos/hr_employees_repo.dart';
import 'package:erp_sys/features/employees/domain/models/employee.dart';

class Records implements AttendanceRepo {
  final items = List.generate(
    23,
    (i) => AttendanceRecord(
      id: '$i',
      tenantId: 't',
      employeeId: '$i',
      employeeName: 'Employee $i',
      date: DateTime(2026, 10, 5),
      status: i == 22 ? 'absent' : 'present',
      checkIn: DateTime.utc(2026, 10, 5, 7),
      checkOut: DateTime.utc(2026, 10, 5, 14),
      notes: 'Note $i',
      createdAt: DateTime(2026),
    ),
  );
  @override
  Future<({List<AttendanceRecord> items, int total})> fetchAttendance({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    DateTime? date,
    String? employeeId,
    String sortBy = 'date',
    bool ascending = false,
  }) async => (
    items: items.skip(page * pageSize).take(pageSize).toList(),
    total: items.length,
  );
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

final employees = HrEmployeesData(
  departments: const {'d': 'Engineering', 'f': 'Finance'},
  employees: List.generate(
    23,
    (i) => Employee(
      id: '$i',
      tenantId: 't',
      fullName: 'Employee $i',
      employeeNumber: 'EMP-$i',
      email: '',
      phone: '',
      status: 'active',
      hireDate: DateTime(2026),
      createdAt: DateTime(2026),
      departmentId: i == 22 ? 'f' : 'd',
    ),
  ),
);
Widget app({String lang = 'ar'}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: EmployeeTheme.from(AppTheme.light()),
  locale: Locale(lang),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: HrAttendancePage(
      repo: Records(),
      loadEmployees: () async => employees,
      today: DateTime(2026, 10, 7),
    ),
  ),
);

void main() {
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1350.0]) {
      testWidgets(
        'HR attendance $lang $width filters all employees and opens inline import',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 1400));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(app(lang: lang));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final search = find.byKey(const ValueKey('attendance-search'));
          await tester.enterText(search, 'Employee 22');
          await tester.pumpAndSettle();
          expect(
            find.byWidgetPredicate((w) => w is Text && w.data == 'Employee 22'),
            findsOneWidget,
          );
          expect(find.text('Employee 0'), findsNothing);
          expect(find.text('10:00'), findsOneWidget);
          expect(find.text('17:00'), findsOneWidget);
          await tester.enterText(search, '');
          await tester.pumpAndSettle();
          final import = find.text(
            lang == 'ar' ? 'استيراد سجلات' : 'Import records',
          );
          await tester.ensureVisible(import);
          await tester.tap(import);
          await tester.pumpAndSettle();
          expect(
            find.text(
              lang == 'ar'
                  ? 'معاينة البيانات المستوردة'
                  : 'Imported records preview',
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('HR attendance visual preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_HR_ATTENDANCE')) return;
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
    await tester.binding.setSurfaceSize(const Size(1350, 1050));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: app()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('استيراد سجلات'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/hr_attendance_preview.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
