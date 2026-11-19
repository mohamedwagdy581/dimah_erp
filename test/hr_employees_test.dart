import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/features/employees/data/repos/hr_employees_repo.dart';
import 'package:erp_sys/features/employees/domain/models/employee.dart';
import 'package:erp_sys/features/employees/view/pages/hr_employees_page.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';

final fixture = HrEmployeesData(
  departments: const {'d1': 'Engineering', 'd2': 'Finance'},
  jobTitles: const {'j1': 'Developer', 'j2': 'Accountant'},
  employees: List.generate(
    24,
    (i) => Employee(
      id: '$i',
      tenantId: 'tenant',
      fullName: 'Employee ${i.toString().padLeft(2, '0')}',
      employeeNumber: 'EMP-$i',
      email: 'e$i@test.example',
      phone: '',
      status: i == 23 ? 'inactive' : 'active',
      hireDate: DateTime(2026, 10, 1),
      createdAt: DateTime(2026),
      departmentId: i < 12 ? 'd1' : 'd2',
      jobTitleId: i < 12 ? 'j1' : 'j2',
    ),
  ),
);
void main() {
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('HR employees $lang $width fits and searches all pages', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                body: HrEmployeesView(data: fixture, onRefresh: () {}),
              ),
            ),
            GoRoute(
              path: '/employees/create',
              builder: (_, _) =>
                  const Scaffold(body: Text('Create destination')),
            ),
            GoRoute(
              path: '/employees/:id',
              builder: (_, state) =>
                  Scaffold(body: Text('Profile ${state.pathParameters['id']}')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: appLocalizationDelegates,
            theme: EmployeeTheme.from(AppTheme.light()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byType(TextField), 'EMP-23');
        await tester.pumpAndSettle();
        expect(find.text('Employee 23'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('inactive-employees')));
        await tester.pumpAndSettle();
        expect(find.text('Employee 23'), findsOneWidget);
        expect(find.text('Employee 00'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('current-employees')));
        await tester.enterText(find.byType(TextField), 'Employee 05');
        await tester.pumpAndSettle();
        expect(find.text('Employee 05').last, findsOneWidget);
        await tester.ensureVisible(find.text('Employee 05').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Employee 05').last);
        await tester.pumpAndSettle();
        expect(find.text('Profile 5'), findsOneWidget);
      });
    }
  }
  testWidgets('Department, job and status combine and reset', (tester) async {
    tester.view.physicalSize = const Size(1440, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationDelegates,
        home: Scaffold(
          body: HrEmployeesView(data: fixture, onRefresh: () {}),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finance').last);
    await tester.pumpAndSettle();
    expect(find.text('Employee 00'), findsNothing);
    expect(find.text('Employee 12'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Developer').last);
    await tester.pumpAndSettle();
    expect(find.text('Employee 12'), findsNothing);
    await tester.tap(find.text('Reset filters'));
    await tester.pumpAndSettle();
    expect(find.text('Employee 00'), findsOneWidget);
  });
}
