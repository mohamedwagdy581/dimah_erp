import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/session/session_cubit.dart';
import '../../core/routing/app_routes.dart';
import '../../core/ui/employee_theme.dart';
import '../../core/widgets/page_navigation_buttons.dart';
import '../../l10n/app_localizations.dart';
import '../attendance/domain/models/attendance_record.dart';
import '../employee_portal/view/widgets/employee_attendance_view.dart'
    show
        employeeAttendanceDate,
        employeeAttendanceDuration,
        employeeAttendanceStatus;
import 'manager_attendance_repo.dart';
import 'manager_attendance_cubit.dart';
import 'attendance_employee_avatar.dart';

class ManagerAttendancePage extends StatelessWidget {
  const ManagerAttendancePage({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<SessionCubit, SessionState>(
    builder: (context, state) {
      if (state is! SessionReady) {
        return const AppLoadingState();
      }
      if (!['manager', 'direct_manager'].contains(state.user.role)) {
        return const SizedBox.shrink();
      }
      return BlocProvider(
        create: (_) => ManagerAttendanceCubit(
          SupabaseManagerAttendanceRepo(Supabase.instance.client),
        )..load(),
        child: const ManagerAttendanceView(),
      );
    },
  );
}

class ManagerAttendanceView extends StatefulWidget {
  const ManagerAttendanceView({super.key});
  @override
  State<ManagerAttendanceView> createState() => _ManagerAttendanceViewState();
}

class _ManagerAttendanceViewState extends State<ManagerAttendanceView> {
  String _query = '', _status = 'all';
  String? _employee;
  int _page = 0;
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => ar ? a : e;
  Widget panel(Widget child) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: EmployeeTheme.primary.withValues(alpha: .15)),
    ),
    child: child,
  );
  void month(DateTime value) {
    setState(() {
      _employee = null;
      _page = 0;
    });
    context.read<ManagerAttendanceCubit>().load(value);
  }

  Widget badge(String status) {
    final color = switch (status) {
      'present' => const Color(0xFF009879),
      'late' => Colors.orange,
      'absent' => Colors.red,
      _ => EmployeeTheme.primary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        employeeAttendanceStatus(status, AppLocalizations.of(context)!),
        style: TextStyle(color: color, fontSize: 13),
      ),
    );
  }

  Widget clock(DateTime? time, DateTime date) => Text(
    time == null
        ? tr('غير مسجل', 'Not recorded')
        : '${time.toLocal().hour.toString().padLeft(2, '0')}:${time.toLocal().minute.toString().padLeft(2, '0')}${DateUtils.isSameDay(time.toLocal(), date) ? '' : '\n${employeeAttendanceDate(time.toLocal())}'}',
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    style: const TextStyle(fontSize: 14, height: 1.5),
  );
  Widget cell(Widget child, int flex) => Expanded(
    flex: flex,
    child: Center(child: child),
  );
  Widget recordRow(AttendanceRecord r, String? photoUrl) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: EmployeeTheme.primary.withValues(alpha: .12)),
      ),
    ),
    child: Row(
      children: [
        cell(
          Row(
            children: [
              AttendanceEmployeeAvatar(
                name: r.employeeName,
                photoUrl: photoUrl,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  r.employeeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          3,
        ),
        cell(
          Text(
            employeeAttendanceDate(r.date),
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 14),
          ),
          2,
        ),
        cell(clock(r.checkIn, r.date), 2),
        cell(clock(r.checkOut, r.date), 2),
        cell(
          Text(
            employeeAttendanceDuration(managerAttendanceDuration(r), ar),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          2,
        ),
        cell(badge(r.status), 2),
      ],
    ),
  );

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ManagerAttendanceCubit, ManagerAttendanceState>(
    builder: (context, state) {
      final cubit = context.read<ManagerAttendanceCubit>();
      final data = state.data;
      final duration = data.records.fold(
        Duration.zero,
        (value, r) => value + (managerAttendanceDuration(r) ?? Duration.zero),
      );
      final filtered = data.records
          .where(
            (r) =>
                (_employee == null || r.employeeId == _employee) &&
                (_status == 'all' || r.status == _status) &&
                '${r.employeeName} ${employeeAttendanceDate(r.date)} ${r.notes ?? ''}'
                    .toLowerCase()
                    .contains(_query.trim().toLowerCase()),
          )
          .toList();
      final pages = (filtered.length / 10).ceil().clamp(1, 100000);
      final page = _page.clamp(0, pages - 1);
      Widget metric(String label, String value, IconData icon, Color color) =>
          panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 25),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(label, style: const TextStyle(fontSize: 13, height: 1.5)),
              ],
            ),
          );
      final metrics = [
        metric(
          tr('أعضاء الفريق لهم سجلات', 'Team members with records'),
          '${data.records.map((r) => r.employeeId).toSet().length} / ${data.members.length}',
          Icons.groups_rounded,
          EmployeeTheme.primary,
        ),
        metric(
          tr('سجلات التأخير', 'Recorded late entries'),
          '${data.records.where((r) => r.status == 'late').length}',
          Icons.schedule,
          Colors.orange,
        ),
        metric(
          tr('سجلات الغياب', 'Recorded absence entries'),
          '${data.records.where((r) => r.status == 'absent').length}',
          Icons.event_busy,
          Colors.red,
        ),
        metric(
          tr('مدة الحضور المكتملة', 'Completed attendance duration'),
          employeeAttendanceDuration(duration, ar),
          Icons.timelapse,
          const Color(0xFF009879),
        ),
      ];
      final t = AppLocalizations.of(context)!;
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 30,
                color: EmployeeTheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('حضور الفريق', 'Team attendance'),
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      tr(
                        'ملخص حضور وانصراف فريقك في مكان واحد',
                        'Your team attendance and monthly summary',
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: tr('تحديث', 'Refresh'),
                onPressed: state.loading ? null : () => cubit.load(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 18),
          panel(
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 10,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PageNavigationButtons(
                      center: Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatMonthYear(state.month),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPrevious: state.loading
                          ? null
                          : () => month(
                              DateTime(state.month.year, state.month.month - 1),
                            ),
                      onNext: state.loading
                          ? null
                          : () => month(
                              DateTime(state.month.year, state.month.month + 1),
                            ),
                      previousTooltip: tr('الشهر السابق', 'Previous month'),
                      nextTooltip: tr('الشهر التالي', 'Next month'),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: state.loading ? null : () => month(DateTime.now()),
                  icon: const Icon(Icons.today, size: 19),
                  label: Text(tr('الشهر الحالي', 'Current month')),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.managerRequests),
                  icon: const Icon(Icons.fact_check_outlined, size: 19),
                  label: Text(
                    tr('طلبات تصحيح الفريق', 'Team correction requests'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (state.loading)
            const Padding(padding: EdgeInsets.all(36), child: AppLoadingState())
          else if (state.failed)
            AppFailureState(error: state.error, onRetry: () => cubit.load())
          else ...[
            LayoutBuilder(
              builder: (_, box) {
                final columns = box.maxWidth < 620
                    ? 1
                    : box.maxWidth < 1100
                    ? 2
                    : 4;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final item in metrics)
                      SizedBox(
                        width: (box.maxWidth - (columns - 1) * 14) / columns,
                        child: item,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr('ملخص الموظفين', 'Employee summary'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (_, box) => Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final member in data.members)
                          SizedBox(
                            width: box.maxWidth < 700
                                ? box.maxWidth
                                : (box.maxWidth - 12) / 2,
                            child: Material(
                              color: _employee == member.id
                                  ? EmployeeTheme.primary.withValues(alpha: .09)
                                  : EmployeeTheme.primary.withValues(
                                      alpha: .025,
                                    ),
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                key: ValueKey('attendance-member-${member.id}'),
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => setState(() {
                                  _employee = _employee == member.id
                                      ? null
                                      : member.id;
                                  _page = 0;
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 17,
                                            backgroundColor: EmployeeTheme
                                                .primary
                                                .withValues(alpha: .16),
                                            child: Text(
                                              member
                                                      .name
                                                      .characters
                                                      .firstOrNull ??
                                                  '—',
                                              style: const TextStyle(
                                                color: EmployeeTheme.dark,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              member.name,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            _employee == member.id
                                                ? Icons.check_circle
                                                : (ar
                                                      ? Icons.chevron_left
                                                      : Icons.chevron_right),
                                            textDirection: TextDirection.ltr,
                                            size: 20,
                                            color: EmployeeTheme.primary,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _summary(member.id, data),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.7,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (data.members.isEmpty)
                    AppEmptyState(
                      title: tr(
                        'لا يوجد أعضاء نشطون في فريقك',
                        'No active team members',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr('سجل الحضور والانصراف', 'Attendance records'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_employee != null)
                        TextButton(
                          onPressed: () => setState(() {
                            _employee = null;
                            _page = 0;
                          }),
                          child: Text(tr('كل الفريق', 'All team')),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (v) => setState(() {
                      _query = v;
                      _page = 0;
                    }),
                    decoration: InputDecoration(
                      hintText: tr(
                        'ابحث بالموظف أو التاريخ أو الملاحظات',
                        'Search employee, date or notes',
                      ),
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: tr('الحالة', 'Status'),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text(tr('كل الحالات', 'All statuses')),
                      ),
                      for (final s in ['present', 'late', 'absent', 'on_leave'])
                        DropdownMenuItem(
                          value: s,
                          child: Text(employeeAttendanceStatus(s, t)),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _status = v!;
                      _page = 0;
                    }),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (_, box) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: box.maxWidth < 820 ? 820 : box.maxWidth,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: EmployeeTheme.primary.withValues(
                                  alpha: .06,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  for (final f in [
                                    (tr('الموظف', 'Employee'), 3),
                                    (tr('التاريخ', 'Date'), 2),
                                    (tr('الحضور', 'Check-in'), 2),
                                    (tr('الانصراف', 'Check-out'), 2),
                                    (tr('المدة', 'Duration'), 2),
                                    (tr('الحالة', 'Status'), 2),
                                  ])
                                    cell(
                                      Text(
                                        f.$1,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      f.$2,
                                    ),
                                ],
                              ),
                            ),
                            for (final r in filtered.skip(page * 10).take(10))
                              recordRow(
                                r,
                                data.members
                                    .where((m) => m.id == r.employeeId)
                                    .firstOrNull
                                    ?.photoUrl,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    AppEmptyState(
                      title: tr(
                        'لا توجد سجلات مطابقة لهذا الشهر',
                        'No matching records for this month',
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${filtered.length} ${tr('سجل', 'records')} · ${tr('الصفحة', 'Page')} ${page + 1} / $pages',
                        style: const TextStyle(fontSize: 13),
                      ),
                      PageNavigationButtons(
                        onPrevious: page == 0
                            ? null
                            : () => setState(() => _page = page - 1),
                        onNext: page + 1 >= pages
                            ? null
                            : () => setState(() => _page = page + 1),
                        previousTooltip: tr('الصفحة السابقة', 'Previous page'),
                        nextTooltip: tr('الصفحة التالية', 'Next page'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'الأوقات بتوقيت جهازك. المدة بين الحضور والانصراف المسجلين؛ لا تعني ساعات راتب أو أوفر تايم. الغياب والتأخير يظهران فقط إذا كانا مسجلين.',
                      'Times use your device timezone. Duration is recorded check-in to check-out, not payable hours or overtime. Absence and lateness reflect recorded statuses only.',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
  String _summary(String id, ManagerAttendanceData data) {
    final rows = data.records.where((r) => r.employeeId == id).toList();
    final complete = rows.fold(
      Duration.zero,
      (sum, r) => sum + (managerAttendanceDuration(r) ?? Duration.zero),
    );
    return '${rows.length} ${tr('سجل', 'records')} · ${rows.where((r) => r.status == 'late').length} ${tr('تأخير مسجل', 'late entries')} · ${rows.where((r) => r.status == 'absent').length} ${tr('غياب مسجل', 'absence entries')}\n${employeeAttendanceDuration(complete, ar)} · ${rows.where((r) => managerAttendanceDuration(r) == null && (r.checkIn != null || r.checkOut != null)).length} ${tr('سجل وقت غير مكتمل', 'incomplete time records')}';
  }
}
