import 'dart:io';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/session/app_user.dart';
import 'package:erp_sys/core/session/session_repo.dart';
import 'package:erp_sys/core/session/session_cubit.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/payroll/domain/models/payroll_run.dart';
import 'package:erp_sys/features/payroll/domain/repos/payroll_repo.dart';
import 'package:erp_sys/features/payroll/view/cubit/payroll_cubit.dart';
import 'package:erp_sys/features/payroll/view/sections/payroll_table_section_header.dart';
import 'package:erp_sys/features/payroll/view/widgets/payroll_list_design.dart';
import 'package:erp_sys/features/payroll/view/widgets/payroll_table.dart';
import 'package:erp_sys/features/payroll/view/widgets/payroll_pagination_bar.dart';

class Session implements SessionRepo {
  @override
  Future<AppUser?> getCurrentAppUser() async => const AppUser(
    id: 'u',
    email: 'hr@example.test',
    role: 'hr',
    tenantId: 't',
    employeeId: 'e',
  );
}

class Repo implements PayrollRepo {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

final runs =
    ['draft', 'pending_finance_manager', 'approved', 'rejected_by_admin']
        .indexed
        .map(
          (entry) => PayrollRun(
            id: '${entry.$1}',
            tenantId: 't',
            periodStart: DateTime(2026, 10 - entry.$1),
            periodEnd: DateTime(2026, 11 - entry.$1, 0),
            status: entry.$2,
            totalEmployees: 10,
            totalAmount: 59200.50,
            createdAt: DateTime(2026, 10),
          ),
        )
        .toList();

void main() {
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1350.0]) {
      testWidgets(
        'Payroll entry $lang $width shows styled controls and opens run',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 1000));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final session = SessionCubit(Session());
          await session.load();
          final cubit = PayrollCubit(Repo());
          addTearDown(session.close);
          addTearDown(cubit.close);
          String? opened;
          await tester.pumpWidget(
            MultiBlocProvider(
              providers: [
                BlocProvider.value(value: session),
                BlocProvider.value(value: cubit),
              ],
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: Locale(lang),
                theme: EmployeeTheme.from(AppTheme.light()),
                localizationsDelegates: appLocalizationDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: PayrollListDesign(
                    header: PayrollTableSectionHeader(
                      cubit: cubit,
                      state: cubit.state,
                    ),
                    status: const SizedBox.shrink(),
                    table: PayrollTable(
                      items: runs,
                      onOpenRun: (id) {
                        opened = id;
                      },
                    ),
                    pagination: PayrollPaginationBar(
                      page: 0,
                      totalPages: 1,
                      total: 4,
                      canPrev: false,
                      canNext: false,
                      onPrev: () {},
                      onNext: () {},
                      pageSize: 10,
                      onPageSizeChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (width >= 768) {
            await tester.ensureVisible(find.byType(OutlinedButton).last);
            await tester.pumpAndSettle();
            await tester.tap(find.byType(OutlinedButton).last);
            expect(opened, '3');
          }
        },
      );
    }
  }
  testWidgets('Payroll entry visual preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_PAYROLL_PREVIEW')) return;
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
    await tester.binding.setSurfaceSize(const Size(1350, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = SessionCubit(Session());
    await session.load();
    final cubit = PayrollCubit(Repo());
    addTearDown(session.close);
    addTearDown(cubit.close);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: session),
            BlocProvider.value(value: cubit),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar'),
            theme: EmployeeTheme.from(AppTheme.light()),
            localizationsDelegates: appLocalizationDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PayrollListDesign(
                header: PayrollTableSectionHeader(
                  cubit: cubit,
                  state: cubit.state,
                ),
                status: const SizedBox.shrink(),
                table: PayrollTable(items: runs, onOpenRun: (_) {}),
                pagination: PayrollPaginationBar(
                  page: 0,
                  totalPages: 1,
                  total: 4,
                  canPrev: false,
                  canNext: false,
                  onPrev: () {},
                  onNext: () {},
                  pageSize: 10,
                  onPageSizeChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/hr_payroll_list_preview.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
