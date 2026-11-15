import 'dart:io';
import 'dart:ui' as ui;

import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/core/widgets/app_scaffold.dart';
import 'package:erp_sys/features/employee_portal/data/repos/my_tasks_repo.dart';
import 'package:erp_sys/features/employee_portal/view/sections/my_tasks_section.dart';
import 'package:erp_sys/features/employee_portal/view/widgets/my_tasks/employee_tasks_view.dart';
import 'package:erp_sys/features/employee_portal/view/widgets/my_tasks/employee_task_details.dart';
import 'package:erp_sys/features/employee_portal/view/widgets/my_tasks/task_filters_utils.dart';
import 'package:erp_sys/features/employee_portal/view/widgets/my_tasks/task_formatters.dart';
import 'package:erp_sys/features/shell/view/sections/sidebar_section.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Fixtures exist only in tests and never seed the app or database.
final tasks = <Map<String, dynamic>>[
  {
    'id': 'a',
    'title': 'مراجعة ملف العمل',
    'description': 'Review notes',
    'task_type': 'report',
    'priority': 'high',
    'status': 'in_progress',
    'progress': 30,
    'due_date': '2026-10-08',
    'logged_hours': 2.333333,
  },
  {
    'id': 'b',
    'title': 'تحديث المستندات',
    'task_type': 'employee_docs',
    'priority': 'medium',
    'status': 'todo',
    'progress': 0,
    'due_date': '2026-10-09',
    'logged_hours': 0,
  },
  {
    'id': 'c',
    'title': 'تقرير المتابعة',
    'task_type': 'report',
    'priority': 'low',
    'status': 'done',
    'employee_review_status': 'pending',
    'qa_status': 'pending',
    'progress': 100,
    'logged_hours': 1,
  },
];

Widget app(Widget body, {String language = 'ar'}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  theme: EmployeeTheme.from(AppTheme.light()),
  home: Scaffold(body: body),
);

Widget detailsPreview({VoidCallback? onAttach, ValueChanged<String>? onOpen}) =>
    EmployeeTaskDetails(
      task: {
        ...tasks.first,
        'description':
            'مراجعة المستندات وإعداد التقرير النهائي وتسليمه للمراجعة.',
        'estimate_hours': 6,
        'created_at': '2026-10-04T09:30:00Z',
        'assignee_started_at': '2026-10-04T14:20:00Z',
        'updated_at': '2026-10-04T14:20:00Z',
        'attachments': [
          {
            'id': 'file-a',
            'file_name': 'مستندات العمل.pdf',
            'mime_type': 'application/pdf',
            'file_url': 'https://example.test/document.pdf',
            'created_at': '2026-10-04T09:30:00Z',
          },
        ],
      },
      busy: false,
      onBack: () {},
      onStatusChanged: (_) {},
      onProgressChanged: (_) {},
      onRequestReview: () {},
      onAttachFile: onAttach ?? () {},
      onLogHours: () {},
      onStartTimer: () {},
      onStopTimer: () {},
      onOpenAttachment: onOpen ?? (_) {},
    );

class _Repo extends MyTasksRepo {
  _Repo()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  List<Map<String, dynamic>> records = [Map.of(tasks.first)];
  int timerStarts = 0;
  @override
  Future<List<Map<String, dynamic>>> loadTasks(
    String employeeId, {
    bool loadAll = false,
  }) async => records.map(Map<String, dynamic>.of).toList();
  @override
  Future<void> startTimer({required String taskId}) async {
    timerStarts++;
    records.first['active_timer_started_at'] = '2026-10-04T10:00:00Z';
  }
}

void main() {
  for (final width in [320.0, 768.0, 1024.0, 1440.0]) {
    for (final language in ['ar', 'en']) {
      testWidgets('Task details $width $language have no overflow', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(app(detailsPreview(), language: language));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(tasks.first['title']), findsOneWidget);
        expect(find.text('2025/09/18'), findsNothing);
      });
    }
  }
  testWidgets('Details use actual attachment URL and upload action', (
    tester,
  ) async {
    var uploads = 0;
    String? opened;
    await tester.pumpWidget(
      app(
        detailsPreview(
          onAttach: () => uploads++,
          onOpen: (url) => opened = url,
        ),
      ),
    );
    final file = find.byKey(const ValueKey('task-attachment-file-a'));
    await tester.ensureVisible(file);
    await tester.pumpAndSettle();
    await tester.tap(file);
    expect(opened, 'https://example.test/document.pdf');
    final upload = find.byKey(const ValueKey('task-upload-attachment'));
    await tester.ensureVisible(upload);
    await tester.pumpAndSettle();
    await tester.tap(upload);
    expect(uploads, 1);
  });
  for (final language in ['ar', 'en']) {
    testWidgets('Task details with large text $language fit a phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: detailsPreview(),
            ),
          ),
          language: language,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  test('Search, status and task type combine without mutating the source', () {
    expect(
      filterEmployeeTasks(
        tasks,
        search: ' Review ',
        type: 'report',
        status: 'in_progress',
      ).single['id'],
      'a',
    );
    expect(filterEmployeeTasks(tasks, status: 'qa_pending').single['id'], 'c');
    final reversed = tasks.reversed.toList();
    expect(
      filterEmployeeTasks(reversed, sort: 'due').map((task) => task['id']),
      ['a', 'b', 'c'],
    );
    expect(
      filterEmployeeTasks(reversed, sort: 'priority').map((task) => task['id']),
      ['a', 'b', 'c'],
    );
    expect(reversed.map((task) => task['id']), ['c', 'b', 'a']);
  });
  test(
    'Logged hours use valid hours and minutes without showing invalid numbers',
    () {
      expect(taskLoggedTime(2.333333, arabic: true), '2 س 20 د');
      expect(taskLoggedTime(1.999, arabic: false), '2h 0m');
      expect(taskLoggedTime(null, arabic: true), '—');
      expect(taskLoggedTime(double.nan, arabic: false), '—');
    },
  );
  for (final width in [320.0, 768.0, 1024.0, 1440.0]) {
    for (final language in ['ar', 'en']) {
      testWidgets('Tasks layout $width $language has no overflow', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          app(
            EmployeeTasksView(tasks: tasks, onOpen: (_) {}, onRefresh: () {}),
            language: language,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(tasks.first['title']), findsOneWidget);
      });
    }
  }
  for (final language in ['ar', 'en']) {
    testWidgets('Tasks with enlarged text $language have no overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: EmployeeTasksView(
                tasks: tasks,
                onOpen: (_) {},
                onRefresh: () {},
              ),
            ),
          ),
          language: language,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(tasks.first['title']), findsOneWidget);
    });
  }
  testWidgets(
    'Status filter, search, reset and details select the actual task',
    (tester) async {
      Map<String, dynamic>? selected;
      await tester.pumpWidget(
        app(
          EmployeeTasksView(
            tasks: tasks,
            onOpen: (task) => selected = task,
            onRefresh: () {},
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('task-filter-todo')));
      await tester.pumpAndSettle();
      expect(find.text(tasks.first['title']), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('employee-task-search')),
        'missing',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('مسح الفلاتر'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('مسح الفلاتر'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('employee-task-search')),
            )
            .controller!
            .text,
        isEmpty,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('task-details-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-details-a')));
      expect(selected!['id'], 'a');
    },
  );
  testWidgets('Failed load offers retry and does not present zero counts', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      app(
        EmployeeTasksView(
          tasks: const [],
          failed: true,
          onOpen: (_) {},
          onRefresh: () => retries++,
        ),
      ),
    );
    expect(find.text('0'), findsNothing);
    await tester.ensureVisible(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إعادة المحاولة'));
    expect(retries, 1);
  });
  for (final detailsWidth in [320.0, 1200.0]) {
    testWidgets('Existing timer updates open details at $detailsWidth', (
      tester,
    ) async {
      tester.view.physicalSize = Size(detailsWidth, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _Repo();
      await tester.pumpWidget(
        app(
          MyTasksSection(
            employeeId: 'employee',
            employeeDesign: true,
            repo: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('employee-task-search')),
        'مراجعة',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('task-details-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-details-a')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('بدء المؤقت'));
      await tester.tap(find.text('بدء المؤقت'));
      await tester.pumpAndSettle();
      expect(repo.timerStarts, 1);
      expect(find.text('إيقاف المؤقت'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('العودة إلى المهام'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('العودة إلى المهام'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('employee-task-search')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('employee-task-search')),
            )
            .controller!
            .text,
        'مراجعة',
      );
    });
  }
  testWidgets('Arabic desktop preview', (tester) async {
    const exportDetails = bool.fromEnvironment('EXPORT_TASK_DETAILS_PREVIEW');
    if (!const bool.fromEnvironment('EXPORT_TASKS_PREVIEW') && !exportDetails) {
      return;
    }
    await tester.runAsync(() async {
      final font = FontLoader('Roboto');
      font.addFont(
        Future.value(
          ByteData.sublistView(
            await File('C:/Windows/Fonts/segoeui.ttf').readAsBytes(),
          ),
        ),
      );
      await font.load();
      final serif = FontLoader('serif');
      serif.addFont(
        Future.value(
          ByteData.sublistView(
            await File('C:/Windows/Fonts/times.ttf').readAsBytes(),
          ),
        ),
      );
      await serif.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(
        Future.value(
          ByteData.sublistView(
            await File(
              'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
            ).readAsBytes(),
          ),
        ),
      );
      await icons.load();
    });
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    final router = GoRouter(
      initialLocation: '/my?tab=tasks',
      routes: [
        GoRoute(
          path: '/my',
          builder: (context, state) => RepaintBoundary(
            key: key,
            child: AppScaffold(
              title: AppLocalizations.of(context)!.myTasks,
              employeeStyle: true,
              isCollapsed: false,
              onToggle: () {},
              sidebar: SidebarSection(
                isCollapsed: false,
                onToggle: () {},
                role: 'employee',
                email: 'fixture@example.test',
              ),
              body: exportDetails
                  ? detailsPreview()
                  : EmployeeTasksView(
                      tasks: tasks,
                      onOpen: (_) {},
                      onRefresh: () {},
                    ),
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
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: EmployeeTheme.from(AppTheme.light()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        exportDetails
            ? 'build/employee_task_details_preview.png'
            : 'build/employee_tasks_preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
