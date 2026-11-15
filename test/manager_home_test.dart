import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:erp_sys/core/routing/app_routes.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/features/shell/domain/nav_menu.dart';
import 'package:erp_sys/features/manager_home/manager_home_page.dart';
import 'package:erp_sys/features/manager_team/data/manager_team_repo.dart';
import 'package:erp_sys/features/manager_team/domain/manager_team_data.dart';
import 'package:erp_sys/features/manager_team/view/manager_team_cubit.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class HomeRepo implements ManagerTeamRepo {
  bool fail = false;
  @override
  Future<ManagerTeamData> load() async {
    if (fail) throw StateError('failure');
    return ManagerTeamData(
      managerName: 'مدير اختبار',
      departmentNames: const ['التسويق'],
      members: const [TeamMember(id: 'e', name: 'موظف اختبار')],
      pendingRequests: 3,
      tasks: [
        TeamTask({
          'id': '1',
          'employee_id': 'e',
          'title': 'مهمة قادمة',
          'status': 'in_progress',
          'due_date': '2026-10-08',
          'progress': 20,
          'employee_review_status': 'pending',
        }),
        TeamTask({
          'id': '2',
          'employee_id': 'e',
          'title': 'مهمة متأخرة',
          'status': 'in_progress',
          'due_date': '2026-10-01',
          'progress': 40,
        }),
        TeamTask({
          'id': '3',
          'employee_id': 'e',
          'title': 'تسليم للمراجعة',
          'status': 'done',
          'qa_status': 'pending',
        }),
      ],
    );
  }
}

void main() {
  testWidgets('Export home preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_HOME_PREVIEW')) return;
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
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = ManagerTeamCubit(HomeRepo());
    addTearDown(cubit.close);
    await cubit.load();
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: EmployeeTheme.from(AppTheme.light()),
        home: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: ManagerHomeView(now: DateTime(2026, 10, 6)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final picture =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/manager_home_preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  });
  test('Payroll stays with HR and finance and leaves both manager menus', () {
    for (final role in ['manager', 'direct_manager']) {
      expect(
        NavMenu.forRole(role).any((item) => item.path == AppRoutes.payroll),
        isFalse,
      );
      expect(
        NavMenu.forRole(role).any((item) => item.path == AppRoutes.dashboard),
        isTrue,
      );
    }
    expect(
      NavMenu.forRole('hr').any((item) => item.path == AppRoutes.payroll),
      isTrue,
    );
  });
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('Home $lang fits $width and opens attendance', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final cubit = ManagerTeamCubit(HomeRepo());
        await cubit.load();
        addTearDown(cubit.close);
        expect(
          cubit.state.data!.tasks
              .where((t) => t.reviewPending || t.qaPending)
              .length,
          2,
        );
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                body: BlocProvider.value(
                  value: cubit,
                  child: ManagerHomeView(now: DateTime(2026, 10, 6)),
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.managerAttendance,
              builder: (_, _) =>
                  const Scaffold(body: Text('Attendance destination')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: EmployeeTheme.from(AppTheme.light()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('مهمة قادمة'), findsOneWidget);
        expect(find.text('مهمة متأخرة'), findsNothing);
        expect(tester.takeException(), isNull);
        final attendance = find.text(
          lang == 'ar' ? 'حضور الفريق' : 'Team attendance',
        );
        await tester.scrollUntilVisible(
          attendance,
          400,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(attendance);
        await tester.pumpAndSettle();
        expect(find.text('Attendance destination'), findsOneWidget);
      });
    }
  }
  testWidgets('Home load failure offers retry without fake totals', (
    tester,
  ) async {
    final repo = HomeRepo()..fail = true;
    final cubit = ManagerTeamCubit(repo);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: const ManagerHomeView(),
          ),
        ),
      ),
    );
    expect(find.text('Could not load your team summary'), findsOneWidget);
    expect(find.text('Pending requests'), findsNothing);
    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Pending requests'), findsOneWidget);
  });
}
