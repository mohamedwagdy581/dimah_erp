import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/employee_docs/domain/models/employee_document.dart';
import 'package:erp_sys/features/employee_docs/domain/repos/employee_docs_repo.dart';
import 'package:erp_sys/features/employee_docs/view/pages/hr_employee_docs_page.dart';
import 'package:erp_sys/features/employees/data/repos/hr_employees_repo.dart';
import 'package:erp_sys/features/employees/domain/models/employee.dart';

class Documents implements EmployeeDocsRepo {
  final items = List.generate(
    6,
    (i) => EmployeeDocument(
      id: '$i',
      tenantId: 't',
      employeeId: '${i ~/ 2}',
      employeeName: 'Employee ${i ~/ 2}',
      docType: i == 5
          ? 'custom_document'
          : i.isEven
          ? 'id_card'
          : 'passport',
      fileUrl: 'https://example.com/employee_docs/t/document-$i.pdf',
      issuedAt: DateTime(2025, 1, 10),
      expiresAt: i == 5 ? null : DateTime(2026, 10, 20 + i),
      createdAt: DateTime(2026),
    ),
  );
  int creates = 0;
  String? updated, deleted;
  bool failUpdate = false;
  @override
  Future<({List<EmployeeDocument> items, int total})> fetchDocs({
    required int page,
    required int pageSize,
    String? search,
    String? employeeId,
    String? docType,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async => (
    items: items.skip(page * pageSize).take(pageSize).toList(),
    total: items.length,
  );
  @override
  Future<void> createDoc({
    required String employeeId,
    required String docType,
    required String fileUrl,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) async {
    creates++;
  }

  @override
  Future<void> updateDoc({
    required String id,
    required String employeeId,
    required String docType,
    required String fileUrl,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) async {
    if (failUpdate) throw StateError('Save failed');
    final original = items.firstWhere((d) => d.id == id);
    expect(employeeId, original.employeeId);
    expect(docType, original.docType);
    expect(fileUrl, original.fileUrl);
    expect(issuedAt, original.issuedAt);
    expect(expiresAt, original.expiresAt);
    updated = id;
  }

  @override
  Future<void> deleteDoc({required String id, required String fileUrl}) async {
    deleted = id;
    items.removeWhere((d) => d.id == id);
  }
}

final employees = HrEmployeesData(
  employees: List.generate(
    3,
    (i) => Employee(
      id: '$i',
      tenantId: 't',
      fullName: 'Employee $i',
      employeeNumber: 'EMP-00$i',
      jobTitleName: 'Job title $i',
      email: '',
      phone: '',
      status: 'active',
      hireDate: DateTime(2025),
      createdAt: DateTime(2025),
    ),
  ),
);
Widget app(Documents repo, {String lang = 'ar', String? expiry}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: EmployeeTheme.from(AppTheme.light()),
  locale: Locale(lang),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: HrEmployeeDocsPage(
      repo: repo,
      loadEmployees: () async => employees,
      today: DateTime(2026, 10, 7),
      initialExpiryStatus: expiry,
    ),
  ),
);
void main() {
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1350.0]) {
      testWidgets('Documents $lang $width render and validate attachment', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repo = Documents();
        await tester.pumpWidget(app(repo, lang: lang));
        await tester.pumpAndSettle();
        expect(find.text('Job title 0'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final save = find.byKey(const ValueKey('document-save'));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(repo.creates, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('Editing preserves file and dates, failure allows retry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1350, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = Documents()..failUpdate = true;
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-0')));
    await tester.pumpAndSettle();
    expect(find.text('document-0.pdf'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('document-save')));
    await tester.pumpAndSettle();
    expect(repo.updated, isNull);
    expect(find.text('document-0.pdf'), findsOneWidget);
    repo.failUpdate = false;
    await tester.tap(find.byKey(const ValueKey('document-save')));
    await tester.pumpAndSettle();
    expect(repo.updated, '0');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Legacy no expiry link includes employee outside first card page',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1350, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(Documents(), expiry: 'no_expiry'));
      await tester.pumpAndSettle();
      expect(find.text('Job title 2'), findsOneWidget);
      expect(find.byKey(const ValueKey('edit-5')), findsOneWidget);
      expect(find.byKey(const ValueKey('edit-0')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Delete confirmation cancellation and removal', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1350, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = Documents();
    await tester.pumpWidget(app(repo, lang: 'en'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel').last);
    await tester.pumpAndSettle();
    expect(repo.deleted, isNull);
    await tester.tap(find.byKey(const ValueKey('delete-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete').last);
    await tester.pumpAndSettle();
    expect(repo.deleted, '0');
    expect(find.byKey(const ValueKey('edit-0')), findsNothing);
  });
  testWidgets('Filters include documents beyond a repository page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1350, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = Documents();
    repo.items.clear();
    repo.items.addAll(
      List.generate(
        501,
        (i) => EmployeeDocument(
          id: 'long-$i',
          tenantId: 't',
          employeeId: '2',
          employeeName: 'Employee 2',
          docType: 'custom_document',
          fileUrl: 'https://example.com/document.pdf',
          expiresAt: i == 500 ? null : DateTime(2027),
          createdAt: DateTime(2026),
        ),
      ),
    );
    await tester.pumpWidget(app(repo, expiry: 'no_expiry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-long-500')), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-long-0')), findsNothing);
    expect(find.text('custom_document').last, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Documents visual preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_HR_DOCS')) return;
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
    await tester.binding.setSurfaceSize(const Size(1350, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: app(Documents())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/hr_employee_docs_preview.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
