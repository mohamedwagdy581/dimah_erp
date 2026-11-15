import 'dart:io';
import 'dart:ui' as ui;
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/features/manager_team/data/manager_team_repo.dart';
import 'package:erp_sys/features/manager_team/domain/manager_team_data.dart';
import 'package:erp_sys/features/manager_team/view/manager_team_cubit.dart';
import 'package:erp_sys/features/manager_team/view/manager_team_page.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

final fixture = ManagerTeamData(
  members: const [
    TeamMember(id: 'e1', name: 'موظف الاختبار'),
    TeamMember(id: 'e2', name: 'Test member'),
  ],
  tasks: [
    TeamTask({
      'id': 't1',
      'employee_id': 'e1',
      'title': 'مهمة مكتملة',
      'status': 'done',
      'due_date': '2026-01-01',
    }),
    TeamTask({
      'id': 't2',
      'employee_id': 'e1',
      'title': 'مهمة تحتاج مراجعة',
      'status': 'in_progress',
      'employee_review_status': 'pending',
      'priority': 'high',
      'due_date': '2026-01-01',
    }),
  ],
  pendingRequests: 2,
);

class FakeRepo implements ManagerTeamRepo {
  bool fail = false;
  ManagerTeamData data = fixture;
  @override
  Future<ManagerTeamData> load() async {
    if (fail) throw StateError('Unavailable');
    return data;
  }
}

void main() {
  test('Partial task progress is independent from completed-task ratio', () {
    final data = ManagerTeamData(
      tasks: [
        TeamTask({
          'id': 't',
          'employee_id': 'e',
          'status': 'in_progress',
          'progress': 20,
        }),
      ],
    );
    expect(data.completion('e'), 0);
    expect(data.averageProgress('e'), .2);
    expect(TeamTask.taskProgressValue({'progress': 150}), 100);
    expect(TeamTask.taskProgressValue({'progress': -5}), 0);
    expect(TeamTask.taskProgressValue({'progress': 'NaN'}), 0);
    expect(TeamTask.taskProgressValue({'status': 'done', 'progress': 20}), 100);
  });
  test('Completion, due dates and review counts use actual assigned tasks', () {
    expect(fixture.completion('e1'), .5);
    expect(fixture.completion('e2'), 0);
    expect(fixture.overdue(DateTime(2026, 1, 2)).length, 1);
    expect(fixture.overdue(DateTime(2026, 1, 1)), isEmpty);
    expect(fixture.upcoming(DateTime(2026, 1, 1)).length, 1);
    expect(fixture.reviews.length, 1);
  });
  test('Failed loads show failure instead of invented zero data', () async {
    final repo = FakeRepo()..fail = true;
    final cubit = ManagerTeamCubit(repo);
    await cubit.load();
    expect(cubit.state.failed, true);
    expect(cubit.state.data, isNull);
    repo.fail = false;
    await cubit.load();
    expect(cubit.state.data, fixture);
    await cubit.close();
  });
  Future<void> pump(
    WidgetTester tester,
    ManagerTeamCubit cubit,
    double width,
    String lang, {
    GlobalKey? capture,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 1000));
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(lang),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: EmployeeTheme.from(AppTheme.light()),
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: TextScaler.linear(width < 500 ? 1.3 : 1),
              ),
              child: RepaintBoundary(
                key: capture,
                child: ColoredBox(
                  color: EmployeeTheme.from(
                    AppTheme.light(),
                  ).scaffoldBackgroundColor,
                  child: const ManagerTeamView(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('Team layout $width $lang has no overflow', (tester) async {
        final cubit = ManagerTeamCubit(FakeRepo());
        await cubit.load();
        await pump(tester, cubit, width, lang);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await cubit.close();
        await tester.binding.setSurfaceSize(null);
      });
    }
  }
  testWidgets('Manager sees 20 percent and reloads updated progress', (
    tester,
  ) async {
    final repo = FakeRepo();
    ManagerTeamData data(int progress) => ManagerTeamData(
      members: const [TeamMember(id: 'e', name: 'Employee')],
      tasks: [
        TeamTask({
          'id': 't',
          'employee_id': 'e',
          'title': 'Working task',
          'status': 'in_progress',
          'progress': progress,
        }),
      ],
    );
    repo.data = data(20);
    final cubit = ManagerTeamCubit(repo);
    await cubit.load();
    await pump(tester, cubit, 1440, 'ar');
    expect(find.text('20%'), findsOneWidget);
    await tester.tap(find.text('Employee'));
    await tester.pumpAndSettle();
    expect(find.text('قيد التنفيذ • 20%'), findsOneWidget);
    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();
    repo.data = data(40);
    await cubit.load();
    await tester.pumpAndSettle();
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('20%'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('Member search and details reflect actual members and tasks', (
    tester,
  ) async {
    final cubit = ManagerTeamCubit(FakeRepo());
    await cubit.load();
    await pump(tester, cubit, 1440, 'ar');
    await tester.tap(find.byTooltip('بحث في الفريق'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'موظف');
    await tester.pumpAndSettle();
    expect(find.text('Test member'), findsNothing);
    await tester.tap(find.text('موظف الاختبار'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('مهمة مكتملة'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('Desktop team preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_TEAM_PREVIEW')) return;
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
    final cubit = ManagerTeamCubit(FakeRepo());
    await cubit.load();
    final key = GlobalKey();
    await pump(tester, cubit, 1440, 'ar', capture: key);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build').create(recursive: true);
      await File(
        'build/manager_team_preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('Summary actions open their matching task filters', (
    tester,
  ) async {
    final cubit = ManagerTeamCubit(FakeRepo());
    await cubit.load();
    await pump(tester, cubit, 1440, 'ar');
    await tester.tap(find.text('عرض المهام'));
    await tester.pumpAndSettle();
    expect(find.text('مهمة تحتاج مراجعة'), findsOneWidget);
    await tester.ensureVisible(find.text('عرض المراجعات'));
    await tester.tap(find.text('عرض المراجعات'));
    await tester.pumpAndSettle();
    expect(find.text('فتح شاشة المراجعات الحالية'), findsOneWidget);
    expect(find.text('مهمة تحتاج مراجعة'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await tester.binding.setSurfaceSize(null);
  });
}
