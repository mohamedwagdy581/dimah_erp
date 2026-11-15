part of 'manager_team_page.dart';

extension _ManagerTeamTables on _ManagerTeamViewState {
  Widget _membersPanel(ManagerTeamData data) {
    final filtered = data.members
        .where((m) => m.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    final visible = _allMembers ? filtered : filtered.take(6).toList();
    return KeyedSubtree(
      key: _membersKey,
      child: _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr('توزيع عبء العمل على الفريق', 'Team workload'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: tr('بحث في الفريق', 'Search team'),
                  onPressed: _toggleSearch,
                  icon: const Icon(Icons.search_rounded, size: 19),
                  visualDensity: VisualDensity.compact,
                ),
                TextButton(
                  onPressed: _toggleMembers,
                  child: Text(
                    _allMembers
                        ? tr('عرض مختصر', 'Show less')
                        : tr('عرض الكل', 'View all'),
                  ),
                ),
              ],
            ),
            if (_showSearch) ...[
              const SizedBox(height: 8),
              TextField(
                onChanged: _searchMembers,
                decoration: InputDecoration(
                  hintText: tr('ابحث باسم الموظف', 'Search employee name'),
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  filled: true,
                  fillColor: EmployeeTheme.primary.withValues(alpha: .04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            _memberRow(
              tr('الموظف', 'Employee'),
              tr('المهام النشطة', 'Active tasks'),
              Text(
                tr('متوسط تقدم المهام', 'Average task progress'),
                textAlign: TextAlign.center,
              ),
              heading: true,
            ),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(tr('لا توجد نتائج مطابقة', 'No matching results')),
              ),
            for (final member in visible)
              InkWell(
                onTap: () => _showMember(data, member),
                child: _memberRow(
                  member.name,
                  '${data.tasksFor(member.id).where((t) => !t.done).length}',
                  _completion(data.averageProgress(member.id)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _memberRow(
    String name,
    String tasks,
    Widget progress, {
    bool heading = false,
  }) => Container(
    padding: EdgeInsets.symmetric(vertical: heading ? 10 : 12, horizontal: 8),
    decoration: BoxDecoration(
      color: heading ? EmployeeTheme.primary.withValues(alpha: .06) : null,
      border: Border(
        bottom: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: .15),
        ),
      ),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 5,
          child: Row(
            children: [
              if (!heading) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: EmployeeTheme.primary.withValues(alpha: .12),
                  child: Text(
                    name
                        .trim()
                        .split(RegExp(r'\s+'))
                        .where((part) => part.isNotEmpty)
                        .take(2)
                        .map((part) => part.characters.first)
                        .join(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: EmployeeTheme.dark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Tooltip(
                  message: name,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: heading ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            tasks,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Expanded(flex: 4, child: progress),
      ],
    ),
  );
  Widget _completion(double ratio) {
    final color = ratio >= .7
        ? const Color(0xFF009B7B)
        : ratio >= .4
        ? const Color(0xFFFFB300)
        : const Color(0xFFEF476F);
    return LayoutBuilder(
      builder: (context, box) {
        final label = Text(
          '${(ratio * 100).round()}%',
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        );
        final bar = Directionality(
          textDirection: TextDirection.ltr,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: .1),
            ),
          ),
        );
        if (box.maxWidth < 110) {
          return Column(children: [label, const SizedBox(height: 5), bar]);
        }
        return Row(
          textDirection: TextDirection.ltr,
          children: [
            SizedBox(
              width: MediaQuery.textScalerOf(context).scale(39),
              child: Text(
                '${(ratio * 100).round()}%',
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(child: bar),
          ],
        );
      },
    );
  }

  Widget _tasksPanel(ManagerTeamData data, DateTime now) {
    final rows = switch (_filter) {
      'overdue' => data.overdue(now),
      'reviews' => data.reviews,
      'all' => data.tasks.where((t) => !t.done).toList(),
      _ => data.upcoming(now),
    };
    rows.sort(
      (a, b) => (a.due ?? DateTime(9999)).compareTo(b.due ?? DateTime(9999)),
    );
    return KeyedSubtree(
      key: _tasksKey,
      child: _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    switch (_filter) {
                      'overdue' => tr(
                        'المهام المتأخرة لفريقي',
                        'Overdue team tasks',
                      ),
                      'reviews' => tr(
                        'مهام الفريق بانتظار المراجعة',
                        'Tasks awaiting review',
                      ),
                      'all' => tr('المهام النشطة لفريقي', 'Active team tasks'),
                      _ => tr('المهام القادمة لفريقي', 'Upcoming team tasks'),
                    },
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: tr('فلترة المهام', 'Filter tasks'),
                  icon: const Icon(Icons.tune_rounded, size: 19),
                  onSelected: _changeFilter,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'upcoming',
                      child: Text(
                        tr(
                          'المهام القادمة خلال ٧ أيام',
                          'Due in the next 7 days',
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'overdue',
                      child: Text(tr('المهام المتأخرة', 'Overdue tasks')),
                    ),
                    PopupMenuItem(
                      value: 'reviews',
                      child: Text(tr('في انتظار المراجعة', 'Awaiting review')),
                    ),
                    PopupMenuItem(
                      value: 'all',
                      child: Text(tr('كل المهام النشطة', 'All active tasks')),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _changeFilter('all'),
                  child: Text(tr('عرض الكل', 'View all')),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_filter == 'reviews')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.managerReviews),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(
                    tr(
                      'فتح شاشة المراجعات الحالية',
                      'Open current review screen',
                    ),
                  ),
                ),
              ),
            LayoutBuilder(
              builder: (context, box) {
                if (rows.isEmpty) {
                  return Column(
                    children: [
                      if (box.maxWidth >= 420)
                        _taskRow(
                          Text(tr('المهمة', 'Task')),
                          Text(tr('الموظف', 'Employee')),
                          Text(
                            tr('تاريخ الاستحقاق', 'Due date'),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            tr('الأولوية', 'Priority'),
                            textAlign: TextAlign.center,
                          ),
                          heading: true,
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Text(
                          tr(
                            'لا توجد مهام في هذا العرض',
                            'No tasks in this view',
                          ),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                if (box.maxWidth < 420) {
                  return Column(
                    children: rows
                        .map(
                          (task) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(data.nameFor(task.employeeId)),
                                _taskProgress(task),
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 12,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      _date(task.due),
                                      textDirection: TextDirection.ltr,
                                    ),
                                    _priority(task.priority),
                                  ],
                                ),
                                const Divider(),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  );
                }
                return Column(
                  children: [
                    _taskRow(
                      Text(tr('المهمة', 'Task')),
                      Text(tr('الموظف', 'Employee')),
                      Text(
                        tr('تاريخ الاستحقاق', 'Due date'),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        tr('الأولوية', 'Priority'),
                        textAlign: TextAlign.center,
                      ),
                      heading: true,
                    ),
                    for (final task in rows)
                      _taskRow(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _taskProgress(task),
                          ],
                        ),
                        Text(data.nameFor(task.employeeId)),
                        Text(
                          _date(task.due),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                        ),
                        _priority(task.priority),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskRow(
    Widget title,
    Widget employee,
    Widget date,
    Widget priority, {
    bool heading = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
    decoration: BoxDecoration(
      color: heading ? EmployeeTheme.primary.withValues(alpha: .06) : null,
      border: Border(
        bottom: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: .15),
        ),
      ),
    ),
    child: DefaultTextStyle.merge(
      style: TextStyle(
        fontSize: 14,
        fontWeight: heading ? FontWeight.w700 : FontWeight.w500,
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: title),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: employee),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: date),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: priority),
        ],
      ),
    ),
  );
  String _date(DateTime? value) => value == null
      ? '—'
      : '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
  Widget _priority(String value) {
    final color = switch (value) {
      'high' => const Color(0xFFEF476F),
      'low' => const Color(0xFF1685DE),
      _ => const Color(0xFFF39B00),
    };
    final label = switch (value) {
      'high' => tr('عالية', 'High'),
      'low' => tr('منخفضة', 'Low'),
      _ => tr('متوسطة', 'Medium'),
    };
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showMember(ManagerTeamData data, TeamMember member) {
    final rows = data.tasksFor(member.id);
    showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(member.name),
        content: SizedBox(
          width: 560,
          height: 350,
          child: rows.isEmpty
              ? Text(
                  tr(
                    'لا توجد مهام موكلة لهذا الموظف',
                    'No tasks assigned to this employee',
                  ),
                )
              : ListView(
                  children: rows
                      .map(
                        (task) => ListTile(
                          title: Text(task.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(_date(task.due)),
                              const SizedBox(height: 6),
                              _taskProgress(task),
                            ],
                          ),
                          trailing: SizedBox(
                            width: 90,
                            child: _priority(task.priority),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text(tr('إغلاق', 'Close')),
          ),
        ],
      ),
    );
  }

  Widget _taskProgress(TeamTask task) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${_taskStatus(task)} • ${task.progress.round()}%',
        style: const TextStyle(fontSize: 12, color: EmployeeTheme.dark),
      ),
      const SizedBox(height: 4),
      Directionality(
        textDirection: TextDirection.ltr,
        child: LinearProgressIndicator(
          value: task.progress / 100,
          minHeight: 4,
          borderRadius: BorderRadius.circular(4),
          color: EmployeeTheme.primary,
          backgroundColor: EmployeeTheme.primary.withValues(alpha: .1),
        ),
      ),
    ],
  );
  String _taskStatus(TeamTask task) => task.reviewPending
      ? tr('بانتظار المراجعة', 'Awaiting review')
      : switch (task.status) {
          'done' => tr('مكتملة', 'Completed'),
          'in_progress' => tr('قيد التنفيذ', 'In progress'),
          'blocked' => tr('متوقفة', 'Blocked'),
          _ => tr('لم تبدأ', 'Not started'),
        };
}
