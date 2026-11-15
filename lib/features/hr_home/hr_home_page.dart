import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/app_di.dart';
import '../../core/routing/app_routes.dart';
import '../../core/ui/employee_theme.dart';
import '../../l10n/app_localizations.dart';
import 'hr_home_repo.dart';

class HrHomePage extends StatefulWidget {
  const HrHomePage({super.key, this.repo});
  final HrHomeRepo? repo;
  @override
  State<HrHomePage> createState() => _HrHomePageState();
}

class _HrHomePageState extends State<HrHomePage> {
  late final HrHomeRepo _repo =
      widget.repo ?? SupabaseHrHomeRepo(AppDI.supabase);
  late Future<HrHomeData> _future = _repo.load(DateTime.now());
  void _refresh() {
    final future = _repo.load(DateTime.now());
    setState(() {
      _future = future;
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<HrHomeData>(
    future: _future,
    builder: (context, snapshot) {
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const AppLoadingState();
      }
      if (snapshot.hasError) {
        return AppFailureState(
          error: snapshot.error,
          onRetry: _refresh,
          title: ar
              ? 'تعذر تحميل لوحة الموارد البشرية'
              : 'Could not load the HR dashboard',
        );
      }
      return HrHomeView(data: snapshot.data!, onRefresh: _refresh);
    },
  );
}

class HrHomeView extends StatelessWidget {
  const HrHomeView({
    super.key,
    required this.data,
    required this.onRefresh,
    this.now,
  });
  final HrHomeData data;
  final VoidCallback onRefresh;
  final DateTime? now;
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String a, String e) => ar ? a : e;
    final today = now ?? DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final colors = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    void open(String route) => context.go(route);
    Widget panel(Widget child) => Card(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
    Widget cell(
      String value, {
      bool number = false,
      Color? color,
      bool bold = false,
    }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        value,
        textAlign: TextAlign.center,
        textDirection: number ? TextDirection.ltr : null,
        style: TextStyle(
          fontSize: 13,
          height: 1.45,
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
    Widget table(
      String title,
      List<String> headers,
      List<TableRow> rows,
      String route,
    ) => panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => open(route),
                child: Text(tr('عرض الكل', 'View all')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                tr('لا توجد بيانات للعرض حاليًا', 'Nothing to show right now'),
                textAlign: TextAlign.center,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: box.maxWidth < 500 ? 500 : box.maxWidth,
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: .3),
                      ),
                    ),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: EmployeeTheme.primary.withValues(alpha: .06),
                        ),
                        children: headers
                            .map((h) => cell(h, bold: true))
                            .toList(),
                      ),
                      ...rows,
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    String employee(Map<String, dynamic> row) =>
        row['employee'] is Map ? '${row['employee']['full_name'] ?? '—'}' : '—';
    String date(dynamic raw) {
      final value = DateTime.tryParse('$raw');
      return value == null ? '—' : hrHomeDate(value).replaceAll('-', '/');
    }

    String docLabel(String type) => switch (type) {
      'id_card' => t.idCard,
      'passport' => t.passport,
      'residency' => t.residencyDocument,
      'driving_license' => t.drivingLicense,
      'contract' => t.contract,
      'medical_insurance' => t.medicalInsurance,
      _ => t.documentLabel,
    };
    Widget documents() => table(
      tr('مستندات تنتهي قريبًا', 'Documents expiring soon'),
      [
        tr('الموظف', 'Employee'),
        tr('نوع المستند', 'Document'),
        tr('تاريخ الانتهاء', 'Expiry'),
        tr('الأيام المتبقية', 'Days left'),
      ],
      data.documents.take(5).map((r) {
        final expiry = DateTime.tryParse('${r['expires_at']}');
        final remaining = expiry == null
            ? null
            : DateTime(
                expiry.year,
                expiry.month,
                expiry.day,
              ).difference(day).inDays;
        final color = remaining != null && remaining <= 4
            ? const Color(0xFFF04464)
            : EmployeeTheme.primary;
        return TableRow(
          children: [
            cell(employee(r)),
            cell(docLabel('${r['doc_type']}')),
            cell(date(r['expires_at']), number: true),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  remaining == null
                      ? '—'
                      : remaining < 0
                      ? tr('منتهي', 'Expired')
                      : tr('$remaining يوم', '$remaining days'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ),
            ),
          ],
        );
      }).toList(),
      AppRoutes.employeeDocs,
    );
    Widget leaves() => table(
      tr('طلبات الإجازات المعلقة', 'Pending leave requests'),
      [
        tr('الموظف', 'Employee'),
        tr('نوع الإجازة', 'Leave type'),
        tr('من تاريخ', 'From'),
        tr('إلى تاريخ', 'To'),
        tr('الحالة', 'Status'),
      ],
      data.leaves.take(5).map((r) {
        final p = r['payload'] is Map ? r['payload'] as Map : const {};
        final type = '${p['leave_type'] ?? p['type'] ?? ''}';
        final label = switch (type) {
          'annual' => tr('إجازة سنوية', 'Annual leave'),
          'sick' => tr('إجازة مرضية', 'Sick leave'),
          'unpaid' => tr('بدون راتب', 'Unpaid leave'),
          'other' => tr('أخرى', 'Other'),
          _ => tr('إجازة', 'Leave'),
        };
        final hr = r['current_approver_role'] == 'hr';
        return TableRow(
          children: [
            cell(employee(r)),
            cell(label),
            cell(date(p['start_date']), number: true),
            cell(date(p['end_date']), number: true),
            cell(
              hr
                  ? tr('بانتظار مراجعتك', 'Your review')
                  : tr('بانتظار الاعتماد', 'Awaiting approval'),
              color: hr ? const Color(0xFFE38B00) : EmployeeTheme.primary,
            ),
          ],
        );
      }).toList(),
      AppRoutes.approvals,
    );
    Widget metric(
      String title,
      int value,
      String caption,
      IconData icon,
      Color color,
      String route,
      String action,
    ) => panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: .1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              '$value',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            caption,
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => open(route),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(action),
          ),
        ],
      ),
    );
    final metrics = [
      metric(
        tr('مخالفات الحضور', 'Attendance exceptions'),
        data.attendanceIssues,
        tr(
          'تأخير وغياب مسجلان هذا الأسبوع',
          'Recorded lateness and absence this week',
        ),
        Icons.schedule,
        const Color(0xFF644AFF),
        AppRoutes.attendance,
        tr('مراجعة المخالفات', 'Review attendance'),
      ),
      metric(
        tr('مستندات منتهية أو قادمة', 'Expired or expiring documents'),
        data.documents.length,
        tr('منتهية أو تنتهي خلال ٣٠ يومًا', 'Expired or due within 30 days'),
        Icons.description,
        const Color(0xFFF04464),
        AppRoutes.employeeDocs,
        tr('عرض المستندات', 'View documents'),
      ),
      metric(
        tr('الموظفون الجدد', 'New employees'),
        data.newEmployees,
        tr('انضموا هذا الشهر', 'Joined this month'),
        Icons.person_add_alt_1,
        const Color(0xFF0788E9),
        AppRoutes.employees,
        tr('عرض التفاصيل', 'View details'),
      ),
      metric(
        tr('إجمالي الموظفين', 'Total employees'),
        data.employees,
        tr('موظفو الشركة', 'Company employees'),
        Icons.groups,
        const Color(0xFF0788E9),
        AppRoutes.employees,
        tr('عرض الموظفين', 'View employees'),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: EmployeeTheme.primary.withValues(alpha: .12),
              child: const Icon(Icons.groups, color: EmployeeTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name.isEmpty
                        ? tr('أهلًا بك', 'Welcome')
                        : tr('أهلًا ${data.name}', 'Welcome ${data.name}'),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    tr(
                      'إليك أبرز معلومات الموارد البشرية',
                      'Your human resources overview',
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    MaterialLocalizations.of(context).formatFullDate(today),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: tr('تحديث', 'Refresh'),
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, box) {
            final count = box.maxWidth >= 1050
                ? 4
                : box.maxWidth >= 580
                ? 2
                : 1;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final metric in metrics)
                  SizedBox(
                    width: (box.maxWidth - 12 * (count - 1)) / count,
                    child: metric,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, box) => box.maxWidth >= 1050
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: documents()),
                    const SizedBox(width: 14),
                    Expanded(child: leaves()),
                  ],
                )
              : Column(
                  children: [documents(), const SizedBox(height: 14), leaves()],
                ),
        ),
        const SizedBox(height: 16),
        panel(
          LayoutBuilder(
            builder: (context, box) => Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 18,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: box.maxWidth >= 600
                      ? box.maxWidth - 240
                      : box.maxWidth,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.request_page,
                        color: EmployeeTheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('تجهيز مسير الرواتب', 'Prepare payroll'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              tr(
                                'إعداد ومتابعة مسير الشهر الحالي',
                                'Prepare and track the current payroll',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => open(AppRoutes.payroll),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(tr('بدء التجهيز', 'Start preparation')),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
