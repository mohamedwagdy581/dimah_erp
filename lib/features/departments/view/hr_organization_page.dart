import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/di/app_di.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/widgets/page_navigation_buttons.dart';
import '../../../l10n/app_localizations.dart';
import '../../employees/domain/models/employee_lookup.dart';
import '../../job_titles/domain/models/job_title.dart';
import '../../job_titles/domain/repos/job_titles_repo.dart';
import '../domain/models/department.dart';
import '../domain/repos/departments_repo.dart';

class HrOrganizationPage extends StatefulWidget {
  const HrOrganizationPage({
    super.key,
    this.initialTab = 0,
    this.departmentsRepo,
    this.jobTitlesRepo,
    this.loadManagers,
  });
  final int initialTab;
  final DepartmentsRepo? departmentsRepo;
  final JobTitlesRepo? jobTitlesRepo;
  final Future<List<EmployeeLookup>> Function()? loadManagers;
  @override
  State<HrOrganizationPage> createState() => _HrOrganizationPageState();
}

class _HrOrganizationPageState extends State<HrOrganizationPage> {
  static const purple = Color(0xFF8659BB),
      ink = Color(0xFF24204E),
      border = Color(0xFFECE7F5);
  late final departmentsRepo = widget.departmentsRepo ?? AppDI.departmentsRepo;
  late final titlesRepo = widget.jobTitlesRepo ?? AppDI.jobTitlesRepo;
  late int tab = widget.initialTab;
  final name = TextEditingController(),
      code = TextEditingController(),
      description = TextEditingController(),
      level = TextEditingController(),
      search = TextEditingController();
  final form = GlobalKey<FormState>();
  List<Department> departments = [];
  List<JobTitle> titles = [];
  List<EmployeeLookup> managers = [];
  Department? editingDepartment;
  JobTitle? editingTitle;
  String? managerId, departmentId;
  bool active = true, loading = true, saving = false;
  bool? activeFilter;
  int page = 0;
  String? error;
  final formAnchor = GlobalKey();
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    for (final c in [name, code, description, level, search]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      Future<List<Department>> allDepartments() async {
        final result = <Department>[];
        for (var p = 0; ; p++) {
          final batch = await departmentsRepo.fetchDepartments(
            page: p,
            pageSize: 500,
            sortBy: 'name',
            ascending: true,
          );
          result.addAll(batch.items);
          if (batch.items.length < 500) break;
        }
        return result;
      }

      Future<List<JobTitle>> allTitles() async {
        final result = <JobTitle>[];
        for (var p = 0; ; p++) {
          final batch = await titlesRepo.fetchJobTitles(
            page: p,
            pageSize: 500,
            sortBy: 'name',
            ascending: true,
          );
          result.addAll(batch.items);
          if (batch.items.length < 500) break;
        }
        return result;
      }

      final results = await Future.wait<Object>([
        allDepartments(),
        allTitles(),
        widget.loadManagers?.call() ??
            AppDI.employeesRepo.fetchEmployeeLookup(limit: 1000),
      ]);
      if (!mounted) return;
      setState(() {
        departments = results[0] as List<Department>;
        titles = results[1] as List<JobTitle>;
        managers = results[2] as List<EmployeeLookup>;
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = AppError.message(e);
        });
      }
    }
  }

  void clear() {
    form.currentState?.reset();
    for (final c in [name, code, description, level]) {
      c.clear();
    }
    editingDepartment = null;
    editingTitle = null;
    managerId = null;
    departmentId = null;
    active = true;
  }

  void edit(Object item) {
    setState(() {
      clear();
      if (item is Department) {
        editingDepartment = item;
        name.text = item.name;
        code.text = item.code ?? '';
        description.text = item.description ?? '';
        managerId = item.managerId;
        active = item.isActive;
      } else if (item is JobTitle) {
        editingTitle = item;
        name.text = item.name;
        code.text = item.code ?? '';
        description.text = item.description ?? '';
        level.text = item.level?.toString() ?? '';
        departmentId = item.departmentId;
        active = item.isActive;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && formAnchor.currentContext != null) {
        Scrollable.ensureVisible(
          formAnchor.currentContext!,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      if (tab == 0) {
        final id = editingDepartment?.id;
        if (id == null) {
          await departmentsRepo.createDepartment(
            name: name.text,
            code: code.text,
            description: description.text,
            managerId: managerId,
            isActive: active,
          );
        } else {
          await departmentsRepo.updateDepartment(
            id: id,
            name: name.text,
            code: code.text,
            description: description.text,
            managerId: managerId,
            isActive: active,
          );
        }
      } else {
        final id = editingTitle?.id;
        if (id == null) {
          await titlesRepo.createJobTitle(
            name: name.text,
            code: code.text,
            description: description.text,
            level: int.tryParse(level.text.trim()),
            departmentId: departmentId,
            isActive: active,
          );
        } else {
          await titlesRepo.updateJobTitle(
            id: id,
            name: name.text,
            code: code.text,
            description: description.text,
            level: int.tryParse(level.text.trim()),
            departmentId: departmentId,
            isActive: active,
          );
        }
      }
      if (!mounted) return;
      setState(() {
        clear();
        page = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'تم الحفظ بنجاح'
                : 'Saved successfully',
          ),
        ),
      );
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.message(e))));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> runAutoAssign() async {
    setState(() => saving = true);
    try {
      final count = await departmentsRepo.autoAssignManagers();
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? t.noManagerChangesNeeded
                : t.assignedUpdatedManagers(count),
          ),
        ),
      );
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.message(e))));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String a, String e) => ar ? a : e;
    final isDepartment = tab == 0;
    final isEdit = isDepartment
        ? editingDepartment != null
        : editingTitle != null;
    final query = search.text.trim().toLowerCase();
    final items = <Object>[if (isDepartment) ...departments else ...titles]
        .where((item) {
          final (n, c, a) = item is Department
              ? (item.name, item.code, item.isActive)
              : ((item as JobTitle).name, item.code, item.isActive);
          return (activeFilter == null || a == activeFilter) &&
              '$n ${c ?? ''}'.toLowerCase().contains(query);
        })
        .toList();
    final pages = (items.length / 8).ceil().clamp(1, 999999);
    final current = page.clamp(0, pages - 1);
    final visible = items.skip(current * 8).take(8);
    InputDecoration decoration(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      isDense: true,
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF66638B)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: border),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: purple),
      ),
    );
    Widget panel(Widget child) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
    final managerOptions = {for (final m in managers) m.id: m.fullName};
    if (managerId != null) {
      managerOptions.putIfAbsent(
        managerId!,
        () =>
            editingDepartment?.managerName ??
            tr('المدير الحالي', 'Current manager'),
      );
    }
    final departmentOptions = {for (final d in departments) d.id: d.name};
    if (departmentId != null) {
      departmentOptions.putIfAbsent(
        departmentId!,
        () => tr('القسم الحالي', 'Current department'),
      );
    }
    final editor = panel(
      Form(
        key: form,
        child: Column(
          key: formAnchor,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: purple.withValues(alpha: .08),
                  child: Icon(
                    isDepartment
                        ? Icons.account_tree_outlined
                        : Icons.work_outline,
                    color: purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isDepartment
                        ? (isEdit
                              ? t.editDepartment
                              : tr('إضافة قسم جديد', 'Add a department'))
                        : (isEdit
                              ? t.editJobTitle
                              : tr('إضافة مسمى وظيفي', 'Add a job title')),
                    style: const TextStyle(
                      fontSize: 17,
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            TextFormField(
              key: const ValueKey('organization-name'),
              controller: name,
              decoration: decoration(
                '${isDepartment ? tr('اسم القسم', 'Department name') : tr('المسمى الوظيفي', 'Job title')} *',
                hint: isDepartment
                    ? tr('مثال: الدعم الفني', 'e.g. Technical support')
                    : tr('مثال: أخصائي توظيف', 'e.g. Recruitment specialist'),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? t.requiredField : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              key: const ValueKey('organization-code'),
              controller: code,
              decoration: decoration(
                t.codeOptional,
                hint: isDepartment ? 'IT' : 'HR-01',
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              key: const ValueKey('organization-description'),
              controller: description,
              maxLines: 3,
              decoration: decoration(
                t.descriptionOptional,
                hint: tr('وصف مختصر هنا...', 'A short description...'),
              ),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              key: ValueKey(
                'organization-link-$tab-${isDepartment ? managerId : departmentId}',
              ),
              initialValue: (isDepartment ? managerId : departmentId) ?? '',
              isExpanded: true,
              decoration: decoration(
                isDepartment
                    ? tr('مدير القسم', 'Department manager')
                    : t.department,
              ),
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(tr('بدون تحديد', 'Not assigned')),
                ),
                for (final entry
                    in (isDepartment ? managerOptions : departmentOptions)
                        .entries)
                  DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() {
                if (isDepartment) {
                  managerId = v == '' ? null : v;
                } else {
                  departmentId = v == '' ? null : v;
                }
              }),
            ),
            if (!isDepartment) ...[
              const SizedBox(height: 18),
              TextFormField(
                key: const ValueKey('organization-level'),
                controller: level,
                keyboardType: TextInputType.number,
                decoration: decoration(t.levelOptional),
                validator: (v) =>
                    (v ?? '').trim().isEmpty || int.tryParse(v!.trim()) != null
                    ? null
                    : tr('أدخل رقمًا صحيحًا', 'Enter a whole number'),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isDepartment
                        ? tr('حالة القسم', 'Department status')
                        : tr('حالة المسمى', 'Job title status'),
                    style: const TextStyle(fontSize: 13, color: ink),
                  ),
                ),
                Switch(
                  value: active,
                  activeThumbColor: Colors.white,
                  activeTrackColor: purple,
                  onChanged: (v) => setState(() => active = v),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    key: const ValueKey('organization-save'),
                    onPressed: saving || loading ? null : save,
                    style: FilledButton.styleFrom(
                      backgroundColor: purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      minimumSize: const Size.fromHeight(40),
                    ),
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(
                      isDepartment
                          ? tr('حفظ القسم', 'Save department')
                          : tr('حفظ المسمى', 'Save job title'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: saving ? null : () => setState(clear),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      minimumSize: const Size.fromHeight(40),
                      side: const BorderSide(color: border),
                    ),
                    child: Text(t.cancel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    final list = panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F2F7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: purple, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isDepartment
                        ? tr(
                            'الأقسام (${items.length})',
                            'Departments (${items.length})',
                          )
                        : tr(
                            'المسميات الوظيفية (${items.length})',
                            'Job titles (${items.length})',
                          ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: t.refresh,
                  onPressed: loading || saving ? null : load,
                  icon: const Icon(Icons.refresh, size: 18),
                ),
                if (isDepartment)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: t.autoAssignManagers,
                    onPressed: saving || loading ? null : runAutoAssign,
                    icon: const Icon(
                      Icons.auto_fix_high_outlined,
                      size: 18,
                      color: purple,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('organization-search'),
            controller: search,
            onChanged: (_) => setState(() => page = 0),
            decoration: decoration(
              tr('البحث بالاسم أو الرمز', 'Search by name or code'),
            ).copyWith(prefixIcon: const Icon(Icons.search, size: 20)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<bool>(
            key: ValueKey('organization-filter-$activeFilter'),
            initialValue: activeFilter,
            decoration: decoration(t.status),
            items: [
              DropdownMenuItem<bool>(value: null, child: Text(t.all)),
              DropdownMenuItem(value: true, child: Text(t.active)),
              DropdownMenuItem(value: false, child: Text(t.inactive)),
            ],
            onChanged: (v) => setState(() {
              activeFilter = v;
              page = 0;
            }),
          ),
          const SizedBox(height: 14),
          if (loading)
            const Padding(padding: EdgeInsets.all(24), child: AppLoadingState())
          else if (error != null)
            AppFailureState(error: error, onRetry: load)
          else if (items.isEmpty)
            AppEmptyState(
              filtered: search.text.trim().isNotEmpty || activeFilter != null,
              onClear: search.text.trim().isNotEmpty || activeFilter != null
                  ? () => setState(() {
                      search.clear();
                      activeFilter = null;
                      page = 0;
                    })
                  : null,
            )
          else
            LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: box.maxWidth),
                  child: DataTable(
                    headingRowHeight: 38,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 48,
                    columnSpacing: 20,
                    horizontalMargin: 10,
                    headingRowColor: const WidgetStatePropertyAll(
                      Color(0xFFF3F2F7),
                    ),
                    dividerThickness: .5,
                    columns: [
                      for (final label in [
                        t.name,
                        tr('الرمز', 'Code'),
                        isDepartment
                            ? tr('مدير القسم', 'Manager')
                            : t.department,
                        if (!isDepartment) tr('المستوى', 'Level'),
                        t.status,
                        t.actions,
                      ])
                        DataColumn(
                          label: Text(
                            label,
                            style: const TextStyle(fontSize: 12, color: ink),
                          ),
                        ),
                    ],
                    rows: visible.map((item) {
                      final d = item is Department ? item : null;
                      final j = item is JobTitle ? item : null;
                      final enabled = d?.isActive ?? j!.isActive;
                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 170,
                              child: Text(
                                d?.name ?? j!.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: ink,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              d?.code ?? j?.code ?? '—',
                              style: const TextStyle(fontSize: 12, color: ink),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 140,
                              child: Text(
                                d != null
                                    ? d.managerName ?? '—'
                                    : departmentOptions[j!.departmentId] ?? '—',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ink,
                                ),
                              ),
                            ),
                          ),
                          if (!isDepartment)
                            DataCell(Text(j!.level?.toString() ?? '—')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: enabled
                                    ? const Color(0xFFE2F8EF)
                                    : const Color(0xFFF2EFF6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                enabled ? t.active : t.inactive,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: enabled
                                      ? const Color(0xFF00876E)
                                      : const Color(0xFF77748B),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              key: ValueKey(
                                'organization-edit-${d?.id ?? j!.id}',
                              ),
                              tooltip: t.edit,
                              onPressed: saving ? null : () => edit(item),
                              style: IconButton.styleFrom(
                                backgroundColor: purple.withValues(alpha: .1),
                                foregroundColor: purple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                tr(
                  'عرض ${visible.length} من ${items.length}',
                  'Showing ${visible.length} of ${items.length}',
                ),
                style: const TextStyle(fontSize: 12, color: Color(0xFF66638B)),
              ),
              PageNavigationButtons(
                onPrevious: current > 0
                    ? () => setState(() => page = current - 1)
                    : null,
                onNext: current + 1 < pages
                    ? () => setState(() => page = current + 1)
                    : null,
                previousTooltip: tr('السابق', 'Previous'),
                nextTooltip: tr('التالي', 'Next'),
                center: Text(
                  textDirection: TextDirection.ltr,
                  '${current + 1} / $pages',
                  style: const TextStyle(color: purple, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: 500,
            child: Row(
              children: [
                for (var i = 0; i < 2; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: OutlinedButton.icon(
                        onPressed: saving
                            ? null
                            : () => setState(() {
                                tab = i;
                                clear();
                                search.clear();
                                page = 0;
                                activeFilter = null;
                              }),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: tab == i ? purple : Colors.white,
                          foregroundColor: tab == i ? Colors.white : ink,
                          side: const BorderSide(color: border),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        icon: Icon(
                          i == 0
                              ? Icons.account_tree_outlined
                              : Icons.work_outline,
                          size: 19,
                        ),
                        label: Text(
                          i == 0 ? t.menuDepartments : t.menuJobTitles,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        IgnorePointer(
          ignoring: saving,
          child: LayoutBuilder(
            builder: (context, box) => box.maxWidth >= 950
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: box.maxWidth * .36, child: editor),
                      const SizedBox(width: 16),
                      Expanded(child: list),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [editor, const SizedBox(height: 16), list],
                  ),
          ),
        ),
      ],
    );
  }
}
