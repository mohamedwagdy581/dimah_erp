import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/core/widgets/app_scaffold.dart';
import 'package:erp_sys/features/profile/domain/repos/profile_repo.dart';
import 'package:erp_sys/features/profile/view/employee_profile_cubit.dart';
import 'package:erp_sys/features/profile/view/employee_profile_view.dart';
import 'package:erp_sys/features/shell/view/sections/sidebar_section.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class Repo implements ProfileRepo {
  String name = 'اسم الحساب الفعلي';
  String phone = '0500000000';
  bool failLoad = false, failSave = false;
  int saves = 0;
  Completer<void>? pending;
  @override
  Future<({String name, String phone})> getProfile() async {
    if (failLoad) throw StateError('Unavailable');
    return (name: name, phone: phone);
  }

  @override
  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    saves++;
    await pending?.future;
    if (failSave) throw StateError('Unavailable');
    this.name = name;
    this.phone = phone;
  }
}

Widget view({VoidCallback? password, Future<void> Function()? logout}) =>
    EmployeeProfileView(
      email: 'account@example.test',
      onPassword: password ?? () {},
      onLogout: logout ?? () async {},
    );
Widget app(
  EmployeeProfileCubit cubit, {
  String language = 'ar',
  double scale = 1,
  Widget? child,
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
          child: child ?? view(),
        ),
      ),
    ),
  ),
);
Finder field(String name) => find.byKey(ValueKey('employee-profile-$name'));
Future<void> tap(WidgetTester tester, String name) async {
  if (field(name).evaluate().isEmpty) {
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(field(name));
  await tester.pumpAndSettle();
  await tester.tap(field(name));
  await tester.pumpAndSettle();
}

void main() {
  test('Initials and localized phone digits use actual values', () {
    expect(profileInitials('  محمد   علي حسن '), 'م ع');
    expect(profileInitials(''), '');
    expect(profilePhoneDigits(' +٩٦٦ ۵۰۰۰۰۰۰۰۰ '), '+966 500000000');
  });
  test('Loading can retry and saving prevents duplicate requests', () async {
    final repo = Repo()..failLoad = true;
    final cubit = EmployeeProfileCubit(repo);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.error, isNotNull);
    repo.failLoad = false;
    await cubit.load();
    repo.pending = Completer<void>();
    final first = cubit.save(name: ' New name ', phone: ' 0500000001 ');
    await cubit.save(name: 'Duplicate', phone: '0500000002');
    expect(repo.saves, 1);
    repo.pending!.complete();
    await first;
    expect(cubit.state.name, 'New name');
    expect(cubit.state.phone, '0500000001');
    expect(cubit.state.saveVersion, 1);
  });
  test(
    'Save failure preserves last saved account and supports retry',
    () async {
      final repo = Repo()..failSave = true;
      final cubit = EmployeeProfileCubit(repo);
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.save(name: 'New', phone: '0500000001');
      expect(cubit.state.name, repo.name);
      expect(cubit.state.saveError, isNotNull);
      repo.failSave = false;
      await cubit.save(name: 'New', phone: '0500000001');
      expect(cubit.state.name, 'New');
      expect(cubit.state.saveError, isNull);
    },
  );
  test('Leaving during pending save safely completes', () async {
    final repo = Repo()..pending = Completer<void>();
    final cubit = EmployeeProfileCubit(repo);
    await cubit.load();
    final save = cubit.save(name: 'New', phone: '0500000001');
    await cubit.close();
    repo.pending!.complete();
    await save;
  });
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('$language profile fits width $width', (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final cubit = EmployeeProfileCubit(Repo());
        addTearDown(cubit.close);
        await cubit.load();
        await tester.pumpWidget(
          app(cubit, language: language, scale: width == 320 ? 1.5 : 1),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(field('password'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final name in ['email', 'role']) {
          expect(
            tester
                .widget<TextField>(
                  find.descendant(
                    of: field(name),
                    matching: find.byType(TextField),
                  ),
                )
                .readOnly,
            isTrue,
          );
        }
      });
    }
  }
  testWidgets('Save normalizes digits; cancel restores latest saved values', (
    tester,
  ) async {
    final repo = Repo();
    final cubit = EmployeeProfileCubit(repo);
    addTearDown(cubit.close);
    await tester.pumpWidget(app(cubit));
    await cubit.load();
    await tester.pumpAndSettle();
    await tester.enterText(field('name'), ' Updated name ');
    await tester.enterText(field('phone'), '٠٥٠٠٠٠٠٠٠١');
    await tap(tester, 'save');
    expect(repo.name, 'Updated name');
    expect(repo.phone, '0500000001');
    expect(
      tester.widget<TextFormField>(field('name')).controller!.text,
      'Updated name',
    );
    await tester.ensureVisible(field('name'));
    await tester.enterText(field('name'), 'Unsaved');
    await tap(tester, 'cancel');
    expect(
      tester.widget<TextFormField>(field('name')).controller!.text,
      'Updated name',
    );
    expect(repo.saves, 1);
  });
  testWidgets('Invalid inputs do not save', (tester) async {
    final repo = Repo();
    final cubit = EmployeeProfileCubit(repo);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(app(cubit));
    await tester.pumpAndSettle();
    await tester.enterText(field('name'), ' ');
    await tester.enterText(field('phone'), 'invalid');
    await tap(tester, 'save');
    expect(repo.saves, 0);
    expect(find.text('اكتب الاسم'), findsOneWidget);
    expect(find.text('اكتب رقم جوال صحيحًا'), findsOneWidget);
  });
  testWidgets('Failed save keeps draft for retry', (tester) async {
    final repo = Repo()..failSave = true;
    final cubit = EmployeeProfileCubit(repo);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(app(cubit));
    await tester.pumpAndSettle();
    await tester.enterText(field('name'), 'Draft');
    await tap(tester, 'save');
    expect(
      tester.widget<TextFormField>(field('name')).controller!.text,
      'Draft',
    );
    repo.failSave = false;
    await tap(tester, 'save');
    expect(repo.name, 'Draft');
  });
  testWidgets('Security and logout invoke existing actions', (tester) async {
    var passwords = 0, logouts = 0;
    final cubit = EmployeeProfileCubit(Repo());
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      app(
        cubit,
        child: view(
          password: () => passwords++,
          logout: () async {
            logouts++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, 'password');
    await tap(tester, 'logout');
    expect(passwords, 1);
    expect(logouts, 1);
  });
  testWidgets('Desktop profile preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_PROFILE_PREVIEW')) return;
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
    tester.view.physicalSize = const Size(1536, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = EmployeeProfileCubit(Repo());
    addTearDown(cubit.close);
    await cubit.load();
    final key = GlobalKey();
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => RepaintBoundary(
            key: key,
            child: AppScaffold(
              title: AppLocalizations.of(context)!.myProfile,
              employeeStyle: true,
              isCollapsed: false,
              onToggle: () {},
              sidebar: SidebarSection(
                isCollapsed: false,
                onToggle: () {},
                role: 'employee',
                email: 'account@example.test',
              ),
              body: BlocProvider.value(value: cubit, child: view()),
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
        'build/employee_profile_preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
