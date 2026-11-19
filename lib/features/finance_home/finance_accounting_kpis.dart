import 'package:material_ui/material_ui.dart';

import '../../core/routing/app_routes.dart';
import '../accounting/reports/domain/accounting_reports_models.dart';
import '../accounting/reports/domain/accounting_reports_repo.dart';
import '../accounting/view/accounting_ui.dart';
import '../payroll/view/widgets/payroll_format.dart';

const _green = Color(0xFF2E7D32);
const _red = Color(0xFFC62828);

/// Accounting KPI strip for Finance Home. Failures stay inside this widget.
class FinanceAccountingKpis extends StatefulWidget {
  const FinanceAccountingKpis({
    super.key,
    required this.repo,
    required this.initialMonth,
    required this.onOpen,
  });

  final AccountingReportsRepo repo;
  final DateTime initialMonth;
  final ValueChanged<String> onOpen;

  @override
  State<FinanceAccountingKpis> createState() => _FinanceAccountingKpisState();
}

class _FinanceAccountingKpisState extends State<FinanceAccountingKpis> {
  late DateTime month = DateTime(
    widget.initialMonth.year,
    widget.initialMonth.month,
  );
  AccountingKpis? kpis;
  Object? error;
  bool loading = true;
  int generation = 0;

  String tr(String ar, String en) => accountingText(context, ar, en);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final version = ++generation;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await widget.repo.fetchKpis(month);
      if (!mounted || version != generation) return;
      setState(() {
        kpis = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted || version != generation) return;
      setState(() {
        error = e;
        loading = false;
      });
    }
  }

  void shiftMonth(int delta) {
    month = DateTime(month.year, month.month + delta);
    load();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              tr('المؤشرات المحاسبية', 'Accounting overview'),
              style: const TextStyle(
                color: accountingInk,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              key: const ValueKey('kpi-prev-month'),
              tooltip: tr('الشهر السابق', 'Previous month'),
              onPressed: loading ? null : () => shiftMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Text(payrollPeriod(month, ar)),
            IconButton(
              key: const ValueKey('kpi-next-month'),
              tooltip: tr('الشهر التالي', 'Next month'),
              onPressed: loading ? null : () => shiftMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
            TextButton.icon(
              onPressed: () => widget.onOpen(AppRoutes.ledger),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: Text(tr('دفتر الأستاذ', 'General Ledger')),
            ),
            TextButton.icon(
              onPressed: () => widget.onOpen(AppRoutes.trialBalance),
              icon: const Icon(Icons.balance_outlined, size: 18),
              label: Text(tr('ميزان المراجعة', 'Trial Balance')),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null)
          accountingPanel(
            Row(
              children: [
                const Icon(Icons.error_outline, color: _red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr(
                      'المؤشرات المحاسبية غير متاحة حاليًا.',
                      'Accounting figures are unavailable.',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: load,
                  child: Text(tr('إعادة المحاولة', 'Retry')),
                ),
              ],
            ),
          )
        else
          ..._figures(kpis!),
      ],
    );
  }

  List<Widget> _figures(AccountingKpis k) => [
    Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _card(
          tr('رصيد النقدية', 'Cash balance'),
          accountingBalance(k.cashBalance),
          Icons.account_balance_wallet_outlined,
        ),
        _card(
          tr('الإيرادات', 'Revenue'),
          accountingBalance(k.revenue),
          Icons.trending_up,
        ),
        _card(
          tr('المصروفات', 'Expenses'),
          accountingBalance(k.expenses),
          Icons.trending_down,
        ),
        _card(
          tr('صافي الربح', 'Net profit'),
          accountingBalance(k.netProfit),
          Icons.insights_outlined,
          color: k.netProfit < 0 ? _red : _green,
        ),
        _card(
          tr('مسودات بانتظار الترحيل', 'Drafts to post'),
          '${k.draftCount}',
          Icons.menu_book_outlined,
          onTap: () => widget.onOpen(AppRoutes.journal),
        ),
      ],
    ),
    if (k.staleDraftCount > 0)
      _alert(
        tr(
          '${k.staleDraftCount} مسودات أقدم من 7 أيام بانتظار الترحيل',
          '${k.staleDraftCount} drafts older than 7 days are waiting to be posted',
        ),
        AppRoutes.journal,
      ),
    if (!k.hasCashAccounts)
      _alert(
        tr('لم يتم تحديد حسابات نقدية بعد', 'No cash accounts marked yet'),
        AppRoutes.accounts,
      ),
  ];

  Widget _card(
    String label,
    String value,
    IconData icon, {
    Color? color,
    VoidCallback? onTap,
  }) => SizedBox(
    width: 200,
    child: accountingPanel(
      InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accountingPurple, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Color(0xFF77709A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: color ?? accountingInk,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _alert(String text, String route) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Material(
      color: const Color(0xFFFFF4E5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => widget.onOpen(route),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFB26A00)),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    ),
  );
}
