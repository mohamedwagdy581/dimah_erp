import 'package:material_ui/material_ui.dart';
import '../../../finance_home/finance_employee_avatar.dart';
import '../../domain/models/payroll_assignee_option.dart';
import '../../domain/models/payroll_run.dart';
import 'payroll_format.dart';
import '../../../employees/domain/job_level.dart';

class DisbursementAssignmentDialog extends StatelessWidget {
  const DisbursementAssignmentDialog({
    super.key,
    required this.accountant,
    required this.run,
  });

  final PayrollAssigneeOption accountant;
  final PayrollRun run;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String a, String e) => ar ? a : e;
    const purple = Color(0xFF8659BB), navy = Color(0xFF21194E);
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: const Color(0xFFF8F4FD),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE2FB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: purple,
                              textDirection: TextDirection.ltr,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tr(
                                'تأكيد إسناد مهمة الصرف',
                                'Confirm disbursement assignment',
                              ),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: navy,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: tr('إغلاق', 'Close'),
                            onPressed: () => Navigator.pop(context, false),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            tr(
                              'سيتم إسناد متابعة صرف هذا المسير إلى:',
                              'Assign payment processing for this payroll to:',
                            ),
                            style: const TextStyle(
                              color: Color(0xFF77709A),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE5DDF2),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                FinanceEmployeeAvatar(
                                  name: accountant.fullName,
                                  radius: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        accountant.fullName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: navy,
                                        ),
                                      ),
                                      if (accountant.jobLevel != null)
                                        Text(
                                          jobLevelLabel(
                                            accountant.jobLevel,
                                            isArabic: ar,
                                          ),
                                          style: const TextStyle(
                                            color: purple,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      if (accountant
                                              .employeeNumber
                                              ?.isNotEmpty ==
                                          true) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          accountant.employeeNumber!,
                                          textDirection: TextDirection.ltr,
                                          style: const TextStyle(
                                            color: purple,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            tr('ملخص المسير', 'Payroll summary'),
                            style: const TextStyle(
                              color: navy,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SummaryLine(
                            label: tr('فترة الرواتب', 'Payroll period'),
                            value:
                                '${payrollDate(run.periodStart)} — ${payrollDate(run.periodEnd)}',
                            ltr: true,
                          ),
                          _SummaryLine(
                            label: tr('عدد الموظفين', 'Employees'),
                            value: '${run.totalEmployees}',
                          ),
                          _SummaryLine(
                            label: tr('إجمالي الرواتب', 'Total payroll'),
                            value:
                                '${payrollMoney(run.totalAmount)} ${tr('ريال', 'SAR')}',
                            emphasis: true,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4EDFC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: purple,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    tr(
                                      'الإسناد يكلّف المحاسب بالمهمة داخل النظام. التحويل البنكي يتم خارج النظام، ثم يسجل المحاسب حالة الصرف.',
                                      'Assignment creates responsibility inside the system. The accountant makes the bank transfer outside the system, then records payment status.',
                                    ),
                                    style: const TextStyle(
                                      color: navy,
                                      height: 1.6,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5DDF2)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, box) {
                  final confirm = FilledButton.icon(
                    key: const ValueKey('confirm-disbursement-assignment'),
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: Text(tr('تأكيد الإسناد', 'Confirm assignment')),
                    style: FilledButton.styleFrom(
                      backgroundColor: purple,
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                  final cancel = OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: purple,
                      minimumSize: const Size(0, 46),
                      side: const BorderSide(color: Color(0xFFE5DDF2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(tr('إلغاء', 'Cancel')),
                  );
                  if (box.maxWidth < 360) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [confirm, const SizedBox(height: 10), cancel],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: confirm),
                      const SizedBox(width: 12),
                      SizedBox(width: 110, child: cancel),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.ltr = false,
    this.emphasis = false,
  });
  final String label, value;
  final bool ltr, emphasis;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 16,
      runSpacing: 6,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF77709A), fontSize: 13),
        ),
        Text(
          value,
          textDirection: ltr ? TextDirection.ltr : null,
          style: TextStyle(
            color: emphasis ? const Color(0xFF8659BB) : const Color(0xFF21194E),
            fontSize: emphasis ? 18 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
