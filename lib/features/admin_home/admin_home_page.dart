import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/app_di.dart';
import '../../core/routing/app_routes.dart';
import '../../core/ui/app_data_state.dart';
import '../accounting/view/accounting_ui.dart';
import '../payroll/view/widgets/payroll_format.dart';
import 'admin_home_repo.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key, this.repo, this.now, this.onOpen});
  final AdminHomeRepo? repo;
  final DateTime? now;
  final ValueChanged<String>? onOpen;
  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  late final repo = widget.repo ?? SupabaseAdminHomeRepo(AppDI.supabase);
  late DateTime month = DateTime(
    (widget.now ?? DateTime.now()).year,
    (widget.now ?? DateTime.now()).month,
  );
  final scroll = ScrollController();
  AdminHomeData? data;
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

  String tr(String ar, String en) => accountingText(context, ar, en);
  void open(String route) =>
      widget.onOpen != null ? widget.onOpen!(route) : context.go(route);
  Widget link(String label, String route) => TextButton(
    onPressed: () => open(route),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(label)),
        const SizedBox(width: 8),
        Icon(
          Localizations.localeOf(context).languageCode == 'ar'
              ? Icons.arrow_back
              : Icons.arrow_forward,
          size: 18,
          textDirection: TextDirection.ltr,
        ),
      ],
    ),
  );
  Widget section(
    String title,
    String subtitle,
    Widget child, {
    Widget? action,
  }) => accountingPanel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: accountingInk,
              ),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF77709A), fontSize: 13),
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
  Widget summary(
    String text,
    IconData icon, {
    Color color = accountingPurple,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  Widget metric(
    String label,
    int value,
    Object? failure,
    String caption,
    IconData icon,
    String route,
    Color color,
  ) => accountingPanel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: accountingInk,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          failure == null ? '$value' : tr('تعذر التحميل', 'Unavailable'),
          style: TextStyle(
            fontSize: failure == null ? 32 : 17,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          style: const TextStyle(color: Color(0xFF77709A), fontSize: 13),
        ),
        const SizedBox(height: 10),
        if (failure == null)
          link(tr('عرض التفاصيل', 'View details'), route)
        else
          TextButton.icon(
            onPressed: load,
            icon: const Icon(Icons.refresh),
            label: Text(tr('إعادة المحاولة', 'Retry')),
          ),
      ],
    ),
  );
  Widget failure(Object? e) => AppFailureState(error: e, onRetry: load);
  Widget quick(String label, IconData icon, String route) =>
      OutlinedButton.icon(
        onPressed: () => open(route),
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          minimumSize: const Size(0, 46),
        ),
      );
  String requestType(String value) => switch (value) {
    'leave' => tr('طلب إجازة', 'Leave request'),
    'attendance_correction' => tr('تصحيح الحضور', 'Attendance correction'),
    'payroll_run' => tr('مسير رواتب', 'Payroll run'),
    _ => tr('طلب للمراجعة', 'Request for review'),
  };
  @override
  Widget build(BuildContext context) {
    if (loading) return const AppLoadingState();
    if (error != null) return AppFailureState(error: error, onRetry: load);
    final d = data!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final runs = d.payroll.value ?? [];
    final journal = d.journal.value ?? [];
    final activeUsers =
        d.users.value?.where((u) => u['is_active'] == true).length ?? 0;
    final waiting = d.awaitingApproval;
    final metrics = [
      metric(
        tr('رواتب تنتظر اعتمادك', 'Payroll awaiting your approval'),
        waiting.length,
        d.payroll.error,
        tr('كل الفترات بانتظار الإدارة', 'All periods awaiting management'),
        Icons.request_quote_outlined,
        AppRoutes.payroll,
        const Color(0xFFAA6100),
      ),
      metric(
        tr('طلبات تنتظر قرارك', 'Requests awaiting your decision'),
        d.otherApprovals.length,
        d.approvals.error,
        tr(
          'طلبات أخرى بخلاف مسيرات الرواتب',
          'Requests excluding payroll runs',
        ),
        Icons.fact_check_outlined,
        AppRoutes.approvals,
        accountingPurple,
      ),
      metric(
        tr('الموظفون النشطون', 'Active employees'),
        d.activeEmployees,
        d.employees.error,
        tr('فريق الشركة الحالي', 'Current company employees'),
        Icons.groups_outlined,
        AppRoutes.employees,
        const Color(0xFF2568A5),
      ),
      metric(
        tr('الحسابات المفعّلة', 'Enabled user accounts'),
        activeUsers,
        d.users.error,
        tr(
          'حسابات المستخدمين داخل النظام',
          'Enabled application user accounts',
        ),
        Icons.manage_accounts_outlined,
        AppRoutes.userManagement,
        const Color(0xFF16845D),
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
                    tr('لوحة إدارة الشركة', 'Company administration dashboard'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'أهلًا ${d.name}، تابع ما ينتظر قرارك وأعمال الشركة من مكان واحد.',
                      'Welcome ${d.name}. Follow decisions awaiting you and company activity in one place.',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => open(AppRoutes.approvals),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(tr('فتح الموافقات', 'Open approvals')),
                ),
                quick(
                  tr('إضافة موظف', 'Add employee'),
                  Icons.person_add_alt_1,
                  AppRoutes.employeeCreate,
                ),
                quick(
                  tr('المستخدمون والصلاحيات', 'Users and permissions'),
                  Icons.manage_accounts_outlined,
                  AppRoutes.userManagement,
                ),
                quick(
                  tr('دليل الحسابات', 'Chart of accounts'),
                  Icons.account_balance_outlined,
                  AppRoutes.accounts,
                ),
                OutlinedButton.icon(
                  key: const Key('admin-home-refresh'),
                  onPressed: load,
                  icon: const Icon(Icons.refresh),
                  label: Text(tr('تحديث البيانات', 'Refresh data')),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (_, box) {
                final columns = box.maxWidth >= 1050
                    ? 4
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
            const SizedBox(height: 18),
            section(
              tr(
                'مسيرات بانتظار اعتماد الإدارة',
                'Payroll awaiting management approval',
              ),
              tr(
                'راجع تفاصيل المسير قبل اتخاذ القرار. الاعتماد يتم من صفحة المسير.',
                'Review the payroll details before deciding. Approval takes place on the payroll page.',
              ),
              d.payroll.error != null
                  ? failure(d.payroll.error)
                  : waiting.isEmpty
                  ? summary(
                      tr(
                        'لا توجد مسيرات تنتظر اعتمادك حاليًا.',
                        'No payroll currently awaits your approval.',
                      ),
                      Icons.check_circle_outline,
                      color: const Color(0xFF16845D),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        summary(
                          tr(
                            '${payrollMoney(waiting.fold<num>(0, (sum, r) => sum + r.totalAmount))} ريال بانتظار الاعتماد',
                            'SAR ${payrollMoney(waiting.fold<num>(0, (sum, r) => sum + r.totalAmount))} awaiting approval',
                          ),
                          Icons.pending_actions,
                          color: const Color(0xFFAA6100),
                        ),
                        const SizedBox(height: 14),
                        for (final r in waiting.take(6))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F6FD),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Wrap(
                                spacing: 20,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    payrollPeriod(r.periodStart, ar),
                                    style: const TextStyle(
                                      color: accountingInk,
                                      fontWeight: FontWeight.w700,
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
                                      'بانتظار اعتماد الإدارة',
                                      'Awaiting management approval',
                                    ),
                                  ),
                                  TextButton(
                                    key: ValueKey('admin-open-run-${r.id}'),
                                    onPressed: () => open('/payroll/${r.id}'),
                                    child: Text(
                                      tr(
                                        'مراجعة واعتماد',
                                        'Review and approve',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
              action: link(tr('كل الرواتب', 'All payroll'), AppRoutes.payroll),
            ),
            const SizedBox(height: 18),
            section(
              tr(
                'طلبات أخرى تنتظر قرارك',
                'Other requests awaiting your decision',
              ),
              tr(
                'أقدم الطلبات أولًا، وتظهر هنا الطلبات الموجّهة للإدارة فقط.',
                'Oldest first. Only requests assigned to management appear here.',
              ),
              d.approvals.error != null
                  ? failure(d.approvals.error)
                  : d.otherApprovals.isEmpty
                  ? summary(
                      tr(
                        'لا توجد طلبات أخرى تنتظر قرارك.',
                        'No other requests await your decision.',
                      ),
                      Icons.check_circle_outline,
                      color: const Color(0xFF16845D),
                    )
                  : SizedBox(
                      height: 300,
                      child: AccountingTable(
                        minimumWidth: 700,
                        headings: [
                          tr('الطلب', 'Request'),
                          tr('الموظف', 'Employee'),
                          tr('تاريخ الطلب', 'Created'),
                          tr('الإجراء', 'Action'),
                        ],
                        widths: const [3, 4, 2, 2],
                        rows: d.otherApprovals
                            .take(10)
                            .map(
                              (a) => <Widget>[
                                Text(
                                  requestType(
                                    (a['request_type'] ?? '').toString(),
                                  ),
                                ),
                                Text(
                                  d.employees.value
                                          ?.where(
                                            (e) => e['id'] == a['employee_id'],
                                          )
                                          .firstOrNull?['full_name']
                                          ?.toString() ??
                                      tr('غير متاح', 'Unavailable'),
                                ),
                                Text(
                                  (a['created_at'] ?? '')
                                      .toString()
                                      .split('T')
                                      .first
                                      .split(' ')
                                      .first,
                                  textDirection: TextDirection.ltr,
                                ),
                                link(
                                  tr('فتح الموافقات', 'Open approvals'),
                                  AppRoutes.approvals,
                                ),
                              ],
                            )
                            .toList(),
                      ),
                    ),
              action: link(
                tr('كل الموافقات', 'All approvals'),
                AppRoutes.approvals,
              ),
            ),
            const SizedBox(height: 18),
            section(
              tr('ملخص الفترة', 'Period overview'),
              tr(
                'الشهر يحدد ملخص القيود والرواتب فقط؛ الطلبات المنتظرة تشمل جميع الفترات.',
                'Month applies to journal and payroll summaries; pending decisions include all periods.',
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (d.journal.error != null)
                    failure(d.journal.error)
                  else
                    summary(
                      tr(
                        '${journal.length} قيد • ${journal.where((j) => j['status'] == 'draft').length} مسودة • ${journal.where((j) => j['status'] == 'posted').length} مرحّل',
                        '${journal.length} entries • ${journal.where((j) => j['status'] == 'draft').length} drafts • ${journal.where((j) => j['status'] == 'posted').length} posted',
                      ),
                      Icons.menu_book_outlined,
                    ),
                  const SizedBox(height: 12),
                  if (d.payroll.error != null)
                    failure(d.payroll.error)
                  else
                    summary(
                      tr(
                        '${runs.where((r) => r.periodStart.year == month.year && r.periodStart.month == month.month).length} مسير رواتب للفترة المحددة',
                        '${runs.where((r) => r.periodStart.year == month.year && r.periodStart.month == month.month).length} payroll runs for the selected period',
                      ),
                      Icons.request_quote_outlined,
                      color: const Color(0xFF2568A5),
                    ),
                  const SizedBox(height: 10),
                  link(
                    tr('فتح القيود اليومية', 'Open journal entries'),
                    AppRoutes.journal,
                  ),
                ],
              ),
              action: OutlinedButton.icon(
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
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: Text(payrollPeriod(month, ar)),
              ),
            ),
            const SizedBox(height: 18),
            section(
              tr('الموظفون والأقسام', 'Employees and departments'),
              tr(
                'توزيع الموظفين النشطين حسب القسم.',
                'Active employee distribution by department.',
              ),
              d.employees.error != null
                  ? failure(d.employees.error)
                  : d.departments.error != null
                  ? failure(d.departments.error)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        summary(
                          tr(
                            '${d.activeEmployees} موظف نشط • ${d.employees.value!.where((e) => e['status'] == 'inactive').length} غير نشط',
                            '${d.activeEmployees} active employees • ${d.employees.value!.where((e) => e['status'] == 'inactive').length} inactive',
                          ),
                          Icons.groups_outlined,
                          color: const Color(0xFF2568A5),
                        ),
                        const SizedBox(height: 16),
                        for (final department in d.departments.value!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '${department['name']} • ${d.employees.value!.where((e) => e['status'] == 'active' && e['department_id'] == department['id']).length} ${tr('موظف', 'employees')}',
                                  style: const TextStyle(
                                    color: accountingInk,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    minHeight: 8,
                                    color: accountingPurple,
                                    backgroundColor: const Color(0xFFF0E5FF),
                                    value: d.activeEmployees == 0
                                        ? 0
                                        : d.employees.value!
                                                  .where(
                                                    (e) =>
                                                        e['status'] ==
                                                            'active' &&
                                                        e['department_id'] ==
                                                            department['id'],
                                                  )
                                                  .length /
                                              d.activeEmployees,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (d.employees.value!.any(
                          (e) =>
                              e['status'] == 'active' &&
                              !d.departments.value!.any(
                                (dep) => dep['id'] == e['department_id'],
                              ),
                        ))
                          Text(
                            tr(
                              'يوجد موظفون نشطون دون قسم ظاهر في القائمة.',
                              'Some active employees have no department listed.',
                            ),
                          ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            link(
                              tr('إدارة الموظفين', 'Manage employees'),
                              AppRoutes.employees,
                            ),
                            link(
                              tr('إدارة الأقسام', 'Manage departments'),
                              AppRoutes.departments,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 18),
            section(
              tr('إدارة الوصول للنظام', 'System access management'),
              tr(
                'راجع أدوار الحسابات وحالتها من شاشة المستخدمين والصلاحيات.',
                'Review account roles and status on the users and permissions page.',
              ),
              d.users.error != null
                  ? failure(d.users.error)
                  : summary(
                      tr(
                        '$activeUsers حساب مفعّل • ${d.users.value!.where((u) => u['is_active'] != true).length} حساب موقوف',
                        '$activeUsers enabled accounts • ${d.users.value!.where((u) => u['is_active'] != true).length} disabled accounts',
                      ),
                      Icons.manage_accounts_outlined,
                      color: const Color(0xFF16845D),
                    ),
              action: link(
                tr('إدارة المستخدمين', 'Manage users'),
                AppRoutes.userManagement,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
