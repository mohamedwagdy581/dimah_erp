import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/app_di.dart';
import '../../../../core/widgets/page_navigation_buttons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repos/hr_employees_repo.dart';
import '../../data/repos/employee_status_repo.dart';
import '../widgets/employee_status_dialog.dart';
import '../utils/employee_profile_utils.dart';

class HrEmployeesPage extends StatefulWidget {
  const HrEmployeesPage({super.key, this.repo});
  final HrEmployeesRepo? repo;
  @override
  State<HrEmployeesPage> createState() => _HrEmployeesPageState();
}

class _HrEmployeesPageState extends State<HrEmployeesPage> {
  late final _repo = widget.repo ?? SupabaseHrEmployeesRepo(AppDI.supabase);
  late Future<HrEmployeesData> _future = _repo.load();
  void reload() {
    final next = _repo.load();
    setState(() {
      _future = next;
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<HrEmployeesData>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const AppLoadingState();
      }
      if (snapshot.hasError) {
        return AppFailureState(
          error: snapshot.error,
          onRetry: reload,
          title: Localizations.localeOf(context).languageCode == 'ar'
              ? 'تعذر التحميل — إعادة المحاولة'
              : 'Could not load — Retry',
        );
      }
      return HrEmployeesView(data: snapshot.data!, onRefresh: reload);
    },
  );
}

class HrEmployeesView extends StatefulWidget {
  const HrEmployeesView({
    super.key,
    required this.data,
    required this.onRefresh,
    this.onSetStatus,
  });
  final HrEmployeesData data;
  final VoidCallback onRefresh;
  final Future<void> Function(String id, String status)? onSetStatus;
  @override
  State<HrEmployeesView> createState() => _HrEmployeesViewState();
}

class _HrEmployeesViewState extends State<HrEmployeesView> {
  static const accent = Color(0xFF8659BB);
  final search = TextEditingController();
  String department = '', job = '', status = '';
  int page = 0, size = 10;
  bool newest = false;
  bool inactiveList = false;

  Future<void> changeStatus(String id, String name, bool inactive) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmployeeStatusDialog(
        name: name,
        inactive: inactive,
        save: () => widget.onSetStatus != null
            ? widget.onSetStatus!(id, inactive ? 'active' : 'inactive')
            : EmployeeStatusRepo(
                AppDI.supabase,
              ).setStatus(id, inactive ? 'active' : 'inactive'),
      ),
    );
    if (mounted && changed == true) widget.onRefresh();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void change(VoidCallback action) => setState(() {
    action();
    page = 0;
  });
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String a, String e) => ar ? a : e;
    String statusLabel(String s) => switch (s) {
      'active' => tr('على رأس العمل', 'Active'),
      'inactive' => t.inactive,
      'probation' => tr('فترة تجربة', 'Probation'),
      _ => s,
    };
    final colors = Theme.of(context).colorScheme;
    final textAlignment = ar ? TextAlign.right : TextAlign.left;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: accent.withValues(alpha: .22)),
    );
    final query = search.text.trim().toLowerCase();
    final rows =
        widget.data.employees
            .where(
              (e) =>
                  (inactiveList
                      ? e.status == 'inactive'
                      : e.status != 'inactive') &&
                  (department.isEmpty || e.departmentId == department) &&
                  (job.isEmpty || e.jobTitleId == job) &&
                  (status.isEmpty || e.status == status) &&
                  '${e.fullName} ${e.employeeNumber ?? ''} ${e.email} ${e.phone}'
                      .toLowerCase()
                      .contains(query),
            )
            .toList()
          ..sort((a, b) {
            final order = newest
                ? (b.hireDate ?? DateTime(1900)).compareTo(
                    a.hireDate ?? DateTime(1900),
                  )
                : a.fullName.compareTo(b.fullName);
            return order == 0 ? a.id.compareTo(b.id) : order;
          });
    final pages = (rows.length / size).ceil().clamp(1, 999999);
    final current = page.clamp(0, pages - 1);
    final visible = rows.skip(current * size).take(size).toList();
    Widget dropdown(
      String label,
      String value,
      Map<String, String> options,
      ValueChanged<String> update,
    ) => DropdownButtonFormField<String>(
      key: ValueKey('$label:$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: accent, width: 1.4),
        ),
      ),
      items: [
        DropdownMenuItem(value: '', child: Text(t.all)),
        for (final entry in options.entries)
          DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        if (v != null) change(() => update(v));
      },
    );
    Widget textCell(
      String value, {
      bool numeric = false,
      bool heading = false,
    }) => Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: heading ? 16 : 10,
      ),
      child: Text(
        value,
        textAlign: numeric || heading ? TextAlign.center : textAlignment,
        textDirection: numeric ? TextDirection.ltr : null,
        maxLines: heading ? 1 : null,
        style: TextStyle(
          fontSize: heading ? 13 : 14,
          height: 1.5,
          fontWeight: heading ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge, color: accent, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('قائمة الموظفين', 'Employee directory'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            tr(
                              'إدارة بيانات الموظفين واستعراض معلوماتهم',
                              'Manage and explore employee information',
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: tr('الإشعارات', 'Notifications'),
                      onPressed: () => context.go('/notifications'),
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: accent,
                      ),
                    ),
                    IconButton(
                      tooltip: t.refresh,
                      onPressed: widget.onRefresh,
                      icon: const Icon(Icons.refresh),
                    ),
                    if (MediaQuery.sizeOf(context).width >= 1000)
                      FilledButton.icon(
                        onPressed: () => context.go('/employees/create'),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: Text(t.addEmployee),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (MediaQuery.sizeOf(context).width < 1000)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      onPressed: () => context.go('/employees/create'),
                      icon: const Icon(Icons.add),
                      label: Text(t.addEmployee),
                    ),
                  ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      key: const ValueKey('current-employees'),
                      label: Text(
                        '${tr('الموظفون الحاليون', 'Current employees')} (${widget.data.employees.where((e) => e.status != 'inactive').length})',
                      ),
                      selected: !inactiveList,
                      onSelected: (_) => change(() {
                        inactiveList = false;
                        status = '';
                      }),
                    ),
                    ChoiceChip(
                      key: const ValueKey('inactive-employees'),
                      label: Text(
                        '${tr('غير النشطين / المغادرون', 'Inactive / departed')} (${widget.data.employees.where((e) => e.status == 'inactive').length})',
                      ),
                      selected: inactiveList,
                      onSelected: (_) => change(() {
                        inactiveList = true;
                        status = '';
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: accent.withValues(alpha: .18)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final columns = box.maxWidth >= 1000
                          ? 4
                          : box.maxWidth >= 600
                          ? 2
                          : 1;
                      final width =
                          (box.maxWidth - 12 * (columns - 1)) / columns;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 14,
                        children: [
                          SizedBox(
                            width: width,
                            child: TextField(
                              controller: search,
                              onChanged: (_) => change(() {}),
                              decoration: InputDecoration(
                                hintText: tr(
                                  'البحث بالاسم أو رقم الموظف...',
                                  'Search by name or employee number...',
                                ),
                                prefixIcon: const Icon(Icons.search),
                                isDense: true,
                                border: fieldBorder,
                                enabledBorder: fieldBorder,
                                focusedBorder: fieldBorder.copyWith(
                                  borderSide: const BorderSide(
                                    color: accent,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: dropdown(
                              t.department,
                              department,
                              widget.data.departments,
                              (v) => department = v,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: dropdown(
                              t.menuJobTitles,
                              job,
                              widget.data.jobTitles,
                              (v) => job = v,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: dropdown(
                              tr('الحالة الوظيفية', 'Employment status'),
                              status,
                              {
                                for (final s
                                    in widget.data.employees
                                        .where(
                                          (e) => inactiveList
                                              ? e.status == 'inactive'
                                              : e.status != 'inactive',
                                        )
                                        .map((e) => e.status)
                                        .toSet())
                                  s: statusLabel(s),
                              },
                              (v) => status = v,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  children: [
                    TextButton.icon(
                      onPressed: () => change(() {
                        search.clear();
                        department = '';
                        job = '';
                        status = '';
                      }),
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                      label: Text(tr('إعادة تعيين', 'Reset filters')),
                    ),
                    TextButton.icon(
                      onPressed: () => change(() => newest = !newest),
                      icon: const Icon(Icons.sort, size: 18),
                      label: Text(
                        newest
                            ? tr('الأحدث تعيينًا', 'Newest hires')
                            : tr('ترتيب بالاسم', 'Sorted by name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      t.noEmployeesFound,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: box.maxWidth < 960 ? 960 : box.maxWidth,
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            5: FixedColumnWidth(100),
                          },
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: colors.outlineVariant.withValues(
                                alpha: .3,
                              ),
                            ),
                          ),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? colors.surfaceContainerHighest
                                    : const Color(0xFFF0F1F5),
                              ),
                              children: [
                                for (final title in [
                                  tr('الموظف', 'Employee'),
                                  t.department,
                                  t.menuJobTitles,
                                  tr('الحالة الوظيفية', 'Employment status'),
                                  t.hireDate,
                                  t.actions,
                                ])
                                  textCell(title, heading: true),
                              ],
                            ),
                            for (final e in visible)
                              TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 10,
                                    ),
                                    child: InkWell(
                                      onTap: () =>
                                          context.go('/employees/${e.id}'),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 19,
                                            backgroundColor: accent.withValues(
                                              alpha: .15,
                                            ),
                                            foregroundImage:
                                                resolveEmployeePhotoProvider(
                                                  e.photoUrl,
                                                ),
                                            onForegroundImageError:
                                                (e.photoUrl ?? '')
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : (_, _) {},
                                            child: Text(
                                              e.fullName
                                                  .trim()
                                                  .split(RegExp(r'\s+'))
                                                  .where((w) => w.isNotEmpty)
                                                  .take(2)
                                                  .map(
                                                    (w) => w.characters.first,
                                                  )
                                                  .join(' ')
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: accent,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Text(
                                                  e.fullName,
                                                  textAlign: textAlignment,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  e.employeeNumber ?? '—',
                                                  textAlign: textAlignment,
                                                  textDirection:
                                                      TextDirection.ltr,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        colors.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  textCell(
                                    e.departmentName ??
                                        widget.data.departments[e
                                            .departmentId] ??
                                        '—',
                                  ),
                                  textCell(
                                    e.jobTitleName ??
                                        widget.data.jobTitles[e.jobTitleId] ??
                                        '—',
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 5,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (e.status == 'probation'
                                                    ? Colors.orange
                                                    : accent)
                                                .withValues(alpha: .1),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Text(
                                        statusLabel(e.status),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: e.status == 'probation'
                                              ? Colors.orange
                                              : accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  textCell(
                                    formatEmployeeDate(
                                      e.hireDate,
                                    ).replaceAll('-', '/'),
                                    numeric: true,
                                  ),
                                  Center(
                                    child: PopupMenuButton<String>(
                                      tooltip: t.actions,
                                      onSelected: (action) {
                                        if (action == 'status') {
                                          changeStatus(
                                            e.id,
                                            e.fullName,
                                            e.status == 'inactive',
                                          );
                                        } else {
                                          context.go('/employees/${e.id}');
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.more_vert,
                                        size: 22,
                                      ),
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: 'profile',
                                          child: Text(t.openProfile),
                                        ),
                                        PopupMenuItem(
                                          value: 'status',
                                          child: Text(
                                            e.status == 'inactive'
                                                ? tr(
                                                    'إعادة تفعيل الموظف',
                                                    'Reactivate employee',
                                                  )
                                                : tr(
                                                    'إيقاف الموظف',
                                                    'Deactivate employee',
                                                  ),
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
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    Text(
                      rows.isEmpty
                          ? tr('لا توجد نتائج', 'No results')
                          : tr(
                              'إظهار ${current * size + 1}–${current * size + visible.length} من ${rows.length} موظفًا',
                              'Showing ${current * size + 1}–${current * size + visible.length} of ${rows.length} employees',
                            ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    PageNavigationButtons(
                      onPrevious: current > 0
                          ? () => setState(() => page = current - 1)
                          : null,
                      onNext: current + 1 < pages
                          ? () => setState(() => page = current + 1)
                          : null,
                      previousTooltip: tr('الصفحة السابقة', 'Previous page'),
                      nextTooltip: tr('الصفحة التالية', 'Next page'),
                      center: Text(
                        '${current + 1} / $pages',
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    DropdownButton<int>(
                      value: size,
                      items: [
                        for (final count in [10, 25, 50])
                          DropdownMenuItem(
                            value: count,
                            child: Text(
                              tr('$count لكل صفحة', '$count per page'),
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) change(() => size = v);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
