import 'dart:io';

import 'dart:ui' as ui;

import 'package:erp_sys/core/session/app_user.dart';
import 'package:erp_sys/core/session/session_cubit.dart';
import 'package:erp_sys/core/session/session_repo.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/core/widgets/app_scaffold.dart';
import 'package:erp_sys/features/dashboard/view/dashboard_page.dart';
import 'package:erp_sys/features/leaves/domain/models/leave_balance.dart';
import 'package:erp_sys/features/shell/view/sections/sidebar_section.dart';
import 'package:erp_sys/features/shell/view/widgets/shell_action_buttons.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
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

const previewData = EmployeeDashboardData(
  employeeName: 'موظف الاختبار',
  annualBalance: LeaveBalance(type: 'annual', entitlement: 21, used: 5),
  pendingRequests: 2,
  inProgressTasks: 3,
  todayTasks: 1,
  pendingTasks: 4,
  reviewPendingTasks: 1,
  dueSoonTasks: 2,
  recentTasks: [
    {
      'title': 'مراجعة تقرير العمل',
      'priority': 'high',
      'status': 'in_progress',
      'due_date': '2026-10-02',
    },
    {
      'title': 'تحديث المستندات',
      'priority': 'medium',
      'status': 'todo',
      'due_date': '2026-10-03',
    },
    {'title': 'إعداد ملخص المهام', 'priority': 'low', 'status': 'todo'},
  ],
  notifications: [
    EmployeeDashboardNotification(
      type: 'review_approved',
      subtitle: 'مراجعة تقرير العمل • 2026-10-01',
      icon: Icons.verified_outlined,
      color: Colors.green,
    ),
    EmployeeDashboardNotification(
      type: 'task_due_soon',
      subtitle: 'تحديث المستندات • 2026-10-03',
      icon: Icons.schedule_outlined,
      color: Colors.orange,
    ),
  ],
);

GoRouter routerFor(
  Widget body, {
  required bool compact,
  GlobalKey? captureKey,
}) => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => RepaintBoundary(
        key: captureKey,
        child: AppScaffold(
          title: AppLocalizations.of(context)!.menuDashboard,
          employeeStyle: true,
          isCollapsed: false,
          onToggle: () {},
          sidebar: SidebarSection(
            isCollapsed: false,
            onToggle: () {},
            role: 'employee',
            email: 'employee@example.test',
            approvalsBadgeCount: 2,
            showToggle: false,
          ),
          actions: buildShellActionButtons(
            showNotifications: true,
            notificationsTooltip: AppLocalizations.of(
              context,
            )!.notificationsTitle,
            notificationCount: 2,
            onNotificationsTap: () => context.go('/notifications'),
            searchTooltip: AppLocalizations.of(context)!.tooltipSearch,
            onSearchTap: () {},
            employeeStyle: true,
            compact: compact,
            profileLabel: AppLocalizations.of(context)!.myProfile,
            onProfileTap: () {},
          ),
          body: body,
        ),
      ),
    ),
    GoRoute(
      path: '/my',
      builder: (context, state) =>
          Scaffold(body: Text('tab:${state.uri.queryParameters['tab']}')),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) =>
          const Scaffold(body: Text('notifications-page')),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const Scaffold(body: Text('profile-page')),
    ),
  ],
);

Widget app(
  GoRouter router, {
  Locale locale = const Locale('ar'),
  bool dark = false,
  double textScale = 1,
}) => MaterialApp.router(
  locale: locale,
  theme: EmployeeTheme.from(dark ? AppTheme.dark() : AppTheme.light()),
  routerConfig: router,
  supportedLocales: const [Locale('ar'), Locale('en')],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
);

class _EmployeeSessionRepo implements SessionRepo {
  @override
  Future<AppUser?> getCurrentAppUser() async => const AppUser(
    id: 'test',
    email: 'employee@example.test',
    role: 'employee',
    tenantId: 'tenant',
    employeeId: 'employee',
  );
}

void main() {
  for (final width in [320.0, 768.0, 1440.0]) {
    for (final language in ['ar', 'en']) {
      testWidgets('Employee layout $width $language has no overflow', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final router = routerFor(
          EmployeeDashboardView(data: previewData, onRefresh: () {}),
          compact: width < 900,
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          app(
            router,
            locale: Locale(language),
            dark: language == 'en',
            textScale: width == 320 ? 1.3 : 1,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('16'), findsOneWidget);
        expect(find.text('موظف الاختبار', findRichText: true), findsNothing);
        expect(find.textContaining('موظف الاختبار'), findsOneWidget);
        final direction = Directionality.of(
          tester.element(find.byType(EmployeeDashboardView)),
        );
        expect(
          direction,
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        await tester.drag(find.byType(ListView).last, const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Summary actions open the existing employee tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final action in {
      'عرض التفاصيل': 'requests',
      'عرض الطلبات': 'requests',
      'متابعة العمل': 'tasks',
      'عرض المهام': 'tasks',
    }.entries) {
      final router = routerFor(
        EmployeeDashboardView(data: previewData, onRefresh: () {}),
        compact: false,
      );
      await tester.pumpWidget(app(router));
      await tester.pumpAndSettle();
      await tester.tap(find.text(action.key));
      await tester.pumpAndSettle();
      expect(find.text('tab:${action.value}'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    }
  });

  testWidgets('Empty data shows empty states and an unavailable balance', (
    tester,
  ) async {
    final router = routerFor(
      EmployeeDashboardView(
        data: const EmployeeDashboardData(),
        onRefresh: () {},
      ),
      compact: true,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(app(router));
    await tester.pumpAndSettle();
    expect(find.text('الرصيد غير متاح'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Failed dashboard load offers retry instead of zero statistics', (
    tester,
  ) async {
    final cubit = SessionCubit(_EmployeeSessionRepo());
    await cubit.load();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: DashboardPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('تعذّر تحميل البيانات'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    await tester.ensureVisible(find.text('إعادة المحاولة'));
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('تعذّر تحميل البيانات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Desktop Arabic preview', (tester) async {
    await tester.runAsync(() async {
      if (const bool.fromEnvironment('EXPORT_EMPLOYEE_PREVIEW')) {
        for (final family in ['Roboto', 'serif']) {
          final loader = FontLoader(family);
          final font = await File('C:/Windows/Fonts/segoeui.ttf').readAsBytes();
          loader.addFont(Future.value(ByteData.sublistView(font)));
          await loader.load();
        }
        final icons = FontLoader('MaterialIcons');
        final iconBytes = await File(
          'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ).readAsBytes();
        icons.addFont(Future.value(ByteData.sublistView(iconBytes)));
        await icons.load();
      }
    });

    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    final router = routerFor(
      EmployeeDashboardView(data: previewData, onRefresh: () {}),
      compact: false,
      captureKey: key,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(app(router));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('EXPORT_EMPLOYEE_PREVIEW')) {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build').create(recursive: true);
        await File(
          'build/employee_dashboard_preview.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
