import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/ui/app_data_state.dart';
import '../../reports/domain/accounting_reports_models.dart';
import '../../reports/domain/accounting_reports_repo.dart';
import '../../view/accounting_ui.dart';
import 'trial_balance_cubit.dart';

const _green = Color(0xFF2E7D32);
const _red = Color(0xFFC62828);
const _typeOrder = ['asset', 'liability', 'equity', 'income', 'expense'];

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Trial Balance: every account's balance on a date; debits must equal credits.
class TrialBalancePage extends StatelessWidget {
  const TrialBalancePage({super.key, this.repo, this.now, this.onOpen});

  final AccountingReportsRepo? repo;
  final DateTime? now;

  /// Receives a full route; defaults to `context.go`.
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TrialBalanceCubit(
      repo ?? AppDI.accountingReportsRepo,
      now: now ?? DateTime.now(),
    )..load(),
    child: _TrialBalanceView(onOpen: onOpen),
  );
}

class _TrialBalanceView extends StatelessWidget {
  const _TrialBalanceView({this.onOpen});
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    String tr(String ar, String en) => accountingText(context, ar, en);
    return BlocBuilder<TrialBalanceCubit, TrialBalanceState>(
      builder: (context, state) {
        final cubit = context.read<TrialBalanceCubit>();
        return accountingResponsivePage(
          Padding(
            padding: const EdgeInsets.all(16),
            child: accountingPanel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  accountingHeading(
                    tr('ميزان المراجعة', 'Trial Balance'),
                    tr(
                      'أرصدة جميع الحسابات في تاريخ محدد',
                      'Balance of every account on a date',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey('tb-as-of'),
                        icon: const Icon(Icons.event_outlined, size: 18),
                        label: Text(
                          '${tr('حتى تاريخ', 'As of')} ${_day(state.asOf)}',
                        ),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            initialDate: state.asOf,
                          );
                          if (d != null) await cubit.setAsOf(d);
                        },
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            key: const ValueKey('tb-hide-zero'),
                            value: state.hideZero,
                            activeThumbColor: accountingPurple,
                            onChanged: cubit.toggleHideZero,
                          ),
                          Text(
                            tr('إخفاء الأرصدة الصفرية', 'Hide zero balances'),
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: tr('تحديث', 'Refresh'),
                        onPressed: state.loading ? null : cubit.load,
                        icon: const Icon(
                          Icons.refresh,
                          color: accountingPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _body(context, state, cubit, tr)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    TrialBalanceState state,
    TrialBalanceCubit cubit,
    String Function(String, String) tr,
  ) {
    if (state.loading) return const AppLoadingState();
    if (state.error != null) {
      return AppFailureState(error: state.error, onRetry: cubit.load);
    }
    if (state.rows.isEmpty) {
      return AppEmptyState(
        title: tr(
          'لا توجد قيود مرحّلة حتى هذا التاريخ.',
          'No posted entries up to this date.',
        ),
      );
    }
    final groupLabel = {
      'asset': tr('الأصول', 'Assets'),
      'liability': tr('الالتزامات', 'Liabilities'),
      'equity': tr('حقوق الملكية', 'Equity'),
      'income': tr('الإيرادات', 'Income'),
      'expense': tr('المصروفات', 'Expenses'),
    };
    final visible = state.visibleRows;
    final types = <String>{..._typeOrder, ...visible.map((r) => r.type)};
    void open(TrialBalanceRow r) {
      final route =
          '${AppRoutes.ledger}?account=${r.accountId}'
          '&from=${state.asOf.year.toString().padLeft(4, '0')}-01-01'
          '&to=${_day(state.asOf)}';
      onOpen != null ? onOpen!(route) : context.go(route);
    }

    Widget amount(num v, {bool bold = false}) => Text(
      v == 0 ? '—' : accountingBalance(v),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      style: bold ? const TextStyle(fontWeight: FontWeight.w800) : null,
    );
    const bold = TextStyle(color: accountingInk, fontWeight: FontWeight.w800);
    final difference = (state.totalDebit - state.totalCredit).abs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (state.isBalanced ? _green : _red).withValues(alpha: .1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              state.isBalanced
                  ? tr('متوازن', 'Balanced')
                  : tr(
                      'غير متوازن بفارق ${accountingBalance(difference)}',
                      'Out of balance by ${accountingBalance(difference)}',
                    ),
              style: TextStyle(
                color: state.isBalanced ? _green : _red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: AccountingTable(
            minimumWidth: 640,
            headings: [
              tr('الرمز', 'Code'),
              tr('الحساب', 'Account'),
              tr('مدين', 'Debit'),
              tr('دائن', 'Credit'),
            ],
            widths: const [14, 46, 20, 20],
            rows: [
              for (final type in types)
                if (visible.any((r) => r.type == type)) ...[
                  [
                    const SizedBox(),
                    Text(groupLabel[type] ?? type, style: bold),
                    const SizedBox(),
                    const SizedBox(),
                  ],
                  for (final r
                      in visible.where((r) => r.type == type).toList()
                        ..sort((a, b) => a.code.compareTo(b.code)))
                    [
                      Text(r.code, textAlign: TextAlign.center),
                      InkWell(
                        key: ValueKey('tb-row-${r.accountId}'),
                        onTap: () => open(r),
                        child: Text(
                          r.name,
                          style: const TextStyle(
                            color: accountingPurple,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      amount(r.debit),
                      amount(r.credit),
                    ],
                ],
              [
                const SizedBox(),
                Text(tr('الإجمالي', 'Total'), style: bold),
                amount(state.totalDebit, bold: true),
                amount(state.totalCredit, bold: true),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
