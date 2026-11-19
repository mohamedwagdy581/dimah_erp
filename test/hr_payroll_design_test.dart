import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/payroll/domain/models/payroll_item.dart';
import 'package:erp_sys/features/payroll/domain/models/payroll_run.dart';
import 'package:erp_sys/features/payroll/domain/repos/payroll_repo.dart';
import 'package:erp_sys/features/payroll/view/cubit/payroll_run_cubit.dart';
import 'package:erp_sys/features/payroll/view/widgets/payroll_run_design.dart';

final run = PayrollRun(
  id: 'old',
  tenantId: 't',
  periodStart: DateTime(2026, 10),
  periodEnd: DateTime(2026, 10, 31),
  status: 'draft',
  totalEmployees: 1,
  totalAmount: 16500.50,
  createdAt: DateTime(2026, 10, 1),
);
const item = PayrollItem(
  id: 'i',
  runId: 'old',
  employeeId: 'e',
  employeeName: 'Sara Ahmed',
  jobTitle: 'HR Manager',
  basicSalary: 12000,
  housingAllowance: 3000,
  transportAllowance: 1000,
  otherAllowance: 500.50,
  total: 16500.50,
);

class OlderRunsRepo implements PayrollRepo {
  final pages = <int>[];
  @override
  Future<List<PayrollItem>> fetchRunItems({required String runId}) async => [
    item,
  ];
  @override
  Future<({List<PayrollRun> items, int total})> fetchRuns({
    required int page,
    required int pageSize,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    pages.add(page);
    return (
      items: page == 0
          ? List.filled(
              100,
              PayrollRun(
                id: 'new',
                tenantId: 't',
                periodStart: run.periodStart,
                periodEnd: run.periodEnd,
                status: 'draft',
                totalEmployees: 0,
                totalAmount: 0,
                createdAt: run.createdAt,
              ),
            )
          : [run],
      total: 101,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('an older run remains reachable after the first 100 runs', () async {
    final repo = OlderRunsRepo();
    final cubit = PayrollRunCubit(repo);
    await cubit.load('old');
    expect(repo.pages, [0, 1]);
    expect(cubit.state.run?.id, 'old');
    expect(cubit.state.error, isNull);
    await cubit.close();
  });
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      for (final preparation in [true, false]) {
        testWidgets(
          '$language $width preparation=$preparation preserves payroll values',
          (tester) async {
            await tester.binding.setSurfaceSize(Size(width, 1000));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            var back = false;
            await tester.pumpWidget(
              MaterialApp(
                locale: Locale(language),
                localizationsDelegates: appLocalizationDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: PayrollRunDesign(
                    run: run,
                    items: const [item],
                    preparation: preparation,
                    actions: const Text('Actions'),
                    workflow: const Text('Workflow'),
                    onBack: () {
                      back = true;
                    },
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text('Sara Ahmed'), findsOneWidget);
            expect(find.text('HR Manager'), findsOneWidget);
            expect(find.text('16,500.50'), findsWidgets);
            expect(tester.takeException(), isNull);
            await tester.tap(find.byIcon(Icons.list_alt));
            expect(back, isTrue);
          },
        );
      }
    }
  }
}
