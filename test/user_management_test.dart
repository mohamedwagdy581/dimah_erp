import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/user_management/user_management_page.dart';
import 'package:erp_sys/features/user_management/user_management_repo.dart';
import 'package:erp_sys/features/shell/domain/nav_menu.dart';
import 'package:erp_sys/core/routing/app_routes.dart';

final users = [
  const ManagedUser(
    id: 'admin',
    name: 'حساب المدير',
    email: 'admin@example.test',
    role: 'admin',
    active: true,
  ),
  const ManagedUser(
    id: 'employee',
    name: 'نورة علي',
    email: 'noura@example.test',
    role: 'employee',
    active: true,
    employeeId: 'employee-1',
  ),
  ...List.generate(
    8,
    (i) => ManagedUser(
      id: 'user-$i',
      name: 'مستخدم $i',
      email: 'user$i@example.test',
      role: 'hr',
      active: true,
    ),
  ),
];

class Repo implements UserManagementRepo {
  bool canEdit = true, failLoad = false, failSave = false;
  int saves = 0;
  String? savedRole;
  bool? savedActive;
  @override
  Future<ManagedUsersData> load() async {
    if (failLoad) throw StateError('unavailable');
    return ManagedUsersData(actorId: 'admin', canEdit: canEdit, users: users);
  }

  @override
  Future<ManagedUser> save(ManagedUser user, String role, bool active) async {
    saves++;
    savedRole = role;
    savedActive = active;
    if (failSave) throw StateError('unavailable');
    return ManagedUser(
      id: user.id,
      name: user.name,
      email: user.email,
      role: role,
      active: active,
      employeeId: user.employeeId,
    );
  }
}

Widget app(Repo repo, {String lang = 'ar'}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: EmployeeTheme.from(AppTheme.light()),
  home: Scaffold(body: UserManagementPage(repo: repo)),
);
Future<void> tap(WidgetTester t, Finder finder) async {
  await t.ensureVisible(finder);
  await t.pumpAndSettle();
  await t.tap(finder);
  await t.pumpAndSettle();
}

void main() {
  test('HR navigation hides legacy leave and approvals links', () {
    final paths = NavMenu.forRole('hr').map((i) => i.path).toList();
    expect(paths, isNot(contains(AppRoutes.leaves)));
    expect(paths, isNot(contains(AppRoutes.approvals)));
    expect(paths, contains(AppRoutes.userManagement));
    expect(
      NavMenu.forRole('admin').map((i) => i.path),
      contains(AppRoutes.approvals),
    );
  });
  for (final editable in [false, true]) {
    for (final lang in ['ar', 'en']) {
      testWidgets(
        'Selected user details scroll in short desktop window $lang editable=$editable',
        (t) async {
          await t.binding.setSurfaceSize(const Size(1200, 650));
          addTearDown(() => t.binding.setSurfaceSize(null));
          await t.pumpWidget(app(Repo()..canEdit = editable, lang: lang));
          await t.pumpAndSettle();
          await tap(t, find.text('حساب المدير'));
          expect(t.takeException(), isNull);
          final scroll = t.widget<SingleChildScrollView>(
            find.byKey(const ValueKey('user-details-scroll')),
          );
          expect(scroll.controller!.position.maxScrollExtent, greaterThan(0));
          scroll.controller!.jumpTo(
            scroll.controller!.position.maxScrollExtent,
          );
          await t.pumpAndSettle();
          await t.ensureVisible(find.byKey(const ValueKey('user-save')));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
        },
      );
    }
  }
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('User management $lang fits $width with selected user', (
        t,
      ) async {
        await t.binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => t.binding.setSurfaceSize(null));
        await t.pumpWidget(app(Repo(), lang: lang));
        await t.pumpAndSettle();
        await tap(t, find.text('نورة علي'));
        expect(t.takeException(), isNull);
        await t.ensureVisible(find.byType(DropdownButtonFormField<String>));
        await t.pumpAndSettle();
        expect(
          t
              .widget<DropdownButtonFormField<String>>(
                find.byType(DropdownButtonFormField<String>),
              )
              .onChanged,
          isNotNull,
        );
        final scroll = t.widget<SingleChildScrollView>(
          find.byKey(const ValueKey('user-table-scroll')),
        );
        scroll.controller!.jumpTo(scroll.controller!.position.maxScrollExtent);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });
    }
  }
  testWidgets('Admin saves changed role and status; failure retains draft', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final repo = Repo()..failSave = true;
    await t.pumpWidget(app(repo));
    await t.pumpAndSettle();
    await tap(t, find.text('نورة علي'));
    await tap(t, find.byType(DropdownButtonFormField<String>));
    await tap(t, find.text('موارد بشرية').last);
    await tap(t, find.byKey(const ValueKey('user-active')));
    await tap(t, find.byKey(const ValueKey('user-save')));
    expect(repo.saves, 1);
    expect(repo.savedRole, 'hr');
    expect(repo.savedActive, false);
    expect(
      t.widget<Switch>(find.byKey(const ValueKey('user-active'))).value,
      false,
    );
    repo.failSave = false;
    await tap(t, find.byKey(const ValueKey('user-save')));
    expect(repo.saves, 2);
    expect(
      t.widget<FilledButton>(find.byKey(const ValueKey('user-save'))).onPressed,
      isNull,
    );
    expect(t.takeException(), isNull);
  });
  testWidgets('HR cannot edit; admin cannot change own account', (t) async {
    await t.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final repo = Repo()..canEdit = false;
    await t.pumpWidget(app(repo));
    await t.pumpAndSettle();
    await tap(t, find.text('نورة علي'));
    expect(
      t
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .onChanged,
      isNull,
    );
    expect(
      t.widget<Switch>(find.byKey(const ValueKey('user-active'))).onChanged,
      isNull,
    );
    expect(repo.saves, 0);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
    await t.pumpWidget(app(Repo()));
    await t.pumpAndSettle();
    await tap(t, find.text('حساب المدير'));
    expect(
      t.widget<Switch>(find.byKey(const ValueKey('user-active'))).onChanged,
      isNull,
    );
    expect(
      t
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .onChanged,
      isNull,
    );
  });
  testWidgets('Search pagination and load retry', (t) async {
    final repo = Repo()..failLoad = true;
    await t.pumpWidget(app(repo));
    await t.pumpAndSettle();
    repo.failLoad = false;
    await tap(t, find.text('إعادة المحاولة'));
    expect(find.text('1 / 2'), findsOneWidget);
    await tap(t, find.byTooltip('الصفحة التالية'));
    expect(find.text('2 / 2'), findsOneWidget);
    await t.ensureVisible(find.byKey(const ValueKey('user-search')));
    await t.enterText(find.byKey(const ValueKey('user-search')), 'noura@');
    await t.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.text('نورة علي'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('user-search')), 'missing');
    await t.pumpAndSettle();
    expect(find.text('لا توجد نتائج مطابقة'), findsOneWidget);
  });
  testWidgets('Visual preview', (t) async {
    if (!const bool.fromEnvironment('EXPORT_USERS')) return;
    await t.runAsync(() async {
      for (final font in {
        'Roboto': 'C:/Windows/Fonts/segoeui.ttf',
        'MaterialIcons':
            'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(font.key)..addFont(
              Future.value(
                ByteData.sublistView(await File(font.value).readAsBytes()),
              ),
            ))
            .load();
      }
    });
    await t.binding.setSurfaceSize(const Size(1250, 850));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(key: key, child: app(Repo())));
    await t.pumpAndSettle();
    await tap(t, find.text('نورة علي'));
    await t.runAsync(() async {
      final picture =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/user_management_preview.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  });
}
