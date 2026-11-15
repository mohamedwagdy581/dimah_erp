import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp_sys/core/session/session_cubit.dart';
import 'package:erp_sys/core/session/session_repo.dart';
import 'package:erp_sys/core/session/app_user.dart';
import 'package:erp_sys/features/approvals/domain/repos/approvals_repo.dart';
import 'package:erp_sys/features/approvals/view/cubit/approvals_cubit.dart';
import 'package:erp_sys/features/approvals/view/sections/approvals_table_section.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/features/approvals/domain/models/approval_request.dart';
import 'package:erp_sys/features/approvals/view/widgets/approvals_table.dart';
import 'package:erp_sys/l10n/app_localizations.dart';

final approvals = List.generate(
  35,
  (i) => ApprovalRequest(
    id: '$i',
    tenantId: 'tenant',
    requestType: i == 1 ? 'attendance_correction' : 'payroll_run',
    employeeId: 'employee-$i',
    employeeName:
        'Employee $i — اسم الموظف بالكامل مع بيانات إضافية طويلة لاختبار عرض النص',
    status: 'pending',
    currentApproverRole: 'finance_manager',
    createdAt: DateTime(2026, 10, 11),
  ),
);

class _SessionRepo implements SessionRepo {
  @override
  Future<AppUser?> getCurrentAppUser() async => const AppUser(
    id: 'finance',
    email: 'finance@example.test',
    role: 'finance_manager',
    tenantId: 'tenant',
    employeeId: null,
  );
}

class _ApprovalsRepo implements ApprovalsRepo {
  final types = <String?>[];
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
    types.add(requestType);
    final rows = approvals
        .where((r) => requestType == null || r.requestType == requestType)
        .toList();
    return (items: rows.take(pageSize).toList(), total: rows.length);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Finance approvals design preview', (tester) async {
    if (const bool.fromEnvironment('EXPORT_FINANCE_APPROVALS')) {
      await tester.runAsync(() async {
        final font = FontLoader('Roboto')
          ..addFont(
            Future.value(
              ByteData.sublistView(
                await File(
                  'assets/fonts/DINNextLTArabic-Regular-2.ttf',
                ).readAsBytes(),
              ),
            ),
          );
        await font.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(
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
    }
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = ApprovalsCubit(_ApprovalsRepo());
    final session = SessionCubit(_SessionRepo());
    await cubit.load();
    await session.load();
    addTearDown(cubit.close);
    addTearDown(session.close);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: EmployeeTheme.from(AppTheme.light()),
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider.value(value: session),
          ],
          child: const RepaintBoundary(
            key: ValueKey('finance-preview'),
            child: Scaffold(body: ApprovalsTableSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('EXPORT_FINANCE_APPROVALS')) {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('finance-preview')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/finance_approvals_preview.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
  testWidgets(
    'Short finance workspace scrolls filters and pagination and filters payroll',
    (tester) async {
      tester.view.physicalSize = const Size(320, 380);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _ApprovalsRepo();
      final cubit = ApprovalsCubit(repo);
      final session = SessionCubit(_SessionRepo());
      await cubit.load();
      await session.load();
      addTearDown(cubit.close);
      addTearDown(session.close);
      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cubit),
              BlocProvider.value(value: session),
            ],
            child: const Scaffold(body: ApprovalsTableSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final filter = find.byType(DropdownButtonFormField<String?>).at(1);
      await tester.ensureVisible(filter);
      await tester.tap(filter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Payroll').last);
      await tester.pumpAndSettle();
      expect(repo.types.last, 'payroll_run');
      final pageSize = find.byType(DropdownButton<int>);
      await tester.ensureVisible(pageSize);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets(
        'Finance approvals $lang $width scrolls to actions and last row',
        (tester) async {
          tester.view.physicalSize = Size(width, 600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          String? approved;
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(lang),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: EmployeeTheme.from(AppTheme.light()),
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.3)),
                  child: Scaffold(
                    body: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ApprovalsTable(
                        items: approvals,
                        actorRole: 'finance_manager',
                        onApprove: (id) => approved = id,
                        onReject: (_) {},
                        onViewDetails: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final horizontal = tester
              .widget<SingleChildScrollView>(
                find.byKey(const ValueKey('approvals-horizontal-scroll')),
              )
              .controller!;
          final vertical = tester
              .widget<SingleChildScrollView>(
                find.byKey(const ValueKey('approvals-vertical-scroll')),
              )
              .controller!;
          if (width < 1440) {
            expect(horizontal.position.maxScrollExtent, greaterThan(0));
          }
          expect(vertical.position.maxScrollExtent, greaterThan(0));
          expect(
            tester
                .widgetList<Scrollbar>(find.byType(Scrollbar))
                .every(
                  (s) => s.thumbVisibility == true && s.interactive == true,
                ),
            isTrue,
          );
          horizontal.jumpTo(horizontal.position.maxScrollExtent);
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(lang == 'ar' ? 'موافقة' : 'Approve').first,
          );
          await tester.pumpAndSettle();
          expect(approved, '0');
          vertical.jumpTo(vertical.position.maxScrollExtent);
          await tester.pumpAndSettle();
          await tester.tap(find.text(lang == 'ar' ? 'موافقة' : 'Approve').last);
          expect(approved, '34');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'Pending requests for another role do not expose decision buttons',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ApprovalsTable(
              items: approvals.take(1).toList(),
              actorRole: 'manager',
              onApprove: (_) => fail('Unauthorized approve'),
              onReject: (_) => fail('Unauthorized reject'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
      expect(find.text('Finance manager'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
