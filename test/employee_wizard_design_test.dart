import 'dart:io';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/di/app_di.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/departments/domain/models/department.dart';
import 'package:erp_sys/features/departments/domain/repos/departments_repo.dart';
import 'package:erp_sys/features/job_titles/domain/models/job_title.dart';
import 'package:erp_sys/features/job_titles/domain/repos/job_titles_repo.dart';
import 'package:erp_sys/features/employees/domain/models/employee_lookup.dart';
import 'package:erp_sys/features/employees/domain/models/employee_login_result.dart';
import 'package:erp_sys/features/employees/domain/repos/employee_repo.dart';
import 'package:erp_sys/features/employees/view/cubit/employee_wizard_cubit.dart';
import 'package:erp_sys/features/employees/view/pages/employee_wizard_page.dart';

class _Departments implements DepartmentsRepo {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #fetchDepartments) {
      return Future.value((
        items: [
          Department(
            id: 'dept',
            tenantId: 'tenant',
            name: 'الموارد البشرية',
            code: 'HR',
            description: null,
            isActive: true,
          ),
        ],
        total: 1,
      ));
    }
    return super.noSuchMethod(invocation);
  }
}

class _Titles implements JobTitlesRepo {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #fetchJobTitles) {
      return Future.value((
        items: [
          JobTitle(
            id: 'job',
            tenantId: 'tenant',
            name: 'أخصائي توظيف',
            isActive: true,
            createdAt: DateTime(2025),
            departmentId: 'dept',
          ),
        ],
        total: 1,
      ));
    }
    return super.noSuchMethod(invocation);
  }
}

class _Employees implements EmployeesRepo {
  @override
  Future<void> checkEmployeeCreationReady() async {}
  int creations = 0, provisions = 0;
  Map<Symbol, dynamic>? payload;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #createEmployee) {
      creations++;
      payload = invocation.namedArguments;
      return Future.value('saved-employee');
    }
    return super.noSuchMethod(invocation);
  }

  @override
  Future<List<EmployeeLookup>> fetchEmployeeLookup({
    String? search,
    int limit = 200,
  }) async => [];
  @override
  Future<EmployeeLoginResult> provisionEmployeeLogin({
    required String employeeId,
    required String role,
    required String initialPassword,
  }) async {
    provisions++;
    throw StateError('Provisioning unavailable');
  }
}

Widget _app(EmployeeWizardCubit cubit, {String lang = 'ar'}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  locale: Locale(lang),
  theme: EmployeeTheme.from(AppTheme.light()),
  localizationsDelegates: appLocalizationDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: BlocProvider.value(value: cubit, child: const EmployeeWizardPage()),
);
EmployeeWizardCubit _ready(_Employees repo) => EmployeeWizardCubit(repo)
  ..setFullName('أحمد محمد السالم')
  ..setEmail('ahmed@example.com')
  ..setPhone('0501234567')
  ..setNationalId('1020304056')
  ..setNationality('سعودي')
  ..setGender('male')
  ..setDateOfBirth(DateTime(1992, 10, 15))
  ..setHireDate(DateTime(2026, 10, 1));
Future<void> _next(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('employee-wizard-next'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _selectJob(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('الموارد البشرية').last);
  await tester.pumpAndSettle();
  await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
  await tester.pumpAndSettle();
  await tester.tap(find.text('أخصائي توظيف').last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    AppDI.departmentsRepo = _Departments();
    AppDI.jobTitlesRepo = _Titles();
    AppDI.employeesRepo = _Employees();
  });
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1350.0]) {
      testWidgets('Employee wizard $lang at $width retains personal fields', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final cubit = _ready(_Employees());
        addTearDown(cubit.close);
        await tester.pumpWidget(_app(cubit, lang: lang));
        await tester.pumpAndSettle();
        expect(find.byType(Stepper), findsNothing);
        expect(find.byType(EmployeeWizardProgress), findsOneWidget);
        expect(find.text('أحمد محمد السالم'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _next(tester);
        expect(cubit.state.fullName, 'أحمد محمد السالم');
        expect(tester.takeException(), isNull);
        await _selectJob(tester);
        await _next(tester);
        expect(tester.takeException(), isNull);
        await _next(tester);
        expect(
          tester
              .widget<EmployeeWizardProgress>(
                find.byType(EmployeeWizardProgress),
              )
              .currentStep,
          3,
        );
        expect(tester.takeException(), isNull);
        final back = find.byKey(const ValueKey('employee-wizard-back'));
        for (var index = 0; index < 3; index++) {
          await tester.ensureVisible(back);
          await tester.tap(back);
          await tester.pumpAndSettle();
        }
        expect(find.text('أحمد محمد السالم'), findsOneWidget);
        expect(find.text('ahmed@example.com'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('Validation opens missing required personal information', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1350, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cubit = EmployeeWizardCubit(_Employees());
    addTearDown(cubit.close);
    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();
    await _next(tester);
    expect(
      find.byType(EmployeeWizardProgress).evaluate().single.widget
          is EmployeeWizardProgress,
      isTrue,
    );
    expect(
      (tester.widget<EmployeeWizardProgress>(
        find.byType(EmployeeWizardProgress),
      )).currentStep,
      0,
    );
    expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Four steps preserve compensation and retry without duplicate employee',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1350, 1500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = _Employees();
      final cubit = _ready(repo);
      addTearDown(cubit.close);
      await tester.pumpWidget(_app(cubit));
      await tester.pumpAndSettle();
      await _next(tester);
      await _selectJob(tester);
      await _next(tester);
      expect(
        tester
            .widget<EmployeeWizardProgress>(find.byType(EmployeeWizardProgress))
            .currentStep,
        2,
      );
      await _next(tester);
      await tester.enterText(find.byType(TextFormField).first, '12000');
      await tester.enterText(
        find.byKey(const ValueKey('employee-login-password')),
        'Only-test@2042',
      );
      await tester.tap(find.byKey(const ValueKey('employee-wizard-back')));
      await tester.pumpAndSettle();
      await _next(tester);
      expect(find.text('12000'), findsOneWidget);
      await _next(tester);
      expect(repo.creations, 1);
      expect(repo.provisions, 1);
      expect(repo.payload![#nationality], 'سعودي');
      expect(repo.payload![#basicSalary], 12000.0);
      expect(cubit.state.savedEmployeeId, 'saved-employee');
      await _next(tester);
      expect(repo.creations, 1);
      expect(repo.provisions, 2);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Invalid contract dates block progression', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1350, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cubit = _ready(_Employees())
      ..setContractStart(DateTime(2026, 10, 1))
      ..setContractEnd(DateTime(2026, 9, 1));
    addTearDown(cubit.close);
    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();
    await _next(tester);
    await _selectJob(tester);
    await _next(tester);
    await _next(tester);
    expect(
      tester
          .widget<EmployeeWizardProgress>(find.byType(EmployeeWizardProgress))
          .currentStep,
      2,
    );
    expect(
      find.text('تاريخ نهاية العقد يجب أن يكون بعد بدايته'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Employee wizard visual preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_EMPLOYEE_WIZARD')) return;
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
    await tester.binding.setSurfaceSize(const Size(1250, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cubit = _ready(_Employees());
    addTearDown(cubit.close);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: _app(cubit)));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/employee_wizard_preview.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  });
}
