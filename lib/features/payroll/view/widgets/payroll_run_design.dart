import 'package:material_ui/material_ui.dart';
import 'payroll_format.dart';

import '../../domain/models/payroll_item.dart';
import '../../domain/models/payroll_run.dart';
import 'payroll_run_items_table.dart';

/// Both payroll stages share the same saved run; approval never creates a copy.
class PayrollRunDesign extends StatelessWidget {
  const PayrollRunDesign({
    super.key,
    required this.run,
    required this.items,
    required this.preparation,
    required this.actions,
    required this.workflow,
    required this.onBack,
  });
  final PayrollRun run;
  final List<PayrollItem> items;
  final bool preparation;
  final Widget actions;
  final Widget workflow;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String a, String e) => ar ? a : e;
    String date(DateTime d) => payrollDate(d);
    final period = '${date(run.periodStart)} — ${date(run.periodEnd)}';
    num sum(num Function(PayrollItem) value) =>
        items.fold<num>(0, (s, i) => s + value(i));
    final basic = sum((i) => i.basicSalary);
    final housing = sum((i) => i.housingAllowance);
    final transport = sum((i) => i.transportAllowance);
    final other = sum((i) => i.otherAllowance);
    final total = sum((i) => i.total);
    Widget info(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF77738C)),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    Widget panel(String title, Widget body) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFECE5F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF21194E),
            ),
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
    final totals = Wrap(
      spacing: 24,
      runSpacing: 16,
      children: [
        for (final entry in <String, String>{
          tr('إجمالي الموظفين', 'Employees'): '${run.totalEmployees}',
          tr('إجمالي الرواتب الأساسية', 'Basic salaries'): payrollMoney(basic),
          tr('إجمالي بدل السكن', 'Housing'): payrollMoney(housing),
          tr('إجمالي بدل النقل', 'Transport'): payrollMoney(transport),
          tr('إجمالي البدلات الأخرى', 'Other allowances'): payrollMoney(other),
          tr('الإجمالي', 'Total'): payrollMoney(total),
        }.entries)
          SizedBox(
            width: 145,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8659BB),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF21194E),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    final history = panel(
      tr('سجل المراجعة', 'Review history'),
      Column(
        children: [
          info(tr('إعداد المسير', 'Run created'), date(run.createdAt)),
          if (run.hrApprovedAt != null)
            info(
              tr('إرسال للمراجعة المالية', 'Sent to finance'),
              date(run.hrApprovedAt!),
            ),
          if (run.financeManagerApprovedAt != null)
            info(
              tr('اعتماد مدير المحاسبة', 'Finance approval'),
              date(run.financeManagerApprovedAt!),
            ),
          if (run.adminApprovedAt != null)
            info(
              tr('الاعتماد النهائي', 'Final approval'),
              date(run.adminApprovedAt!),
            ),
          if ((run.rejectReason ?? '').isNotEmpty)
            info(tr('سبب الرفض', 'Rejection reason'), run.rejectReason!),
        ],
      ),
    );
    final summary = panel(
      tr('تفاصيل بنود الرواتب', 'Payroll components'),
      Column(
        children: [
          info(
            tr('البند', 'Component'),
            tr('إجمالي المبلغ (ر.س)', 'Total (SAR)'),
          ),
          const Divider(color: Color(0xFFECE5F4)),
          info(tr('الراتب الأساسي', 'Basic salary'), payrollMoney(basic)),
          info(
            tr('البدلات', 'Allowances'),
            payrollMoney(housing + transport + other),
          ),
          Container(
            color: const Color(0xFFF3EAFE),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: info(tr('الإجمالي', 'Total'), payrollMoney(total)),
          ),
          const SizedBox(height: 10),
          Text(
            tr(
              'المسير الحالي يشمل الأساسي والبدلات فقط. الخصومات والأوفر تايم لم تُحتسب.',
              'This run includes basic salary and allowances only. Deductions and overtime are not calculated.',
            ),
            style: const TextStyle(fontSize: 12, color: Color(0xFF77738C)),
          ),
        ],
      ),
    );
    final side = Column(
      children: [
        panel(
          tr('معلومات المسير', 'Run information'),
          Column(
            children: [
              info(tr('الفترة', 'Period'), period),
              info(tr('إجمالي الموظفين', 'Employees'), '${run.totalEmployees}'),
              info(
                tr('إجمالي قيمة الرواتب', 'Payroll value'),
                payrollMoney(run.totalAmount),
              ),
              info(tr('تاريخ الإعداد', 'Created'), date(run.createdAt)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        panel(tr('إجراءات المسير', 'Payroll actions'), actions),
      ],
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEAE3F2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EAFE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    color: Color(0xFF8659BB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(
                          preparation
                              ? 'تجهيز مسير الرواتب'
                              : 'تفاصيل مسير الرواتب',
                          preparation ? 'Prepare payroll' : 'Payroll details',
                        ),
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF21194E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        period,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF77738C),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onBack,
                  tooltip: tr('قائمة المسيرات', 'Payroll runs'),
                  icon: const Icon(Icons.list_alt),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (preparation) ...[
              Wrap(
                spacing: 32,
                runSpacing: 12,
                children: [
                  Container(
                    width: 190,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFEAE3F2)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: info(tr('من تاريخ', 'From'), date(run.periodStart)),
                  ),
                  Container(
                    width: 190,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFEAE3F2)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: info(tr('إلى تاريخ', 'To'), date(run.periodEnd)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              panel(
                tr('عناصر الرواتب', 'Payroll items'),
                PayrollRunItemsTable(items: items),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: totals,
              ),
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(
                      'المسودة محفوظة بالفعل. راجع المبالغ ثم أرسلها للمراجعة المالية.',
                      'The draft is already saved. Review the amounts, then submit to finance.',
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  actions,
                ],
              ),
            ] else ...[
              panel(tr('ملخص المسير', 'Payroll summary'), totals),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, c) {
                  final main = Column(
                    children: [summary, const SizedBox(height: 14), history],
                  );
                  return c.maxWidth >= 900
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 300, child: side),
                            const SizedBox(width: 16),
                            Expanded(child: main),
                          ],
                        )
                      : Column(
                          children: [main, const SizedBox(height: 14), side],
                        );
                },
              ),
              const SizedBox(height: 14),
              panel(
                tr('تفاصيل الموظفين', 'Employee details'),
                PayrollRunItemsTable(items: items),
              ),
            ],
            const SizedBox(height: 14),
            workflow,
          ],
        ),
      ),
    );
  }
}
