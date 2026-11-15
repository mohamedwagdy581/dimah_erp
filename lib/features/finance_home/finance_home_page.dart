import 'package:flutter/material.dart';
import '../employees/domain/job_level.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/app_di.dart';
import '../../core/routing/app_routes.dart';
import '../../core/ui/app_data_state.dart';
import '../accounting/view/accounting_ui.dart';
import '../payroll/view/widgets/payroll_format.dart';
import '../accounting/reports/domain/accounting_reports_repo.dart';
import 'finance_accounting_kpis.dart';
import 'finance_home_repo.dart';
import 'finance_employee_avatar.dart';

class FinanceHomePage extends StatefulWidget {
  const FinanceHomePage({
    super.key,
    this.repo,
    this.reportsRepo,
    this.now,
    this.onOpen,
  });
  final FinanceHomeRepo? repo;
  final AccountingReportsRepo? reportsRepo;
  final DateTime? now;
  final ValueChanged<String>? onOpen;
  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  late final repo = widget.repo ?? SupabaseFinanceHomeRepo(AppDI.supabase);
  late DateTime month = DateTime(
    (widget.now ?? DateTime.now()).year,
    (widget.now ?? DateTime.now()).month,
  );
  final scroll = ScrollController();
  FinanceHomeData? data;
  Object? error;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await repo.load(month);
      if (mounted) {
        setState(() {
          data = result;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    }
  }

  void open(String route) =>
      widget.onOpen != null ? widget.onOpen!(route) : context.go(route);
  String tr(String ar, String en) => accountingText(context, ar, en);
  Widget action(String ar, String en, IconData icon, String route) =>
      OutlinedButton.icon(
        onPressed: () => open(route),
        icon: Icon(icon, size: 18),
        label: Text(tr(ar, en)),
      );
  Widget metric(
    String label,
    String value,
    String caption,
    IconData icon,
    String route, {
    bool failed = false,
  }) => accountingPanel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFF0E5FF),
              child: Icon(
                icon,
                color: accountingPurple,
                textDirection: icon == Icons.send_outlined
                    ? TextDirection.ltr
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: accountingInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value,
          key: ValueKey(label),
          style: TextStyle(
            fontSize: failed ? 16 : 30,
            color: accountingInk,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          style: const TextStyle(color: Color(0xFF77709A), fontSize: 13),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: failed ? load : () => open(route),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  tr(
                    failed ? 'إعادة المحاولة' : 'عرض التفاصيل',
                    failed ? 'Retry' : 'View details',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                failed
                    ? Icons.refresh
                    : Localizations.localeOf(context).languageCode == 'ar'
                    ? Icons.arrow_back
                    : Icons.arrow_forward,
                size: 18,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget section(
    String title,
    String subtitle,
    Widget child, {
    Widget? trailing,
  }) => accountingPanel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: accountingInk,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF77709A), fontSize: 13),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
  Widget failed(Object? e) => AppFailureState(error: e, onRetry: load);
  Widget highlight(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: color.withValues(alpha: .2)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (loading) return const AppLoadingState();
    if (error != null) return AppFailureState(error: error, onRetry: load);
    final d = data!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final journal = d.journal.value ?? [];
    final draftCount = journal.where((j) => j['status'] == 'draft').length;
    final pending = d.isManager
        ? d.reviewRuns
        : (d.runs.value ?? [])
              .where(
                (r) => r.status == 'approved' && r.disbursementStatus != 'paid',
              )
              .toList();
    final work = d.isManager ? [...d.reviewRuns, ...d.assignRuns] : pending;
    final metrics = [
      metric(
        tr(
          d.isManager ? 'مسيرات تنتظر مراجعتك' : 'مسيرات مسندة إليك',
          d.isManager ? 'Payroll awaiting review' : 'Payroll assigned to you',
        ),
        d.runs.error != null
            ? tr('تعذر التحميل', 'Unavailable')
            : '${pending.length}',
        tr('جميع الفترات غير المنتهية', 'Across outstanding periods'),
        Icons.request_quote_outlined,
        AppRoutes.payroll,
        failed: d.runs.error != null,
      ),
      if (d.isManager)
        metric(
          tr('جاهزة لإسناد الصرف', 'Ready for assignment'),
          d.runs.error != null
              ? tr('تعذر التحميل', 'Unavailable')
              : '${d.assignRuns.length}',
          tr(
            'مسيرات معتمدة تنتظر تكليف محاسب',
            'Approved payroll awaiting an accountant',
          ),
          Icons.send_outlined,
          AppRoutes.payroll,
          failed: d.runs.error != null,
        ),
      metric(
        tr('مسودات القيود', 'Journal drafts'),
        d.journal.error != null
            ? tr('تعذر التحميل', 'Unavailable')
            : '$draftCount',
        payrollPeriod(month, ar),
        Icons.menu_book_outlined,
        AppRoutes.journal,
        failed: d.journal.error != null,
      ),
      metric(
        tr('الحسابات النشطة', 'Active accounts'),
        d.accounts.error != null
            ? tr('تعذر التحميل', 'Unavailable')
            : '${d.accounts.value!.length}',
        tr('الحسابات المتاحة لإنشاء القيود', 'Available for new entries'),
        Icons.account_balance_outlined,
        AppRoutes.accounts,
        failed: d.accounts.error != null,
      ),
    ];
    return Scrollbar(
      controller: scroll,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7550B2), Color(0xFFAA85CE)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(
                      d.isManager ? 'لوحة مدير المالية' : 'لوحة المحاسب',
                      d.isManager
                          ? 'Finance manager dashboard'
                          : 'Accountant dashboard',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'أهلًا ${d.name}، تابع الرواتب والقيود وأعمالك من مكان واحد.',
                      'Welcome ${d.name}. Follow payroll, journals and your work in one place.',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FinanceAccountingKpis(
              repo: widget.reportsRepo ?? AppDI.accountingReportsRepo,
              initialMonth: month,
              onOpen: open,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => open('${AppRoutes.journal}?new=1'),
                  icon: const Icon(Icons.add),
                  label: Text(tr('قيد يومي جديد', 'New journal entry')),
                ),
                action(
                  'دليل الحسابات',
                  'Chart of accounts',
                  Icons.account_balance_outlined,
                  AppRoutes.accounts,
                ),
                action(
                  'الموافقات',
                  'Approvals',
                  Icons.fact_check_outlined,
                  AppRoutes.approvals,
                ),
                if (d.isManager)
                  action(
                    'فريق المالية',
                    'Finance team',
                    Icons.groups_outlined,
                    AppRoutes.financeTeam,
                  ),
                IconButton(
                  key: const Key('finance-home-refresh'),
                  tooltip: tr('تحديث البيانات', 'Refresh'),
                  onPressed: load,
                  icon: const Icon(Icons.refresh, color: accountingPurple),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (_, box) {
                final columns = box.maxWidth >= 1050
                    ? metrics.length
                    : box.maxWidth >= 650
                    ? 2
                    : 1;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: metrics
                      .map(
                        (m) => SizedBox(
                          width: (box.maxWidth - 12 * (columns - 1)) / columns,
                          child: m,
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            section(
              tr('أعمال الرواتب المطلوبة', 'Payroll requiring action'),
              tr(
                'افتح المسير لمراجعته أو متابعة الصرف حسب حالته.',
                'Open a run to review it or follow disbursement according to its status.',
              ),
              d.runs.error != null
                  ? failed(d.runs.error)
                  : work.isEmpty
                  ? Text(
                      tr(
                        'لا توجد مسيرات تتطلب إجراء منك حاليًا.',
                        'No payroll currently requires your action.',
                      ),
                    )
                  : Column(
                      children: [
                        for (final r in work.take(6))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F6FD),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Wrap(
                                spacing: 22,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    payrollPeriod(r.periodStart, ar),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: accountingInk,
                                    ),
                                  ),
                                  Text(
                                    '${payrollMoney(r.totalAmount)} ${tr('ريال', 'SAR')}',
                                  ),
                                  Text(
                                    '${r.totalEmployees} ${tr('موظف', 'employees')}',
                                  ),
                                  accountingBadge(
                                    tr(
                                      r.status == 'pending_finance_manager'
                                          ? 'بانتظار المراجعة'
                                          : 'معتمد من الإدارة',
                                      r.status == 'pending_finance_manager'
                                          ? 'Awaiting review'
                                          : 'Approved',
                                    ),
                                  ),
                                  FilledButton.tonalIcon(
                                    key: ValueKey('open-run-${r.id}'),
                                    onPressed: () => open(
                                      '/payroll/${r.id}${d.isManager && r.status == 'approved' ? '?disbursement=1' : ''}',
                                    ),
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                    ),
                                    label: Text(
                                      tr(
                                        d.isManager && r.status == 'approved'
                                            ? 'إسناد الصرف'
                                            : 'فتح المسير',
                                        d.isManager && r.status == 'approved'
                                            ? 'Assign disbursement'
                                            : 'Open payroll',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
              trailing: TextButton(
                onPressed: () => open(AppRoutes.payroll),
                child: Text(tr('كل الرواتب', 'All payroll')),
              ),
            ),
            const SizedBox(height: 16),
            section(
              tr('القيود اليومية لهذا الشهر', 'Journal entries this month'),
              tr(
                'ملخص تسجيل القيود؛ المبالغ هنا ليست رصيد البنك أو أرباح الشركة.',
                'Journal activity; these amounts are not bank balances or company profits.',
              ),
              d.journal.error != null
                  ? failed(d.journal.error)
                  : journal.isEmpty
                  ? highlight(
                      tr(
                        'لا توجد قيود في الشهر المحدد.',
                        'No entries for the selected month.',
                      ),
                      Icons.menu_book_outlined,
                      accountingPurple,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        highlight(
                          tr(
                            '${journal.length} قيد خلال الشهر',
                            '${journal.length} entries this month',
                          ),
                          Icons.menu_book_outlined,
                          accountingPurple,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 330,
                          child: AccountingTable(
                            headings: [
                              tr('التاريخ', 'Date'),
                              tr('البيان', 'Memo'),
                              tr('مدين', 'Debit'),
                              tr('دائن', 'Credit'),
                              tr('الحالة', 'Status'),
                            ],
                            widths: const [2, 4, 2, 2, 2],
                            rows: journal
                                .take(10)
                                .map(
                                  (j) => <Widget>[
                                    Text(
                                      (j['entry_date'] ?? '').toString(),
                                      textDirection: TextDirection.ltr,
                                    ),
                                    SelectableText(
                                      (j['memo'] ?? '').toString(),
                                    ),
                                    Text(
                                      payrollMoney(
                                        (j['total_debit'] ?? 0) as num,
                                      ),
                                    ),
                                    Text(
                                      payrollMoney(
                                        (j['total_credit'] ?? 0) as num,
                                      ),
                                    ),
                                    accountingBadge(
                                      tr(
                                        j['status'] == 'posted'
                                            ? 'مرحّل'
                                            : 'مسودة',
                                        j['status'] == 'posted'
                                            ? 'Posted'
                                            : 'Draft',
                                      ),
                                    ),
                                  ],
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
              trailing: OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: month,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (selected != null && mounted) {
                    month = DateTime(selected.year, selected.month);
                    await load();
                  }
                },
                icon: const Icon(Icons.calendar_month, size: 18),
                label: Text(payrollPeriod(month, ar)),
              ),
            ),
            const SizedBox(height: 16),
            section(
              tr('موافقات تنتظر دورك', 'Approvals awaiting your role'),
              tr(
                'العدد يشمل الطلبات المعلقة الموجهة لصلاحية حسابك.',
                'Pending requests assigned to your account role.',
              ),
              d.approvals.error != null
                  ? failed(d.approvals.error)
                  : highlight(
                      tr(
                        '${d.approvals.value} طلب معلق',
                        '${d.approvals.value} pending requests',
                      ),
                      d.approvals.value! > 0
                          ? Icons.pending_actions
                          : Icons.check_circle_outline,
                      d.approvals.value! > 0
                          ? const Color(0xFFAA6100)
                          : const Color(0xFF16845D),
                    ),
              trailing: TextButton(
                onPressed: () => open(AppRoutes.approvals),
                child: Text(tr('فتح الموافقات', 'Open approvals')),
              ),
            ),
            if (d.isManager) ...[
              const SizedBox(height: 16),
              section(
                tr('فريق المالية', 'Finance team'),
                tr(
                  'الموظفون النشطون المرتبطون بك مباشرة أو بالقسم الذي تديره.',
                  'Active employees reporting to you directly or through a department you manage.',
                ),
                d.team.error != null
                    ? failed(d.team.error)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          highlight(
                            tr(
                              '${d.team.value!.length} موظف في فريق المالية',
                              '${d.team.value!.length} finance team members',
                            ),
                            Icons.groups_outlined,
                            const Color(0xFF2568A5),
                          ),
                          const SizedBox(height: 14),
                          d.team.value!.isEmpty
                              ? Text(
                                  tr(
                                    'لا يوجد موظفون مرتبطون بك حاليًا. راجع تعيين المدير المباشر في بيانات الموظفين.',
                                    'No employees report to you yet. Check their reporting manager assignments.',
                                  ),
                                )
                              : Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    for (final m in d.team.value!.take(6))
                                      ActionChip(
                                        backgroundColor: const Color(
                                          0xFFF0F5FC,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        labelStyle: const TextStyle(
                                          color: Color(0xFF2568A5),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        avatar: FinanceEmployeeAvatar(
                                          name: m.name,
                                          photoUrl: m.photoUrl,
                                          radius: 14,
                                        ),
                                        label: Text(
                                          '${m.name} • ${m.openTasks} ${tr('مهمة', 'tasks')}',
                                        ),
                                        onPressed: () => open(
                                          '${AppRoutes.financeTeam}?employeeId=${Uri.encodeQueryComponent(m.id)}',
                                        ),
                                      ),
                                  ],
                                ),
                        ],
                      ),
                trailing: TextButton(
                  onPressed: () => open(AppRoutes.financeTeam),
                  child: Text(tr('عرض الفريق', 'View team')),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              tr(
                'مسار الرواتب: الموارد البشرية ← مراجعة المالية ← اعتماد الإدارة ← إسناد الصرف للمحاسب ← إثبات الصرف.',
                'Payroll: HR → Finance review → Management approval → Accountant assignment → Payment evidence.',
              ),
              style: const TextStyle(color: Color(0xFF77709A)),
            ),
          ],
        ),
      ),
    );
  }
}

class FinanceTeamPage extends StatefulWidget {
  const FinanceTeamPage({super.key, this.repo, this.employeeId});
  final FinanceHomeRepo? repo;
  final String? employeeId;
  @override
  State<FinanceTeamPage> createState() => _FinanceTeamPageState();
}

class _FinanceTeamPageState extends State<FinanceTeamPage> {
  late final repo = widget.repo ?? SupabaseFinanceHomeRepo(AppDI.supabase);
  final scroll = ScrollController();
  List<FinanceTeamMember>? members;
  Object? error;
  bool loading = true;
  String search = '';
  String? selected;
  @override
  void initState() {
    super.initState();
    selected = widget.employeeId;
    load();
  }

  @override
  void didUpdateWidget(covariant FinanceTeamPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.employeeId != widget.employeeId) selected = widget.employeeId;
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await repo.loadTeam();
      if (mounted) {
        setState(() {
          members = result;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    }
  }

  String tr(String ar, String en) => accountingText(context, ar, en);
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    if (loading) return const AppLoadingState();
    if (error != null) return AppFailureState(error: error, onRetry: load);
    final matches = members!
        .where(
          (m) => '${m.name} ${m.number} ${m.job}'.toLowerCase().contains(
            search.toLowerCase(),
          ),
        )
        .toList();
    final member = members!.where((m) => m.id == selected).firstOrNull;
    return Scrollbar(
      controller: scroll,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.all(16),
        child: accountingPanel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              accountingHeading(
                tr('فريق المالية', 'Finance team'),
                tr(
                  'عرض الموظفين التابعين لك ومتابعة مهامهم.',
                  'View your reporting employees and follow their tasks.',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration:
                    accountingInput(
                      tr(
                        'ابحث بالاسم أو الرقم أو الوظيفة',
                        'Search by name, number or job',
                      ),
                    ).copyWith(
                      prefixIcon: const Icon(
                        Icons.search,
                        color: accountingPurple,
                      ),
                    ),
                onChanged: (value) => setState(() => search = value),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: load,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(120, 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      foregroundColor: accountingPurple,
                      side: const BorderSide(color: accountingBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: Text(tr('تحديث', 'Refresh')),
                  ),
                  if (selected == null)
                    accountingBadge(
                      tr(
                        '${matches.length} موظف',
                        '${matches.length} employees',
                      ),
                    ),
                  if (selected != null)
                    TextButton(
                      onPressed: () => setState(() => selected = null),
                      child: Text(tr('العودة للقائمة', 'Back to list')),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (selected != null && member == null)
                Text(
                  tr(
                    'الموظف غير موجود ضمن فريقك النشط.',
                    'Employee is not in your active team.',
                  ),
                ),
              if (member == null && selected == null) ...[
                if (matches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      tr(
                        members!.isEmpty
                            ? 'لا يوجد موظفون مرتبطون بك حاليًا.'
                            : 'لا توجد نتائج مطابقة للبحث.',
                        members!.isEmpty
                            ? 'No employees currently report to you.'
                            : 'No matching employees.',
                      ),
                    ),
                  ),
                for (final m in matches)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: accountingPanel(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              FinanceEmployeeAvatar(
                                name: m.name,
                                photoUrl: m.photoUrl,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  m.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: accountingInk,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('${m.number} • ${m.job}'),
                          if (m.jobLevel != null)
                            Text(
                              jobLevelLabel(m.jobLevel, isArabic: ar),
                              style: const TextStyle(
                                color: Color(0xFF8659BB),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const SizedBox(height: 10),
                          accountingBadge(
                            tr(
                              '${m.openTasks} مهمة غير منتهية',
                              '${m.openTasks} outstanding tasks',
                            ),
                            active: m.openTasks > 0,
                          ),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            key: ValueKey('view-member-${m.id}'),
                            onPressed: () => setState(() => selected = m.id),
                            icon: const Icon(Icons.visibility_outlined),
                            label: Text(
                              tr(
                                'عرض الموظف ومهامه',
                                'View employee and tasks',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              if (member != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    FinanceEmployeeAvatar(
                      name: member.name,
                      photoUrl: member.photoUrl,
                      radius: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: accountingHeading(
                        member.name,
                        '${member.number} • ${member.job}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  tr('مهام الموظف', 'Employee tasks'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (member.tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      tr(
                        'لا توجد مهام مسندة لهذا الموظف.',
                        'No tasks assigned to this employee.',
                      ),
                    ),
                  ),
                if (member.tasks.isNotEmpty)
                  SizedBox(
                    height: 420,
                    child: AccountingTable(
                      headings: [
                        tr('المهمة', 'Task'),
                        tr('الحالة', 'Status'),
                        tr('تاريخ الاستحقاق', 'Due date'),
                      ],
                      widths: const [5, 2, 2],
                      rows: member.tasks
                          .map(
                            (t) => <Widget>[
                              SelectableText((t['title'] ?? '').toString()),
                              accountingBadge(switch (t['status']) {
                                'done' => tr('منتهية', 'Done'),
                                'in_progress' => tr(
                                  'قيد التنفيذ',
                                  'In progress',
                                ),
                                'todo' => tr('لم تبدأ', 'Not started'),
                                _ => tr(
                                  'بانتظار المتابعة',
                                  'Awaiting follow-up',
                                ),
                              }),
                              Text(
                                (t['due_date'] ?? '—').toString(),
                                textDirection: TextDirection.ltr,
                              ),
                            ],
                          )
                          .toList(),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
