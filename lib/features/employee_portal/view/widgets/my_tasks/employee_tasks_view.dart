import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import 'employee_task_list.dart';
import 'task_filters_utils.dart';
import 'task_labels.dart';

/// Employee-only presentation. Mutations remain in MyTasksSection and its repo.
class EmployeeTasksView extends StatefulWidget {
  const EmployeeTasksView({
    super.key,
    required this.tasks,
    required this.onOpen,
    required this.onRefresh,
    this.loading = false,
    this.failed = false,
    this.error,
  });
  final List<Map<String, dynamic>> tasks;
  final ValueChanged<Map<String, dynamic>> onOpen;
  final VoidCallback onRefresh;
  final bool loading;
  final bool failed;
  final Object? error;

  @override
  State<EmployeeTasksView> createState() => _EmployeeTasksViewState();
}

class _EmployeeTasksViewState extends State<EmployeeTasksView> {
  final _searchController = TextEditingController();
  String _status = 'all';
  String _search = '';
  String _type = 'all';
  String _sort = 'due';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final cs = Theme.of(context).colorScheme;
    final fontScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final neutral = Theme.of(context).brightness == Brightness.dark
        ? cs.surfaceContainerLow
        : const Color(0xFFF5F7F8);
    InputDecoration controlDecoration({String? hint}) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: neutral,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE9EDF1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE9EDF1)),
      ),
    );
    final types =
        widget.tasks
            .map((task) => (task['task_type'] ?? 'general').toString())
            .toSet()
            .toList()
          ..sort();
    final type = types.contains(_type) ? _type : 'all';
    final items = filterEmployeeTasks(
      widget.tasks,
      status: _status,
      search: _search,
      type: type,
      sort: _sort,
    );
    final tabs = [
      ('all', ar ? 'الكل' : 'All'),
      ('todo', ar ? 'لم يبدأ' : 'Not started'),
      ('in_progress', t.statusInProgress),
      ('review_pending', ar ? 'بانتظار المراجعة' : 'Awaiting review'),
      ('done', ar ? 'مكتملة' : 'Completed'),
    ];
    final search = TextField(
      key: const ValueKey('employee-task-search'),
      controller: _searchController,
      onChanged: (value) => setState(() => _search = value),
      style: const TextStyle(fontSize: 14),
      decoration: controlDecoration(
        hint: ar ? 'البحث في المهام...' : 'Search tasks...',
      ).copyWith(prefixIcon: const Icon(Icons.search, size: 20)),
    );
    final typeFilter = DropdownButtonFormField<String>(
      key: ValueKey('task-type-$type'),
      initialValue: type,
      isExpanded: true,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium!.copyWith(fontSize: 14, color: cs.onSurface),
      decoration: controlDecoration(),
      items: [
        DropdownMenuItem(
          value: 'all',
          child: Text(ar ? 'جميع أنواع المهام' : 'All task types'),
        ),
        for (final value in types)
          DropdownMenuItem(value: value, child: Text(taskTypeLabel(t, value))),
      ],
      onChanged: (value) => setState(() => _type = value ?? 'all'),
    );
    final sortFilter = DropdownButtonFormField<String>(
      key: const ValueKey('employee-task-sort'),
      initialValue: _sort,
      isExpanded: true,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium!.copyWith(fontSize: 14, color: cs.onSurface),
      decoration: controlDecoration().copyWith(
        suffixIcon: const Icon(Icons.filter_alt_outlined, size: 16),
      ),
      items: [
        DropdownMenuItem(
          value: 'due',
          child: Text(ar ? 'ترتيب حسب: تاريخ الاستحقاق' : 'Sort: due date'),
        ),
        DropdownMenuItem(
          value: 'priority',
          child: Text(ar ? 'ترتيب حسب: الأولوية' : 'Sort: priority'),
        ),
        DropdownMenuItem(
          value: 'latest',
          child: Text(ar ? 'الأحدث' : 'Newest'),
        ),
      ],
      onChanged: (value) => setState(() => _sort = value ?? 'due'),
    );
    return ListView(
      padding: const EdgeInsets.all(18),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.list_alt_rounded, size: 26, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.myTasks,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ar
                        ? 'إدارة وتتبع جميع المهام الموكلة إليك'
                        : 'Manage and track your assigned tasks',
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.loading ? null : widget.onRefresh,
              tooltip: t.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 800 * fontScale
                        ? 5
                        : constraints.maxWidth >= 400
                        ? 3
                        : 2;
                    final width =
                        (constraints.maxWidth - (columns - 1) * 8) / columns;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tab in tabs)
                          SizedBox(
                            width: width,
                            child: Semantics(
                              selected: _status == tab.$1,
                              child: FilledButton(
                                key: ValueKey('task-filter-${tab.$1}'),
                                onPressed: () =>
                                    setState(() => _status = tab.$1),
                                style: FilledButton.styleFrom(
                                  foregroundColor: _status == tab.$1
                                      ? cs.onPrimary
                                      : cs.onSurface,
                                  backgroundColor: _status == tab.$1
                                      ? cs.primary
                                      : neutral,
                                  minimumSize: const Size(0, 44),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      tab.$2,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (tab.$1 != 'all' &&
                                        !widget.loading &&
                                        !widget.failed)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _status == tab.$1
                                              ? Colors.white.withValues(
                                                  alpha: .2,
                                                )
                                              : Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFFE2E7ED),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '${countByTaskFilter(widget.tasks, tab.$1)}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) =>
                      constraints.maxWidth >= 900 * fontScale
                      ? Row(
                          children: [
                            Expanded(flex: 4, child: search),
                            const SizedBox(width: 12),
                            Expanded(flex: 3, child: typeFilter),
                            const SizedBox(width: 12),
                            Expanded(flex: 3, child: sortFilter),
                          ],
                        )
                      : Column(
                          children: [
                            search,
                            const SizedBox(height: 16),
                            typeFilter,
                            const SizedBox(height: 16),
                            sortFilter,
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                if (widget.loading)
                  const Padding(
                    padding: EdgeInsets.all(36),
                    child: AppLoadingState(),
                  )
                else if (widget.failed)
                  AppFailureState(
                    error: widget.error,
                    onRetry: widget.onRefresh,
                  )
                else if (items.isEmpty)
                  AppEmptyState(
                    title: widget.tasks.isEmpty
                        ? t.noTasksAssigned
                        : (ar
                              ? 'لا توجد مهام تطابق البحث والفلاتر'
                              : 'No tasks match your search and filters'),
                    filtered: widget.tasks.isNotEmpty,
                    onClear: widget.tasks.isNotEmpty
                        ? () => setState(() {
                            _status = 'all';
                            _type = 'all';
                            _search = '';
                            _searchController.clear();
                          })
                        : null,
                  )
                else
                  EmployeeTaskList(tasks: items, onOpen: widget.onOpen),
                if (countByTaskFilter(widget.tasks, 'qa_pending') > 0 ||
                    _status == 'qa_pending')
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      key: const ValueKey('task-filter-qa_pending'),
                      onPressed: () => setState(
                        () => _status = _status == 'qa_pending'
                            ? 'all'
                            : 'qa_pending',
                      ),
                      icon: Icon(
                        _status == 'qa_pending'
                            ? Icons.check_circle
                            : Icons.fact_check_outlined,
                        size: 16,
                      ),
                      label: Text(
                        '${ar ? 'بانتظار فحص الجودة' : 'Awaiting QA'} (${countByTaskFilter(widget.tasks, 'qa_pending')})',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
