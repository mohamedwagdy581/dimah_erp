import 'package:material_ui/material_ui.dart';
import '../../../../core/ui/app_data_state.dart';
import '../../data/repos/payroll_disbursement_repo.dart';
import 'finance_payroll_table.dart';
import 'payroll_format.dart';
import 'disbursement_assignment_dialog.dart';
import '../../../employees/domain/job_level.dart';

class FinanceDisbursementWorkspace extends StatefulWidget {
  const FinanceDisbursementWorkspace({
    super.key,
    required this.repo,
    required this.runId,
    this.onReview,
  });
  final PayrollDisbursementRepo repo;
  final String runId;
  final VoidCallback? onReview;
  @override
  State<FinanceDisbursementWorkspace> createState() =>
      _FinanceDisbursementWorkspaceState();
}

class _FinanceDisbursementWorkspaceState
    extends State<FinanceDisbursementWorkspace> {
  PayrollDisbursementData? data;
  final _pageScroll = ScrollController();
  @override
  void dispose() {
    _pageScroll.dispose();
    super.dispose();
  }

  String? selected, message;
  Object? error;
  bool loading = true, busy = false, assigned = false;
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => ar ? a : e;
  bool get ready =>
      data?.run.status == 'approved' &&
      [
        'not_started',
        'assigned_to_finance_manager',
      ].contains(data?.run.disbursementStatus ?? 'not_started') &&
      (data?.run.disbursementTaskId ?? '').isNotEmpty &&
      !assigned;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final next = await widget.repo.load(widget.runId);
      if (!mounted) return;
      setState(() {
        data = next;
        loading = false;
        if (!next.accountants.any((a) => a.employeeId == selected)) {
          selected = null;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    }
  }

  String status() {
    if (assigned) return tr('تم الإسناد للمحاسب', 'Assigned to accountant');
    return switch (data!.run.disbursementStatus) {
      'assigned_to_accountant' => tr(
        'تم الإسناد للمحاسب',
        'Assigned to accountant',
      ),
      'payment_in_progress' => tr('جارٍ تنفيذ الصرف', 'Payment in progress'),
      'paid' => tr('تم تسجيل الصرف', 'Payment recorded'),
      _ => tr('جاهزة للتكليف', 'Ready to assign'),
    };
  }

  Future<void> assign() async {
    if (busy || loading || !ready || selected == null) return;
    final accountant = data!.accountants.firstWhere(
      (a) => a.employeeId == selected,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          DisbursementAssignmentDialog(accountant: accountant, run: data!.run),
    );
    if (!mounted || confirmed != true || busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await widget.repo.assign(widget.runId, accountant.employeeId);
      if (!mounted) return;
      setState(() {
        assigned = true;
        message = tr(
          'تم إسناد مهمة الصرف إلى ${accountant.fullName}.',
          'Disbursement assigned to ${accountant.fullName}.',
        );
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          message = tr(
            'تعذّر الإسناد. تحقق من الاتصال وصلاحية المسير والمحاسب ثم أعد المحاولة.',
            'Could not assign. Check your connection and payroll/accountant eligibility, then retry.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget panel(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: financeBorder),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: financeNavy,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
  Widget pair(String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFFCFAFF),
      border: Border.all(color: financeBorder),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF77709A), fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textDirection: RegExp(r'^\d{4}/').hasMatch(value)
                ? TextDirection.ltr
                : null,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: financeNavy,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  Widget summary(String label, String value, IconData icon) => panel(label, [
    Row(
      children: [
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: financeNavy,
            ),
          ),
        ),
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFF0E5FF),
          child: Icon(icon, color: financePurple),
        ),
      ],
    ),
  ]);
  Widget columns(List<Widget> children, {double breakpoint = 700}) =>
      LayoutBuilder(
        builder: (context, box) => box.maxWidth < breakpoint
            ? Column(
                children: [
                  for (final child in children)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: child,
                    ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: children[i]),
                  ],
                ],
              ),
      );
  @override
  Widget build(BuildContext context) {
    if (loading) return const AppLoadingState();
    if (error != null) return AppFailureState(error: error, onRetry: load);
    final run = data!.run;
    final approved = run.status == 'approved';
    final date = payrollDate(run.periodStart);
    return LayoutBuilder(
      builder: (context, box) => Scrollbar(
        controller: _pageScroll,
        thumbVisibility: true,
        interactive: true,
        child: SingleChildScrollView(
          controller: _pageScroll,
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              minHeight: box.maxHeight.isFinite
                  ? (box.maxHeight - 32).clamp(0, double.infinity)
                  : 0,
            ),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: financeBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(
                              'تكليف صرف الرواتب',
                              'Assign payroll disbursement',
                            ),
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: financeNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr(
                              'إسناد مهمة صرف الرواتب بعد اعتماد الإدارة',
                              'Assign disbursement after management approval',
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF77709A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onReview != null)
                      IconButton(
                        onPressed: busy ? null : widget.onReview,
                        tooltip: tr('عرض مراجعة المسير', 'View payroll review'),
                        icon: const Icon(
                          Icons.receipt_long_outlined,
                          color: financePurple,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Chip(
                    avatar: Icon(
                      approved ? Icons.check_circle : Icons.schedule,
                      color: approved ? const Color(0xFF168654) : Colors.orange,
                    ),
                    label: Text(
                      approved
                          ? tr('معتمد من الإدارة', 'Management approved')
                          : tr(
                              'بانتظار اعتماد الإدارة',
                              'Awaiting management approval',
                            ),
                    ),
                    backgroundColor: approved
                        ? const Color(0xFFE2F7ED)
                        : const Color(0xFFFFF1E5),
                    side: BorderSide.none,
                  ),
                ),
                const SizedBox(height: 12),
                columns([
                  summary(
                    tr('إجمالي المبلغ المراد صرفه', 'Total amount to disburse'),
                    '${payrollMoney(run.totalAmount)} ${tr('ريال', 'SAR')}',
                    Icons.description_outlined,
                  ),
                  summary(
                    tr('عدد الموظفين', 'Employees'),
                    '${run.totalEmployees}',
                    Icons.groups_rounded,
                  ),
                  summary(
                    tr('فترة الرواتب', 'Payroll period'),
                    payrollPeriod(run.periodStart, ar),
                    Icons.calendar_month_outlined,
                  ),
                ]),
                const SizedBox(height: 16),
                panel(tr('تفاصيل مهمة الصرف', 'Disbursement task details'), [
                  columns([
                    panel(
                      tr('مهمة الصرف المرتبطة', 'Linked disbursement task'),
                      [
                        pair(
                          tr('رقم المهمة', 'Task ID'),
                          (run.disbursementTaskId ?? '').isEmpty
                              ? '—'
                              : run.disbursementTaskId!.substring(
                                  0,
                                  run.disbursementTaskId!.length.clamp(0, 8),
                                ),
                        ),
                        pair(
                          tr('الوصف', 'Description'),
                          data!.taskTitle ??
                              tr(
                                'صرف رواتب الفترة $date',
                                'Pay salaries for $date',
                              ),
                        ),
                        pair(
                          tr('الحالة', 'Status'),
                          approved
                              ? status()
                              : tr(
                                  'غير متاحة للتكليف',
                                  'Assignment unavailable',
                                ),
                        ),
                        pair(
                          tr('تاريخ إنشاء المهمة', 'Task created'),
                          data!.taskCreatedAt == null
                              ? '—'
                              : payrollDate(data!.taskCreatedAt!),
                        ),
                      ],
                    ),
                    panel(tr('معلومات المسير', 'Payroll information'), [
                      pair(
                        tr('حالة الرواتب', 'Payroll status'),
                        approved
                            ? tr('معتمد من الإدارة', 'Management approved')
                            : run.status,
                      ),
                      pair(
                        tr('فترة الرواتب', 'Period'),
                        '${payrollDate(run.periodStart)} — ${payrollDate(run.periodEnd)}',
                      ),
                      pair(
                        tr('عدد الموظفين', 'Employees'),
                        '${run.totalEmployees}',
                      ),
                      pair(
                        tr('المبلغ الإجمالي', 'Total'),
                        '${payrollMoney(run.totalAmount)} ${tr('ريال', 'SAR')}',
                      ),
                      pair(
                        tr('تاريخ اعتماد الإدارة', 'Approved on'),
                        run.adminApprovedAt == null
                            ? '—'
                            : payrollDate(run.adminApprovedAt!),
                      ),
                    ]),
                  ]),
                ]),
                const SizedBox(height: 16),
                panel(tr('إسناد مهمة الصرف', 'Assign disbursement task'), [
                  if (ready && data!.accountants.isNotEmpty)
                    DropdownButtonFormField<String>(
                      key: const ValueKey('disbursement-accountant'),
                      initialValue: selected,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: tr(
                          'المحاسب المسؤول *',
                          'Responsible accountant *',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final a in data!.accountants)
                          DropdownMenuItem(
                            value: a.employeeId,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFFF0E5FF),
                                  child: Text(
                                    a.fullName.trim().isEmpty
                                        ? '—'
                                        : a.fullName.trim().characters.first,
                                    style: const TextStyle(
                                      color: financePurple,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${a.fullName}${a.employeeNumber == null ? '' : ' · ${a.employeeNumber}'}${a.jobLevel == null ? '' : ' · ${jobLevelLabel(a.jobLevel, isArabic: ar)}'}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      onChanged: busy
                          ? null
                          : (id) => setState(() => selected = id),
                    )
                  else
                    Text(
                      ready
                          ? tr(
                              'لا يوجد موظفون نشطون تابعون لمدير المالية متاحون للتكليف. راجع ربط حساب مدير المالية بملفه والموظفين التابعين له.',
                              'No active team members are available. Check the finance manager employee profile and reporting lines.',
                            )
                          : (!approved
                                ? tr(
                                    'يجب اعتماد المسير من الإدارة أولًا.',
                                    'Management must approve payroll first.',
                                  )
                                : ((run.disbursementTaskId ?? '').isEmpty
                                      ? tr(
                                          'مهمة الصرف غير موجودة. راجع إنشاء المهمة عند اعتماد الإدارة.',
                                          'Disbursement task is missing. Check task creation at management approval.',
                                        )
                                      : status())),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1E8FC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: financePurple),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tr(
                              'التكليف والمتابعة داخل النظام؛ التحويل البنكي يتم خارج النظام. لا يعني الإسناد أن الرواتب صُرفت بالفعل.',
                              'Assignment and tracking happen here; bank transfers happen outside the system. Assignment does not mean salaries have been paid.',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          message!,
                          style: TextStyle(
                            color: assigned
                                ? const Color(0xFF168654)
                                : const Color(0xFFDC4545),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const ValueKey('disbursement-assign'),
                    onPressed: ready && selected != null && !busy
                        ? assign
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: financePurple,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.near_me,
                            textDirection: TextDirection.ltr,
                            size: 19,
                          ),
                    label: Text(
                      busy
                          ? tr('جارٍ الإسناد...', 'Assigning...')
                          : tr('إسناد الصرف للمحاسب', 'Assign to accountant'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
