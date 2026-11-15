import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/features/departments/view/hr_organization_page.dart';
import 'package:erp_sys/features/departments/domain/repos/departments_repo.dart';
import 'package:erp_sys/features/departments/domain/models/department.dart';
import 'package:erp_sys/features/job_titles/domain/repos/job_titles_repo.dart';
import 'package:erp_sys/features/job_titles/domain/models/job_title.dart';
import 'package:erp_sys/features/employees/domain/models/employee_lookup.dart';
import 'package:erp_sys/l10n/app_localizations.dart';

class Departments implements DepartmentsRepo {
  bool failSave = false;
  final writes = <Map<String, Object?>>[];
  final items = List.generate(
    24,
    (i) => Department(
      id: '$i',
      tenantId: 't',
      name: 'Department $i',
      code: 'D$i',
      description: 'Description $i',
      isActive: true,
      managerId: 'm',
      managerName: 'Manager',
    ),
  );
  @override
  Future<({List<Department> items, int total})> fetchDepartments({
    required int page,
    required int pageSize,
    String? search,
    bool? isActive,
    String sortBy = 'name',
    bool ascending = true,
  }) async => (
    items: items.skip(page * pageSize).take(pageSize).toList(),
    total: items.length,
  );
  @override
  Future<void> createDepartment({
    required String name,
    String? code,
    String? description,
    String? managerId,
    bool isActive = true,
  }) async {
    if (failSave) throw StateError('Save failed');
    writes.add({'name': name, 'active': isActive, 'manager': managerId});
  }

  @override
  Future<void> updateDepartment({
    required String id,
    required String name,
    String? code,
    String? description,
    String? managerId,
    required bool isActive,
  }) async => writes.add({
    'id': id,
    'name': name,
    'active': isActive,
    'manager': managerId,
  });
  @override
  Future<int> autoAssignManagers() async => 0;
}

class Titles implements JobTitlesRepo {
  final writes = <Map<String, Object?>>[];
  @override
  Future<({List<JobTitle> items, int total})> fetchJobTitles({
    required int page,
    required int pageSize,
    String? search,
    bool? isActive,
    String? departmentId,
    String sortBy = 'name',
    bool ascending = true,
  }) async => (
    items: [
      JobTitle(
        id: 'job',
        tenantId: 't',
        name: 'Developer',
        description: 'Existing description',
        code: 'DEV',
        level: 4,
        departmentId: '0',
        isActive: false,
        createdAt: DateTime(2026),
      ),
    ],
    total: 1,
  );
  @override
  Future<void> createJobTitle({
    required String name,
    String? code,
    String? description,
    int? level,
    String? departmentId,
    bool isActive = true,
  }) async => writes.add({'name': name});
  @override
  Future<void> updateJobTitle({
    required String id,
    required String name,
    String? code,
    String? description,
    int? level,
    String? departmentId,
    required bool isActive,
  }) async => writes.add({
    'id': id,
    'name': name,
    'code': code,
    'description': description,
    'level': level,
    'department': departmentId,
    'active': isActive,
  });
}

Widget app(Departments d, Titles j, {String lang = 'ar', int tab = 0}) =>
    MaterialApp(
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: EmployeeTheme.from(AppTheme.light()),
      home: Scaffold(
        body: HrOrganizationPage(
          initialTab: tab,
          departmentsRepo: d,
          jobTitlesRepo: j,
          loadManagers: () async => [
            const EmployeeLookup(id: 'm', fullName: 'Manager'),
          ],
        ),
      ),
    );
Finder field(String name) => find.byKey(ValueKey('organization-$name'));
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Organization desktop design preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_ORGANIZATION_PREVIEW')) return;
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
    tester.view.physicalSize = const Size(1350, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: app(Departments(), Titles())),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/hr_organization_preview.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets(
        'Organization $lang $width searches across pages and edits manager',
        (tester) async {
          tester.view.physicalSize = Size(width, 1800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final d = Departments(), j = Titles();
          await tester.pumpWidget(app(d, j, lang: lang));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.enterText(field('search'), 'D23');
          await tester.pumpAndSettle();
          expect(find.text('Department 23'), findsOneWidget);
          await tapVisible(tester, field('edit-23'));
          expect(
            tester.widget<TextFormField>(field('name')).controller!.text,
            'Department 23',
          );
          await tapVisible(tester, field('save'));
          expect(d.writes.single['manager'], 'm');
          expect(d.writes.single['id'], '23');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('New inactive department and failed save preserve input', (
    tester,
  ) async {
    final d = Departments(), j = Titles();
    await tester.pumpWidget(app(d, j));
    await tester.pumpAndSettle();
    await tapVisible(tester, field('save'));
    expect(d.writes, isEmpty);
    await tester.enterText(field('name'), 'New department');
    await tapVisible(tester, find.byType(Switch));
    d.failSave = true;
    await tapVisible(tester, field('save'));
    expect(
      tester.widget<TextFormField>(field('name')).controller!.text,
      'New department',
    );
    d.failSave = false;
    await tapVisible(tester, field('save'));
    expect(d.writes.single['active'], false);
  });
  testWidgets(
    'Job title editing retains department level description and inactive status',
    (tester) async {
      final d = Departments(), j = Titles();
      await tester.pumpWidget(app(d, j, tab: 1));
      await tester.pumpAndSettle();
      await tapVisible(tester, field('edit-job'));
      await tapVisible(tester, field('save'));
      expect(j.writes.single, {
        'id': 'job',
        'name': 'Developer',
        'code': 'DEV',
        'description': 'Existing description',
        'level': 4,
        'department': '0',
        'active': false,
      });
      expect(tester.takeException(), isNull);
    },
  );
}
