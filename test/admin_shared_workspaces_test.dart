import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/ui/admin_theme.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/departments/view/hr_organization_page.dart';
import 'package:erp_sys/features/attendance/view/pages/hr_attendance_page.dart';
import 'package:erp_sys/features/employee_docs/view/pages/hr_employee_docs_page.dart';
import 'hr_organization_test.dart' as organization;
import 'hr_attendance_design_test.dart' as attendance;
import 'hr_employee_docs_design_test.dart' as documents;

void main() {
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 1440.0]) {
      testWidgets(
        'Admin shared workspaces $lang $width retain responsive controls',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          for (final workspace in [
            HrOrganizationPage(
              departmentsRepo: organization.Departments(),
              jobTitlesRepo: organization.Titles(),
              loadManagers: () async => [],
            ),
            HrOrganizationPage(
              initialTab: 1,
              departmentsRepo: organization.Departments(),
              jobTitlesRepo: organization.Titles(),
              loadManagers: () async => [],
            ),
            HrAttendancePage(
              repo: attendance.Records(),
              loadEmployees: () async => attendance.employees,
              today: DateTime(2026, 10, 7),
            ),
            HrEmployeeDocsPage(
              repo: documents.Documents(),
              loadEmployees: () async => attendance.employees,
              today: DateTime(2026, 10, 7),
            ),
          ]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: AdminTheme.from(AppTheme.light()),
                locale: Locale(lang),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: appLocalizationDelegates,
                home: Scaffold(body: workspace),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: workspace.runtimeType.toString(),
            );
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          }
        },
      );
    }
  }
}
