import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_sys/core/ui/admin_theme.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/leaves/domain/models/leave_request.dart';
import 'package:erp_sys/features/leaves/domain/repos/leaves_repo.dart';
import 'package:erp_sys/features/leaves/view/cubit/leaves_cubit.dart';
import 'package:erp_sys/features/leaves/view/widgets/admin_leaves_workspace.dart';
import 'package:erp_sys/features/accounting/view/accounting_ui.dart';

class AdminLeaveRepo implements LeavesRepo {
  bool fail = false;
  String? statusFilter;
  int calls = 0;
  @override
  Future<({List<LeaveRequest> items, int total})> fetchLeaves({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String sortBy = 'start_date',
    bool ascending = false,
  }) async {
    calls++;
    statusFilter = status;
    if (fail) throw StateError('offline');
    final items = [
      for (var i = 0; i < 20; i++)
        LeaveRequest(
          id: '$i',
          tenantId: 'tenant',
          employeeId: 'e$i',
          employeeName: 'الموظف $i',
          type: 'annual',
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 10, 3),
          status: i.isEven ? 'pending' : 'approved',
          createdAt: DateTime(2026, 10),
          notes: 'ملاحظات الإجازة كاملة دون قطع النص',
        ),
    ].where((r) => status == null || r.status == status).toList();
    return (items: items.take(pageSize).toList(), total: items.length);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<GoRouter> mount(
  WidgetTester tester,
  LeavesCubit cubit,
  String lang, {
  GlobalKey? preview,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: AdminLeavesWorkspace()),
      ),
      GoRoute(
        path: '/approvals',
        builder: (_, _) => const Scaffold(body: Text('Approvals destination')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    RepaintBoundary(
      key: preview,
      child: BlocProvider.value(
        value: cubit,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          locale: Locale(lang),
          theme: AdminTheme.from(AppTheme.light()),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.2)),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets(
        'Admin leave $lang $width has scrollable data and approval navigation',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final cubit = LeavesCubit(AdminLeaveRepo());
          addTearDown(cubit.close);
          await cubit.load();
          final router = await mount(tester, cubit, lang);
          expect(tester.takeException(), isNull);
          expect(find.byType(AccountingTable), findsOneWidget);
          await tester.ensureVisible(
            find.byKey(const ValueKey('leave-open-approvals')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('leave-open-approvals')));
          await tester.pumpAndSettle();
          expect(router.routeInformationProvider.value.uri.path, '/approvals');
          expect(find.text('Approvals destination'), findsOneWidget);
        },
      );
    }
  }
  testWidgets(
    'Admin leave filters request the selected status and errors can retry',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = AdminLeaveRepo();
      final cubit = LeavesCubit(repo);
      addTearDown(cubit.close);
      await cubit.load();
      await mount(tester, cubit, 'en');
      await tester.tap(find.byKey(const ValueKey('leave-status-null')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approved').last);
      await tester.pumpAndSettle();
      expect(repo.statusFilter, 'approved');
      expect(cubit.state.items.every((r) => r.status == 'approved'), isTrue);
      repo.fail = true;
      await cubit.load();
      await tester.pumpAndSettle();
      expect(cubit.state.error, isNotNull);
      repo.fail = false;
      await cubit.load();
      await tester.pumpAndSettle();
      expect(cubit.state.error, isNull);
      expect(find.byType(AccountingTable), findsOneWidget);
    },
  );
  testWidgets('Admin leave preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_ADMIN_LEAVES_PREVIEW')) return;
    await tester.runAsync(() async {
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
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cubit = LeavesCubit(AdminLeaveRepo());
    addTearDown(cubit.close);
    await cubit.load();
    final key = GlobalKey();
    await mount(tester, cubit, 'ar', preview: key);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final picture =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/admin_leaves_preview.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  });
}
