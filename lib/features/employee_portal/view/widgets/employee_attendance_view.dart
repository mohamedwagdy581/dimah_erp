import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:erp_sys/core/ui/app_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../attendance/domain/models/attendance_record.dart';
import '../cubit/employee_attendance_cubit.dart';
import 'employee_attendance_correction_dialog.dart';

String employeeAttendanceDate(DateTime value) =>
    '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
String employeeAttendanceDay(DateTime value, bool ar) => (ar
    ? const [
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
        'الأحد',
      ]
    : const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ])[value.weekday - 1];

String employeeAttendanceDuration(Duration? value, bool ar) => value == null
    ? '—'
    : (ar
          ? '${value.inHours} س ${value.inMinutes.remainder(60)} د'
          : '${value.inHours}h ${value.inMinutes.remainder(60)}m');
String employeeAttendanceStatus(String status, AppLocalizations t) =>
    switch (status) {
      'present' => t.attendancePresent,
      'late' => t.attendanceLate,
      'absent' => t.attendanceAbsent,
      'on_leave' => t.attendanceOnLeave,
      _ => status,
    };

class EmployeeAttendanceView extends StatefulWidget {
  const EmployeeAttendanceView({super.key, required this.onRequests, this.now});
  final VoidCallback onRequests;
  final DateTime? now;
  @override
  State<EmployeeAttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<EmployeeAttendanceView> {
  String _status = 'all', _query = '';
  int _page = 0;
  Future<void> _correction(AttendanceRecord record) async {
    final cubit = context.read<EmployeeAttendanceCubit>();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: EmployeeAttendanceCorrectionDialog(record: record),
      ),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Localizations.localeOf(context).languageCode == 'ar'
              ? 'تم إرسال طلب التصحيح؛ تابعه في سجل طلباتي'
              : 'Correction submitted. Track it in request history.',
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<EmployeeAttendanceCubit, EmployeeAttendanceState>(
    builder: (context, state) {
      final t = AppLocalizations.of(context)!;
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      final cs = Theme.of(context).colorScheme;
      final cubit = context.read<EmployeeAttendanceCubit>();
      final busy = state.loading || state.saving;
      final now = widget.now ?? DateTime.now();
      final today = state.records
          .where((r) => DateUtils.isSameDay(r.date, now))
          .firstOrNull;
      final inCurrentMonth =
          state.month.year == now.year && state.month.month == now.month;
      final featured = inCurrentMonth ? today : state.records.firstOrNull;
      final filtered = state.records
          .where(
            (r) =>
                (_status == 'all' || r.status == _status) &&
                (_query.trim().isEmpty ||
                    '${employeeAttendanceDate(r.date)} ${r.notes ?? ''} ${employeeAttendanceStatus(r.status, t)}'
                        .toLowerCase()
                        .contains(_query.trim().toLowerCase())),
          )
          .toList();
      final pages = (filtered.length / 10).ceil().clamp(1, 100000);
      final page = _page.clamp(0, pages - 1);
      final visible = filtered.skip(page * 10).take(10).toList();
      Widget panel(Widget child) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? cs.surface
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: .4)),
        ),
        child: child,
      );
      Widget status(AttendanceRecord r) {
        final color = switch (r.status) {
          'present' => const Color(0xFF00886A),
          'late' => const Color(0xFFD17800),
          'absent' => cs.error,
          _ => cs.primary,
        };
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            employeeAttendanceStatus(r.status, t),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }

      Widget time(DateTime? value) {
        if (value == null) {
          return Text(
            ar ? 'غير مسجل' : 'Not recorded',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          );
        }
        final local = value.toLocal();
        return Text(
          '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}',
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        );
      }

      Widget correction(AttendanceRecord record) =>
          state.pending.contains(record.id)
          ? Text(
              ar ? 'تصحيح قيد المراجعة' : 'Correction pending',
              style: TextStyle(color: cs.primary, fontSize: 13),
              textAlign: TextAlign.center,
            )
          : OutlinedButton.icon(
              key: ValueKey('attendance-correct-${record.id}'),
              onPressed: busy || !state.correctionsReady
                  ? null
                  : () => _correction(record),
              icon: const Icon(Icons.edit_calendar_outlined, size: 18),
              label: Text(ar ? 'طلب تصحيح' : 'Correct'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            );
      Widget summary(String label, String value, IconData icon) => panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
      List<Widget> cells(AttendanceRecord record) => [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              employeeAttendanceDate(record.date),
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              employeeAttendanceDay(record.date, ar),
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        time(record.checkIn),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            time(record.checkOut),
            if (record.checkIn != null &&
                record.checkOut != null &&
                !DateUtils.isSameDay(
                  record.checkIn!.toLocal(),
                  record.checkOut!.toLocal(),
                ))
              Text(
                employeeAttendanceDate(record.checkOut!.toLocal()),
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
          ],
        ),
        Text(
          employeeAttendanceDuration(recordedAttendanceDuration(record), ar),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
        status(record),
        correction(record),
      ];
      const flex = [2, 1, 1, 2, 2, 2];
      Widget tableRow(List<Widget> values, {bool header = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: header
            ? BoxDecoration(
                color: cs.primary.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Row(
          children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                flex: flex[i],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(child: values[i]),
                ),
              ),
          ],
        ),
      );
      return ListView(
        key: const ValueKey('employee-attendance-view'),
        padding: const EdgeInsets.all(22),
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.myAttendance,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ar
                        ? 'مواعيدك وسجل حضورك في مكان واحد'
                        : 'Your attendance records, in one place',
                    style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: busy ? null : widget.onRequests,
                    icon: const Icon(Icons.assignment_outlined),
                    label: Text(
                      ar ? 'متابعة طلبات التصحيح' : 'Track correction requests',
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('attendance-refresh'),
                    onPressed: busy ? null : cubit.load,
                    tooltip: t.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          panel(
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  textDirection: TextDirection.ltr,
                  children: [
                    IconButton(
                      key: const ValueKey('attendance-prev-month'),
                      onPressed: busy
                          ? null
                          : () {
                              setState(() => _page = 0);
                              cubit.load(
                                month: DateTime(
                                  state.month.year,
                                  state.month.month - 1,
                                ),
                              );
                            },
                      tooltip: ar ? 'الشهر السابق' : 'Previous month',
                      icon: const Icon(
                        Icons.chevron_left,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    Text(
                      MaterialLocalizations.of(
                        context,
                      ).formatMonthYear(state.month),
                      textDirection: Directionality.of(context),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('attendance-next-month'),
                      onPressed: busy
                          ? null
                          : () {
                              setState(() => _page = 0);
                              cubit.load(
                                month: DateTime(
                                  state.month.year,
                                  state.month.month + 1,
                                ),
                              );
                            },
                      tooltip: ar ? 'الشهر التالي' : 'Next month',
                      icon: const Icon(
                        Icons.chevron_right,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: busy
                      ? null
                      : () {
                          setState(() => _page = 0);
                          cubit.load(month: now);
                        },
                  icon: const Icon(Icons.today),
                  label: Text(ar ? 'الشهر الحالي' : 'Current month'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (state.loading)
            const AppLoadingState()
          else if (state.error != null)
            AppFailureState(error: state.error, onRetry: cubit.load)
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                final columns = (constraints.maxWidth / (240 * scale))
                    .floor()
                    .clamp(1, 4);
                final width =
                    (constraints.maxWidth - 12 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: width,
                      child: summary(
                        ar ? 'أيام لها سجلات' : 'Days with records',
                        '${state.recordedDays}',
                        Icons.calendar_month_outlined,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: summary(
                        ar ? 'أيام تأخير مسجلة' : 'Recorded late days',
                        '${state.daysWithStatus('late')}',
                        Icons.schedule,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: summary(
                        ar ? 'أيام غياب مسجلة' : 'Recorded absent days',
                        '${state.daysWithStatus('absent')}',
                        Icons.event_busy_outlined,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: summary(
                        ar
                            ? 'مدة الحضور المكتملة'
                            : 'Completed attendance duration',
                        employeeAttendanceDuration(state.recordedDuration, ar),
                        Icons.timelapse,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    inCurrentMonth
                        ? (ar ? 'سجل اليوم' : 'Today’s record')
                        : (ar
                              ? 'أحدث سجل في الشهر'
                              : 'Latest record this month'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (featured == null)
                    Text(
                      inCurrentMonth
                          ? (ar
                                ? 'لم يُسجّل حضور لهذا اليوم حتى الآن.'
                                : 'No attendance is recorded for today yet.')
                          : (ar
                                ? 'لا توجد سجلات لهذا الشهر.'
                                : 'No records for this month.'),
                    )
                  else
                    Wrap(
                      spacing: 32,
                      runSpacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        status(featured),
                        Column(
                          children: [
                            Text(ar ? 'الحضور' : 'Arrival'),
                            const SizedBox(height: 8),
                            time(featured.checkIn),
                          ],
                        ),
                        Column(
                          children: [
                            Text(ar ? 'الانصراف' : 'Departure'),
                            const SizedBox(height: 8),
                            time(featured.checkOut),
                          ],
                        ),
                        Text(
                          employeeAttendanceDuration(
                            recordedAttendanceDuration(featured),
                            ar,
                          ),
                        ),
                        correction(featured),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Text(
                    ar
                        ? 'الأوقات بتوقيت جهازك. المدة هي الفرق بين الحضور والانصراف المسجلين، وليست ساعات الرواتب أو الإضافي.'
                        : 'Times use your device timezone. Duration is the recorded arrival-to-departure interval, not paid hours or overtime.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ar ? 'سجل الحضور والانصراف' : 'Attendance history',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final search = AppSearchField(
                        value: _query,
                        key: const ValueKey('attendance-search'),
                        onChanged: (v) => setState(() {
                          _query = v;
                          _page = 0;
                        }),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: ar
                              ? 'بحث بالتاريخ أو الملاحظات'
                              : 'Search dates or notes',
                          border: const OutlineInputBorder(),
                        ),
                      );
                      final filter = DropdownButtonFormField<String>(
                        key: ValueKey('attendance-status-$_status'),
                        initialValue: _status,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: ar ? 'الحالة' : 'Status',
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text(t.all)),
                          for (final value in {
                            'present',
                            'late',
                            'absent',
                            'on_leave',
                            ...state.records.map((r) => r.status),
                            if (_status != 'all') _status,
                          })
                            DropdownMenuItem(
                              value: value,
                              child: Text(employeeAttendanceStatus(value, t)),
                            ),
                        ],
                        onChanged: (v) => setState(() {
                          _status = v ?? 'all';
                          _page = 0;
                        }),
                      );
                      return constraints.maxWidth >=
                              600 *
                                  MediaQuery.textScalerOf(context).scale(14) /
                                  14
                          ? Row(
                              children: [
                                Expanded(flex: 2, child: search),
                                const SizedBox(width: 16),
                                Expanded(child: filter),
                              ],
                            )
                          : Column(
                              children: [
                                search,
                                const SizedBox(height: 16),
                                filter,
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 20),
                  if (!state.correctionsReady)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        ar
                            ? 'طلبات التصحيح غير متاحة حاليًا؛ تواصل مع الموارد البشرية.'
                            : 'Correction requests are currently unavailable. Contact HR.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  if (visible.isEmpty)
                    AppEmptyState(
                      filtered: _status != 'all' || _query.trim().isNotEmpty,
                      onClear: _status != 'all' || _query.trim().isNotEmpty
                          ? () => setState(() {
                              _status = 'all';
                              _query = '';
                              _page = 0;
                            })
                          : null,
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) =>
                          constraints.maxWidth >=
                              900 *
                                  MediaQuery.textScalerOf(context).scale(14) /
                                  14
                          ? Column(
                              children: [
                                tableRow([
                                  for (final label in [
                                    ar ? 'التاريخ' : 'Date',
                                    ar ? 'الحضور' : 'Arrival',
                                    ar ? 'الانصراف' : 'Departure',
                                    ar ? 'المدة' : 'Duration',
                                    ar ? 'الحالة' : 'Status',
                                    ar ? 'الإجراءات' : 'Actions',
                                  ])
                                    Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ], header: true),
                                for (final record in visible) ...[
                                  tableRow(cells(record)),
                                  const Divider(height: 1),
                                ],
                              ],
                            )
                          : Column(
                              children: [
                                for (final record in visible)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: cs.outlineVariant.withValues(
                                            alpha: .4,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            '${employeeAttendanceDay(record.date, ar)} · ${employeeAttendanceDate(record.date)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Wrap(
                                            spacing: 20,
                                            runSpacing: 14,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              status(record),
                                              Column(
                                                children: [
                                                  Text(
                                                    ar ? 'الحضور' : 'Arrival',
                                                  ),
                                                  time(record.checkIn),
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  Text(
                                                    ar
                                                        ? 'الانصراف'
                                                        : 'Departure',
                                                  ),
                                                  time(record.checkOut),
                                                ],
                                              ),
                                              Text(
                                                employeeAttendanceDuration(
                                                  recordedAttendanceDuration(
                                                    record,
                                                  ),
                                                  ar,
                                                ),
                                              ),
                                              correction(record),
                                            ],
                                          ),
                                          if ((record.notes ?? '').isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 12,
                                              ),
                                              child: Text(
                                                record.notes!,
                                                style: TextStyle(
                                                  color: cs.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text(
                        ar
                            ? '${filtered.length} سجل · الصفحة ${page + 1} من $pages'
                            : '${filtered.length} records · Page ${page + 1} of $pages',
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.ltr,
                        children: [
                          IconButton(
                            key: const ValueKey('attendance-prev-page'),
                            tooltip: ar
                                ? 'الصفحة السابقة · سجلات أحدث'
                                : 'Previous page · Newer records',
                            onPressed: page > 0
                                ? () => setState(() => _page = page - 1)
                                : null,
                            icon: const Icon(
                              Icons.chevron_left,
                              textDirection: TextDirection.ltr,
                            ),
                          ),
                          IconButton(
                            key: const ValueKey('attendance-next-page'),
                            tooltip: ar
                                ? 'الصفحة التالية · سجلات أقدم'
                                : 'Next page · Older records',
                            onPressed: page + 1 < pages
                                ? () => setState(() => _page = page + 1)
                                : null,
                            icon: const Icon(
                              Icons.chevron_right,
                              textDirection: TextDirection.ltr,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}
