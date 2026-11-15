import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/features/employees/domain/models/employee_profile_details.dart';
import 'package:erp_sys/features/employees/view/widgets/employee_profile/employee_profile_identity_header.dart';
import 'package:erp_sys/features/employees/view/widgets/employee_profile/employee_profile_contracts.dart';
import 'package:erp_sys/features/employees/view/widgets/employee_profile/employee_profile_sections.dart';
import 'package:erp_sys/l10n/app_localizations.dart';

final profile = EmployeeProfileDetails(
  id: 'employee',
  fullName: 'أحمد سالم أحمد',
  employeeNumber: 'EMP-007',
  email: 'employee@example.test',
  phone: '0500000000',
  status: 'active',
  jobTitleName: 'أخصائي توظيف',
  departmentName: 'الموارد البشرية',
  managerName: 'سارة أحمد',
  hireDate: DateTime(2026, 10, 10),
  contractType: 'عقد محدد المدة',
  contractStart: DateTime(2025, 10, 25),
  contractEnd: DateTime(2026, 10, 24),
  probationMonths: 3,
  contractFileUrl: 'https://example.test/current.pdf',
  nationalId: '1234567890',
  insuranceProvider: 'Insurance data',
  university: 'University data',
  contractHistory: [
    EmployeeContractVersion(
      id: 'contract',
      contractType: 'عقد محدد المدة',
      startDate: DateTime(2025, 10, 25),
      endDate: DateTime(2026, 10, 24),
      probationMonths: 3,
      fileUrl: 'https://example.test/history.pdf',
    ),
  ],
);
Widget app(Widget child, String lang) => MaterialApp(
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: EmployeeTheme.from(AppTheme.light()),
  home: Scaffold(body: child),
);
void main() {
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets(
        'Employee details $lang $width preserve identity and contract actions',
        (tester) async {
          tester.view.physicalSize = Size(width, 1700);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var edits = 0, adds = 0;
          final opened = <String>[];
          await tester.pumpWidget(
            app(
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  EmployeeProfileIdentityHeader(
                    profile: profile,
                    canEdit: true,
                    onDownload: () {},
                    onEdit: () => edits++,
                    onIdentity: () {},
                  ),
                  const SizedBox(height: 16),
                  EmployeeProfileContracts(
                    profile: profile,
                    canEdit: true,
                    onAdd: () => adds++,
                    onOpenUrl: opened.add,
                    today: DateTime(2026, 10, 6),
                  ),
                ],
              ),
              lang,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('EMP-007'), findsOneWidget);
          expect(
            find.text(lang == 'ar' ? '18 يوم' : '18 days'),
            findsOneWidget,
          );
          final t = await AppLocalizations.delegate.load(Locale(lang));
          await tester.tap(find.byTooltip(t.editProfile));
          await tester.ensureVisible(
            find.byKey(const ValueKey('contract-expiry-add')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('contract-expiry-add')));
          await tester.tap(find.byKey(const ValueKey('contract-expiry-open')));
          expect(edits, 1);
          expect(adds, 1);
          expect(opened, ['https://example.test/current.pdf']);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'Personal tab retains insurance and education fields on narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 5000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(
          ListView(
            children: [
              EmployeeProfileSections(
                profile: profile,
                section: 0,
                canEdit: false,
                onAddCompensationVersion: () {},
                onAddContractVersion: () {},
                onAddSettlement: () {},
                onOpenUrl: (_) {},
              ),
            ],
          ),
          'ar',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Insurance data'), findsOneWidget);
      expect(find.text('University data'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Contract preview and read-only actions', (tester) async {
    tester.view.physicalSize = const Size(1300, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (const bool.fromEnvironment('EXPORT_HR_DETAILS_PREVIEW')) {
      await tester.runAsync(() async {
        final font = FontLoader('Roboto');
        font.addFont(
          File(
            'C:/Windows/Fonts/segoeui.ttf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
        await font.load();
        final icons = FontLoader('MaterialIcons');
        icons.addFont(
          File(
            'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
        await icons.load();
      });
    }
    final boundary = GlobalKey();
    await tester.pumpWidget(
      app(
        RepaintBoundary(
          key: boundary,
          child: Material(
            color: Colors.white,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                EmployeeProfileIdentityHeader(
                  profile: profile,
                  canEdit: false,
                  onDownload: () {},
                ),
                const SizedBox(height: 18),
                EmployeeProfileContracts(
                  profile: profile,
                  canEdit: false,
                  onAdd: () {},
                  onOpenUrl: (_) {},
                  today: DateTime(2026, 10, 6),
                ),
              ],
            ),
          ),
        ),
        'ar',
      ),
    );
    await tester.pumpAndSettle();
    final t = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.byKey(const ValueKey('contract-expiry-add')), findsNothing);
    expect(find.byTooltip(t.editProfile), findsNothing);
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('EXPORT_HR_DETAILS_PREVIEW')) {
      await tester.runAsync(() async {
        final screenshot =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await screenshot.toByteData(
          format: ui.ImageByteFormat.png,
        );
        Directory('build').createSync(recursive: true);
        File(
          'build/hr_employee_details_preview.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        screenshot.dispose();
      });
    }
  });
}
