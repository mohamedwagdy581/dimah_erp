import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/di/app_di.dart';
import 'package:erp_sys/core/session/session_cubit.dart';
import 'package:erp_sys/core/session/session_repo.dart';
import 'package:erp_sys/core/session/app_user.dart';
import 'package:erp_sys/features/employee_portal/view/pages/employee_portal_page.dart';
import 'package:erp_sys/features/employee_portal/data/repos/employee_leave_attachment.dart';
import 'package:erp_sys/features/approvals/domain/repos/approvals_repo.dart';
import 'package:erp_sys/features/approvals/domain/models/approval_request.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/core/widgets/app_scaffold.dart';
import 'package:erp_sys/features/employee_portal/view/cubit/employee_leave_request_cubit.dart';
import 'package:erp_sys/features/employee_portal/view/widgets/employee_requests/employee_leave_request_view.dart';
import 'package:erp_sys/features/employee_portal/view/widgets/employee_requests/employee_leave_balances.dart';
import 'package:erp_sys/features/leaves/domain/models/leave_balance.dart';
import 'package:erp_sys/features/leaves/domain/repos/leaves_repo.dart';
import 'package:erp_sys/features/shell/view/sections/sidebar_section.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Repo extends Fake implements LeavesRepo {
  List<LeaveBalance> balances = const [
    LeaveBalance(type: 'annual', entitlement: 21, used: 4),
    LeaveBalance(type: 'sick', entitlement: 10, used: 1),
  ];
  bool balanceFails = false;
  bool createFails = false;
  Completer<void>? gate;
  int creates = 0;
  int? year;
  String? employee;
  String? type;
  String? reason;
  String? fileUrl;
  DateTime? start;
  DateTime? end;
  @override
  Future<List<LeaveBalance>> fetchLeaveBalances({
    required String employeeId,
    int? year,
  }) async {
    employee = employeeId;
    this.year = year;
    if (balanceFails) throw StateError('Balance unavailable');
    return balances;
  }

  @override
  Future<void> createLeave({
    required String employeeId,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String? fileUrl,
    String? notes,
  }) async {
    creates++;
    employee = employeeId;
    this.type = type;
    reason = notes;
    this.fileUrl = fileUrl;
    start = startDate;
    end = endDate;
    if (gate != null) await gate!.future;
    if (createFails) throw StateError('Save failed');
  }
}

class _SessionRepo extends Fake implements SessionRepo {
  @override
  Future<AppUser?> getCurrentAppUser() async => const AppUser(
    id: 'auth-id',
    email: 'fixture@example.test',
    role: 'employee',
    tenantId: 'tenant',
    employeeId: 'real-employee-id',
  );
}

class _ApprovalsRepo extends Fake implements ApprovalsRepo {
  String? employee;
  @override
  Future<({List<ApprovalRequest> items, int total})> fetchApprovals({
    required int page,
    required int pageSize,
    String? status,
    String? requestType,
    String? employeeId,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    employee = employeeId;
    return (items: <ApprovalRequest>[], total: 0);
  }
}

EmployeeLeaveRequestCubit cubit(
  LeavesRepo repo, {
  LeaveAttachmentUploader? uploader,
}) => EmployeeLeaveRequestCubit(
  repo,
  employeeId: 'real-employee-id',
  uploadAttachment:
      uploader ?? (_, _) async => 'https://example.test/leave.pdf',
);

Widget app(
  EmployeeLeaveRequestCubit controller, {
  String language = 'ar',
  double scale = 1,
  Widget? child,
}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  theme: EmployeeTheme.from(AppTheme.light()),
  home: Scaffold(
    body: BlocProvider.value(
      value: controller,
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? EmployeeLeaveRequestView(onHistory: () {}),
        ),
      ),
    ),
  ),
);

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('Balances fit $language at $width with large text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = _Repo();
        final controller = cubit(repo);
        addTearDown(controller.close);
        await controller.loadBalance(year: 2027);
        await tester.pumpWidget(
          app(
            controller,
            language: language,
            scale: 1.5,
            child: const SingleChildScrollView(child: EmployeeLeaveBalances()),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('leave-remaining-annual')),
          findsOneWidget,
        );
        expect(repo.employee, 'real-employee-id');
        expect(find.textContaining('2027'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'Balance refresh keeps year and updates actual remaining values',
    (tester) async {
      final repo = _Repo();
      final controller = cubit(repo);
      addTearDown(controller.close);
      await controller.loadBalance(year: 2027);
      await tester.pumpWidget(
        app(controller, language: 'en', child: const EmployeeLeaveBalances()),
      );
      await tester.pumpAndSettle();
      expect(find.text('17 days remaining'), findsOneWidget);
      repo.balances = const [
        LeaveBalance(type: 'annual', entitlement: 21, used: 22),
      ];
      await tester.tap(find.byKey(const ValueKey('leave-balance-refresh')));
      await tester.pumpAndSettle();
      expect(repo.year, 2027);
      expect(find.text('-1 days remaining'), findsOneWidget);
      expect(find.byKey(const ValueKey('leave-balance-sick')), findsNothing);
    },
  );
  testWidgets(
    'Missing and failed balances never show invented zeroes; retry works',
    (tester) async {
      final repo = _Repo()..balances = [];
      final controller = cubit(repo);
      addTearDown(controller.close);
      await controller.loadBalance();
      await tester.pumpWidget(
        app(controller, language: 'en', child: const EmployeeLeaveBalances()),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('No leave balance'), findsOneWidget);
      repo.balanceFails = true;
      await tester.tap(find.byKey(const ValueKey('leave-balance-refresh')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Unable to load balances'), findsOneWidget);
      expect(find.byKey(const ValueKey('leave-balance-annual')), findsNothing);
      repo.balanceFails = false;
      repo.balances = const [
        LeaveBalance(type: 'annual', entitlement: 21, used: 4),
      ];
      await tester.tap(find.byKey(const ValueKey('leave-balance-refresh')));
      await tester.pumpAndSettle();
      expect(find.text('17 days remaining'), findsOneWidget);
    },
  );
  test(
    'Attachment validation rejects wrong type or oversize before contacting Supabase',
    () async {
      await expectLater(
        uploadEmployeeLeaveAttachment(
          XFile.fromData(Uint8List.fromList([1]), name: 'image.jpg'),
          'employee',
        ),
        throwsArgumentError,
      );
      await expectLater(
        uploadEmployeeLeaveAttachment(
          XFile.fromData(Uint8List(10 * 1024 * 1024 + 1), name: 'large.pdf'),
          'employee',
        ),
        throwsArgumentError,
      );
    },
  );
  test('Upload failure does not create a leave and supports retry', () async {
    final repo = _Repo();
    var attempts = 0;
    final controller = cubit(
      repo,
      uploader: (_, _) async {
        if (++attempts == 1) throw StateError('Upload failed');
        return 'https://example.test/proof.pdf';
      },
    );
    addTearDown(controller.close);
    final file = XFile.fromData(Uint8List.fromList([1]), name: 'proof.pdf');
    Future<void> submit() => controller.submit(
      type: 'sick',
      start: DateTime(2026, 10, 4),
      end: DateTime(2026, 10, 5),
      notes: 'reason',
      attachment: file,
    );
    await submit();
    expect(repo.creates, 0);
    expect(controller.state.submitError, isNotNull);
    await submit();
    expect(repo.creates, 1);
    expect(controller.state.submitted, isTrue);
  });
  testWidgets(
    'Employee requests route keeps draft and scopes read-only history',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      AppDI.leavesRepo = _Repo();
      final approvals = _ApprovalsRepo();
      AppDI.approvalsRepo = approvals;
      final session = SessionCubit(_SessionRepo());
      addTearDown(session.close);
      await session.load();
      final router = GoRouter(
        initialLocation: '/my?tab=requests',
        routes: [
          GoRoute(
            path: '/my',
            builder: (_, _) => const Scaffold(body: EmployeePortalPage()),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        BlocProvider.value(
          value: session,
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: EmployeeTheme.from(AppTheme.light()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Leave request'), findsOneWidget);
      expect(find.byType(EmployeeLeaveBalances), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('employee-leave-reason')),
        'Saved draft',
      );
      await tester.tap(find.text('Request history'));
      await tester.pumpAndSettle();
      expect(approvals.employee, 'real-employee-id');
      expect(find.byType(EmployeeLeaveBalances), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('employee-request-back-to-form')),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('employee-leave-reason')),
            )
            .controller!
            .text,
        'Saved draft',
      );
      expect(tester.takeException(), isNull);
      router.go('/my?tab=leaves');
      await tester.pumpAndSettle();
      expect(find.text('Leave request'), findsOneWidget);
      expect(find.byType(TabBar), findsNothing);
    },
  );
  test('Duration includes start and end, including year boundaries', () {
    expect(leaveRequestDays(DateTime(2026, 12, 31), DateTime(2027, 1, 2)), 3);
    expect(leaveRequestDays(DateTime(2026, 10, 4), DateTime(2026, 10, 4)), 1);
  });
  test(
    'Submission uses scoped employee and blocks concurrent or repeated save',
    () async {
      final repo = _Repo()..gate = Completer<void>();
      final controller = cubit(repo);
      addTearDown(controller.close);
      await controller.loadBalance(year: 2027);
      expect(repo.employee, 'real-employee-id');
      expect(repo.year, 2027);
      Future<void> submit() => controller.submit(
        type: 'sick',
        start: DateTime(2027, 1, 2),
        end: DateTime(2027, 1, 3),
        notes: '  actual reason  ',
      );
      final saving = submit();
      await submit();
      expect(repo.creates, 1);
      repo.gate!.complete();
      await saving;
      await submit();
      expect(repo.creates, 1);
      expect(repo.type, 'sick');
      expect(repo.reason, 'actual reason');
      expect(repo.start, DateTime(2027, 1, 2));
      expect(repo.end, DateTime(2027, 1, 3));
      expect(controller.state.submitted, isTrue);
    },
  );
  test('Saved request stays successful if balance refresh fails', () async {
    final repo = _Repo()..balanceFails = true;
    final controller = cubit(repo);
    addTearDown(controller.close);
    await controller.submit(
      type: 'annual',
      start: DateTime(2026, 10, 4),
      end: DateTime(2026, 10, 5),
      notes: 'reason',
    );
    expect(controller.state.submitted, isTrue);
    expect(controller.state.submitError, isNull);
    expect(controller.state.balanceError, isNotNull);
    expect(repo.creates, 1);
  });
  test(
    'Failed save retries existing uploaded attachment without uploading twice',
    () async {
      final repo = _Repo()..createFails = true;
      var uploads = 0;
      final controller = cubit(
        repo,
        uploader: (_, employee) async {
          expect(employee, 'real-employee-id');
          uploads++;
          return 'https://example.test/actual.pdf';
        },
      );
      addTearDown(controller.close);
      final file = XFile.fromData(
        Uint8List.fromList([1, 2]),
        name: 'proof.pdf',
      );
      Future<void> submit() => controller.submit(
        type: 'annual',
        start: DateTime(2026, 10, 4),
        end: DateTime(2026, 10, 5),
        notes: 'reason',
        attachment: file,
      );
      await submit();
      expect(controller.state.submitError, isNotNull);
      repo.createFails = false;
      await submit();
      expect(uploads, 1);
      expect(repo.fileUrl, 'https://example.test/actual.pdf');
      expect(controller.state.submitted, isTrue);
    },
  );
  test('Invalid date order never creates a request', () async {
    final repo = _Repo();
    final controller = cubit(repo);
    addTearDown(controller.close);
    await controller.submit(
      type: 'annual',
      start: DateTime(2026, 10, 5),
      end: DateTime(2026, 10, 4),
      notes: 'reason',
    );
    expect(repo.creates, 0);
    expect(controller.state.submitError, isNotNull);
  });
  for (final width in [320.0, 768.0, 1024.0, 1440.0]) {
    for (final language in ['ar', 'en']) {
      testWidgets('Leave form $width $language has no overflow', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = cubit(_Repo());
        addTearDown(controller.close);
        await controller.loadBalance();
        await tester.pumpWidget(app(controller, language: language));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('17'), findsOneWidget);
        expect(find.text('18'), findsNothing);
      });
    }
  }
  for (final language in ['ar', 'en']) {
    testWidgets('Phone leave form with large text $language has no overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = cubit(_Repo());
      addTearDown(controller.close);
      await controller.loadBalance();
      await tester.pumpWidget(app(controller, language: language, scale: 1.5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Missing dates and reason prevent submit', (tester) async {
    final repo = _Repo();
    final controller = cubit(repo);
    addTearDown(controller.close);
    await controller.loadBalance();
    await tester.pumpWidget(app(controller, language: 'en'));
    final button = find.byKey(const ValueKey('employee-leave-submit'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(repo.creates, 0);
    expect(find.text('Select a date'), findsNWidgets(2));
    expect(find.text('Enter a reason for your leave'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Date selection and reason submit actual request and show success',
    (tester) async {
      final repo = _Repo();
      final controller = cubit(repo);
      addTearDown(controller.close);
      await controller.loadBalance();
      await tester.pumpWidget(app(controller, language: 'en'));
      for (final date in ['start', 'end']) {
        final field = find.byKey(ValueKey('leave-$date-null'));
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.tap(field);
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }
      await tester.enterText(
        find.byKey(const ValueKey('employee-leave-reason')),
        'Family appointment',
      );
      final button = find.byKey(const ValueKey('employee-leave-submit'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(repo.creates, 1);
      expect(repo.reason, 'Family appointment');
      expect(repo.employee, 'real-employee-id');
      expect(find.text('Leave request submitted for review'), findsOneWidget);
    },
  );
  testWidgets('Balance failure shows unavailable balance and retry', (
    tester,
  ) async {
    final controller = cubit(_Repo()..balanceFails = true);
    addTearDown(controller.close);
    await controller.loadBalance();
    await tester.pumpWidget(app(controller, language: 'en'));
    expect(find.text('Balance unavailable'), findsOneWidget);
    expect(find.text('17'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });
  testWidgets('Desktop request form preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_REQUESTS_PREVIEW')) return;
    await tester.runAsync(() async {
      for (final entry in {
        'Roboto': 'C:/Windows/Fonts/segoeui.ttf',
        'serif': 'C:/Windows/Fonts/times.ttf',
        'MaterialIcons':
            'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      }.entries) {
        final loader = FontLoader(entry.key)
          ..addFont(
            Future.value(
              ByteData.sublistView(await File(entry.value).readAsBytes()),
            ),
          );
        await loader.load();
      }
    });
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = cubit(_Repo());
    addTearDown(controller.close);
    await controller.loadBalance();
    final key = GlobalKey();
    final router = GoRouter(
      initialLocation: '/my?tab=requests',
      routes: [
        GoRoute(
          path: '/my',
          builder: (context, state) => RepaintBoundary(
            key: key,
            child: AppScaffold(
              title: AppLocalizations.of(context)!.myRequests,
              employeeStyle: true,
              isCollapsed: false,
              onToggle: () {},
              sidebar: SidebarSection(
                isCollapsed: false,
                onToggle: () {},
                role: 'employee',
                email: 'fixture@example.test',
              ),
              body: BlocProvider.value(
                value: controller,
                child: EmployeeLeaveRequestView(
                  onHistory: () {},
                  showBalanceSummary: true,
                ),
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
      final preview = await boundary.toImage();
      final bytes = await preview.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/employee_requests_preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      preview.dispose();
    });
  });
}
