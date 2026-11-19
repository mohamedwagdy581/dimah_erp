import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/app_di.dart';
import '../../../../core/widgets/page_navigation_buttons.dart';
import '../../../employees/data/repos/hr_employees_repo.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/repos/attendance_repo.dart';
import '../cubit/attendance_cubit.dart';
import '../sections/attendance_correction_dialog_launcher.dart';
import '../widgets/attendance_form_dialog.dart';
import '../widgets/attendance_import_dialog.dart';

class HrAttendancePage extends StatefulWidget {
  const HrAttendancePage({
    super.key,
    this.repo,
    this.loadEmployees,
    this.today,
  });
  final AttendanceRepo? repo;
  final Future<HrEmployeesData> Function()? loadEmployees;
  final DateTime? today;
  @override
  State<HrAttendancePage> createState() => _HrAttendancePageState();
}

class _HrAttendancePageState extends State<HrAttendancePage> {
  AttendanceRepo get repo => widget.repo ?? AppDI.attendanceRepo;
  HrEmployeesData _employees = const HrEmployeesData();
  List<AttendanceRecord> _records = [];
  bool _loading = true, _import = false;
  String? _error, _department, _status;
  String _search = '';
  final _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime? _from, _to;
  int _page = 0;
  bool _ascending = false;
  static const _purple = Color(0xFF8654BC),
      _ink = Color(0xFF21194E),
      _border = Color(0xFFECE6F4);
  @override
  void initState() {
    super.initState();
    final now = widget.today ?? DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = DateTime(now.year, now.month + 1, 0);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final employeeFuture =
          (widget.loadEmployees ??
          () => SupabaseHrEmployeesRepo(Supabase.instance.client).load())();
      final recordsFuture = _loadRecords();
      final results = await Future.wait<Object>([
        employeeFuture,
        recordsFuture,
      ]);
      if (mounted) {
        setState(() {
          _employees = results[0] as HrEmployeesData;
          _records = results[1] as List<AttendanceRecord>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<List<AttendanceRecord>> _loadRecords() async {
    final result = <AttendanceRecord>[];
    for (var page = 0; ; page++) {
      final batch = await repo.fetchAttendance(
        page: page,
        pageSize: 500,
        sortBy: 'date',
        ascending: false,
      );
      result.addAll(batch.items);
      if (batch.items.isEmpty || result.length >= batch.total) break;
    }
    return result;
  }

  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => ar ? a : e;
  String date(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  String time(DateTime? d) {
    if (d == null) return '—';
    final local = d.isUtc ? d.add(const Duration(hours: 3)) : d;
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String statusLabel(String value) => switch (value) {
    'present' => tr('حاضر', 'Present'),
    'absent' => tr('غائب', 'Absent'),
    'late' => tr('متأخر', 'Late'),
    'on_leave' => tr('إجازة', 'On leave'),
    'half_day' => tr('نصف يوم', 'Half day'),
    _ => value,
  };
  Future<void> _pick(bool start) async {
    final now = widget.today ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (start ? _from : _to) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        if (start) {
          _from = picked;
          if (_to?.isBefore(picked) == true) _to = picked;
        } else {
          _to = picked;
          if (_from?.isAfter(picked) == true) _from = picked;
        }
        _page = 0;
      });
    }
  }

  Future<void> _add() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AttendanceCubit>(),
        child: const AttendanceFormDialog(),
      ),
    );
    if (ok == true && mounted) await _load();
  }

  Widget badge(String status) {
    final color = switch (status) {
      'present' => const Color(0xFF009B7E),
      'absent' => const Color(0xFFF04461),
      'late' || 'half_day' => const Color(0xFFF29400),
      _ => _purple,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(color: color, fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employees = {for (final e in _employees.employees) e.id: e};
    final filtered =
        _records
            .where(
              (r) =>
                  (_department == null ||
                      employees[r.employeeId]?.departmentId == _department) &&
                  (_status == null || r.status == _status) &&
                  (_from == null || !r.date.isBefore(_from!)) &&
                  (_to == null || !r.date.isAfter(_to!)) &&
                  ('${r.employeeName} ${r.notes ?? ''}'.toLowerCase().contains(
                    _search.toLowerCase(),
                  )),
            )
            .toList()
          ..sort((a, b) {
            final byDate = a.date.compareTo(b.date);
            return (_ascending ? 1 : -1) *
                (byDate == 0 ? a.id.compareTo(b.id) : byDate);
          });
    final pages = (filtered.length / 5).ceil().clamp(1, 1000000);
    final page = _page.clamp(0, pages - 1);
    final visible = filtered.skip(page * 5).take(5).toList();
    Widget field(String label, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _ink)),
        const SizedBox(height: 5),
        child,
      ],
    );
    Widget drop(
      String key,
      String label,
      String? value,
      Map<String, String> options,
      ValueChanged<String?> onChanged,
    ) => field(
      label,
      DropdownButtonFormField<String>(
        key: ValueKey('$key-$value'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 11,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: _border),
          ),
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem(value: null, child: Text(tr('الكل', 'All'))),
          for (final e in options.entries)
            DropdownMenuItem(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _border),
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
                        tr('الحضور والانصراف', 'Attendance'),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(
                          'إدارة سجلات حضور وانصراف الموظفين',
                          'Manage employee attendance records',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF77738C),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _load,
                  tooltip: tr('تحديث', 'Refresh'),
                  icon: const Icon(Icons.refresh, color: _purple),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, c) {
                final width = c.maxWidth >= 900
                    ? (c.maxWidth - 36) / 4
                    : c.maxWidth >= 500
                    ? (c.maxWidth - 12) / 2
                    : c.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: width,
                      child: drop(
                        'department',
                        tr('القسم', 'Department'),
                        _department,
                        _employees.departments,
                        (v) => setState(() {
                          _department = v;
                          _page = 0;
                        }),
                      ),
                    ),
                    for (final start in [true, false])
                      SizedBox(
                        width: width,
                        child: field(
                          tr(
                            start ? 'من تاريخ' : 'إلى تاريخ',
                            start ? 'From date' : 'To date',
                          ),
                          OutlinedButton(
                            onPressed: () => _pick(start),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _ink,
                              side: const BorderSide(color: _border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              minimumSize: const Size(double.infinity, 42),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    (start ? _from : _to) == null
                                        ? '—'
                                        : date((start ? _from : _to)!),
                                    textDirection: TextDirection.ltr,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: width,
                      child: drop(
                        'status',
                        tr('الحالة', 'Status'),
                        _status,
                        {
                          for (final s in {
                            'present',
                            'late',
                            'absent',
                            'on_leave',
                            'half_day',
                            ..._records.map((r) => r.status),
                          })
                            s: statusLabel(s),
                        },
                        (v) => setState(() {
                          _status = v;
                          _page = 0;
                        }),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              textDirection: TextDirection.ltr,
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                          _import = true;
                        }),
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.file_upload_outlined, size: 19),
                  label: Text(tr('استيراد سجلات', 'Import records')),
                ),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _add,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _purple,
                    side: const BorderSide(color: Color(0xFFBD96EC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(tr('إضافة سجل', 'Add record')),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _from = null;
                    _to = null;
                    _department = null;
                    _status = null;
                    _search = '';
                    _searchController.clear();
                    _page = 0;
                  }),
                  child: Text(tr('عرض الكل', 'Show all')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('attendance-search'),
              controller: _searchController,
              onChanged: (v) => setState(() {
                _search = v;
                _page = 0;
              }),
              decoration: InputDecoration(
                hintText: tr(
                  'ابحث باسم الموظف أو الملاحظات...',
                  'Search employee or notes...',
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF9F7FC),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: _border),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading) const AppLoadingState(),
            if (_error != null) AppFailureState(error: _error, onRetry: _load),
            if (!_loading && _error == null)
              LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: c.maxWidth),
                    child: DataTable(
                      headingRowHeight: 42,
                      dataRowMinHeight: 44,
                      dataRowMaxHeight: 48,
                      horizontalMargin: 12,
                      columnSpacing: 24,
                      dividerThickness: 0,
                      border: const TableBorder(
                        horizontalInside: BorderSide(color: _border),
                        verticalInside: BorderSide(color: Color(0xFFF5F1FA)),
                      ),
                      headingRowColor: const WidgetStatePropertyAll(
                        Color(0xFFF5F2FA),
                      ),
                      headingTextStyle: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(
                            fontSize: 14,
                            color: _ink,
                            fontWeight: FontWeight.w600,
                          ),
                      columns: [
                        for (final label in [
                          '#',
                          tr('الموظف', 'Employee'),
                          tr('التاريخ', 'Date'),
                          tr('وقت الحضور', 'Check in'),
                          tr('وقت الانصراف', 'Check out'),
                          tr('الحالة', 'Status'),
                          tr('إجراءات', 'Actions'),
                        ])
                          DataColumn(
                            label: label == tr('التاريخ', 'Date')
                                ? InkWell(
                                    onTap: () => setState(() {
                                      _ascending = !_ascending;
                                      _page = 0;
                                    }),
                                    child: Text(label),
                                  )
                                : Text(label),
                          ),
                      ],
                      rows: [
                        for (var i = 0; i < visible.length; i++)
                          DataRow(
                            cells: [
                              DataCell(Text('${page * 5 + i + 1}')),
                              DataCell(Text(visible[i].employeeName)),
                              DataCell(
                                Text(
                                  date(visible[i].date),
                                  textDirection: TextDirection.ltr,
                                ),
                              ),
                              DataCell(
                                Text(
                                  time(visible[i].checkIn),
                                  textDirection: TextDirection.ltr,
                                ),
                              ),
                              DataCell(
                                Text(
                                  time(visible[i].checkOut),
                                  textDirection: TextDirection.ltr,
                                ),
                              ),
                              DataCell(badge(visible[i].status)),
                              DataCell(
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_horiz,
                                    color: _purple,
                                  ),
                                  onSelected: (action) async {
                                    if (action == 'correction') {
                                      await openAttendanceCorrectionDialog(
                                        context,
                                        visible[i],
                                      );
                                    } else if (mounted) {
                                      showDialog<void>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text(visible[i].employeeName),
                                          content: SelectableText(
                                            '${date(visible[i].date)}\n${visible[i].notes ?? tr('لا توجد ملاحظات', 'No notes')}',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'details',
                                      child: Text(
                                        tr('تفاصيل السجل', 'Record details'),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'correction',
                                      child: Text(
                                        tr('طلب تصحيح', 'Request correction'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!_loading && _error == null && filtered.isEmpty)
              AppEmptyState(
                filtered:
                    _from != null ||
                    _to != null ||
                    _department != null ||
                    _status != null ||
                    _search.trim().isNotEmpty,
                onClear:
                    _from != null ||
                        _to != null ||
                        _department != null ||
                        _status != null ||
                        _search.trim().isNotEmpty
                    ? () => setState(() {
                        _from = null;
                        _to = null;
                        _department = null;
                        _status = null;
                        _search = '';
                        _searchController.clear();
                        _page = 0;
                      })
                    : null,
              ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  tr('${filtered.length} سجل', '${filtered.length} records'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF77738C),
                  ),
                ),
                PageNavigationButtons(
                  onPrevious: page > 0
                      ? () => setState(() {
                          _page = page - 1;
                        })
                      : null,
                  onNext: page + 1 < pages
                      ? () => setState(() {
                          _page = page + 1;
                        })
                      : null,
                  previousTooltip: tr('السابق', 'Previous'),
                  nextTooltip: tr('التالي', 'Next'),
                  center: Text(
                    '${page + 1} / $pages',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            if (_import) ...[
              const SizedBox(height: 12),
              AttendanceImportDialog(
                embedded: true,
                onClosed: (saved) {
                  setState(() {
                    _import = false;
                  });
                  if (saved) _load();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
