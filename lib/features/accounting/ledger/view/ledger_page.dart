import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/ui/app_data_state.dart';
import '../../accounts/domain/repos/accounts_repo.dart';
import '../../reports/domain/accounting_reports_repo.dart';
import '../../view/accounting_ui.dart';
import 'ledger_cubit.dart';

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// General Ledger: posted movements of one account with a running balance.
class LedgerPage extends StatelessWidget {
  const LedgerPage({
    super.key,
    this.reportsRepo,
    this.accountsRepo,
    this.initialAccountId,
    this.initialFrom,
    this.initialTo,
    this.now,
  });

  final AccountingReportsRepo? reportsRepo;
  final AccountsRepo? accountsRepo;
  final String? initialAccountId;
  final DateTime? initialFrom, initialTo;
  final DateTime? now;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LedgerCubit(
      reportsRepo ?? AppDI.accountingReportsRepo,
      accountsRepo ?? AppDI.accountsRepo,
      now: now ?? DateTime.now(),
    )..init(accountId: initialAccountId, from: initialFrom, to: initialTo),
    child: const _LedgerView(),
  );
}

class _LedgerView extends StatelessWidget {
  const _LedgerView();

  @override
  Widget build(BuildContext context) {
    String tr(String ar, String en) => accountingText(context, ar, en);
    return BlocBuilder<LedgerCubit, LedgerState>(
      builder: (context, state) {
        final cubit = context.read<LedgerCubit>();
        final narrow = MediaQuery.sizeOf(context).width < 600;
        return accountingResponsivePage(
          minHeight: narrow ? 1150 : 760,
          Padding(
            padding: const EdgeInsets.all(16),
            child: accountingPanel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  accountingHeading(
                    tr('دفتر الأستاذ العام', 'General Ledger'),
                    tr(
                      'حركات الحساب المرحّلة ورصيده الجاري',
                      'Posted movements and running balance of one account',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DropdownMenu<String>(
                        key: ValueKey(
                          'ledger-account-${state.accounts.length}',
                        ),
                        width: narrow ? 260 : 360,
                        enableFilter: true,
                        requestFocusOnTap: true,
                        initialSelection: state.accountId,
                        label: Text(tr('الحساب', 'Account')),
                        onSelected: (id) {
                          if (id != null) cubit.selectAccount(id);
                        },
                        dropdownMenuEntries: [
                          for (final a in state.accounts)
                            DropdownMenuEntry(
                              value: a.id,
                              label:
                                  '${a.code} — ${a.name}'
                                  '${a.isActive ? '' : ' (${tr('غير نشط', 'Inactive')})'}',
                            ),
                        ],
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey('ledger-range'),
                        icon: const Icon(Icons.date_range_outlined, size: 18),
                        label: Text(
                          '${_day(state.from)} → ${_day(state.to)}',
                          textDirection: TextDirection.ltr,
                        ),
                        onPressed: () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            initialDateRange: DateTimeRange(
                              start: state.from,
                              end: state.to,
                            ),
                          );
                          if (range != null) {
                            await cubit.setRange(range.start, range.end);
                          }
                        },
                      ),
                      IconButton(
                        tooltip: tr('تحديث', 'Refresh'),
                        onPressed: state.loading ? null : cubit.refresh,
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
    LedgerState state,
    LedgerCubit cubit,
    String Function(String, String) tr,
  ) {
    if (state.loading) return const AppLoadingState();
    if (state.error != null) {
      return AppFailureState(error: state.error, onRetry: cubit.refresh);
    }
    final r = state.report;
    if (state.accountId == null || r == null) {
      return AppEmptyState(
        title: tr(
          'اختر حسابًا لعرض دفتر الأستاذ.',
          'Choose an account to view its ledger.',
        ),
      );
    }
    Widget money(num v) => Text(
      accountingBalance(v),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    Widget amount(num v) => Text(
      v == 0 ? '—' : accountingBalance(v),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _card(tr('الرصيد الافتتاحي', 'Opening balance'), r.opening),
            _card(tr('إجمالي المدين', 'Total debit'), r.totalDebit),
            _card(tr('إجمالي الدائن', 'Total credit'), r.totalCredit),
            _card(tr('الرصيد الختامي', 'Closing balance'), r.closing),
          ],
        ),
        if (r.truncated)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              tr(
                'يُعرض أول 2,000 حركة فقط. ضيّق نطاق التاريخ لرؤية الكل.',
                'Showing the first 2,000 movements. Narrow the date range to see all.',
              ),
              style: const TextStyle(color: Color(0xFFB26A00)),
            ),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: r.rows.isEmpty
              ? AppEmptyState(
                  title: tr(
                    'لا توجد حركات مرحّلة في هذه الفترة.',
                    'No posted movements in this period.',
                  ),
                )
              : AccountingTable(
                  minimumWidth: 760,
                  headings: [
                    tr('التاريخ', 'Date'),
                    tr('البيان', 'Memo'),
                    tr('مدين', 'Debit'),
                    tr('دائن', 'Credit'),
                    tr('الرصيد', 'Balance'),
                  ],
                  widths: const [16, 40, 14, 14, 16],
                  rows: [
                    [
                      Text(
                        _day(state.from),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                      ),
                      Text(
                        tr('الرصيد الافتتاحي', 'Opening balance'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(),
                      const SizedBox(),
                      money(r.opening),
                    ],
                    for (final row in r.rows)
                      [
                        Text(
                          _day(row.entryDate),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                        ),
                        SelectableText(row.memo.isEmpty ? '—' : row.memo),
                        amount(row.debit),
                        amount(row.credit),
                        money(row.balance),
                      ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _card(String label, num value) => SizedBox(
    width: 200,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F2FC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF77709A))),
          const SizedBox(height: 6),
          Text(
            accountingBalance(value),
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: accountingInk,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
