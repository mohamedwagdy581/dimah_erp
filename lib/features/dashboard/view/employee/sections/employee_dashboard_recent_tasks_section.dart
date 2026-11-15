part of '../../dashboard_page.dart';

class _EmployeeRecentTasksCard extends StatelessWidget {
  const _EmployeeRecentTasksCard({required this.data});
  final EmployeeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final tasks = data.recentTasks
        .where((task) => task['status'] != 'done')
        .take(4)
        .toList();
    return EmployeeDashboardCard(
      title: ar ? 'المهام التالية' : 'Upcoming tasks',
      actionLabel: ar ? 'عرض الكل' : 'View all',
      onAction: () => context.go('/my?tab=tasks'),
      child: tasks.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: AppEmptyState(title: t.noDueSoonTasks, compact: false),
            )
          : Column(
              children: [
                for (var i = 0; i < tasks.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  InkWell(
                    onTap: () => context.go('/my?tab=tasks'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tasks[i]['title']?.toString() ?? '—',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios, size: 12),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _EmployeePriorityBadge(
                                priority: (tasks[i]['priority'] ?? 'medium')
                                    .toString(),
                              ),
                              Text(
                                tasks[i]['status'] == 'in_progress'
                                    ? t.statusInProgress
                                    : t.statusTodo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (DateTime.tryParse(
                                    tasks[i]['due_date']?.toString() ?? '',
                                  ) !=
                                  null)
                                Text(
                                  _dateOnlyFromRaw(
                                    tasks[i]['due_date']?.toString(),
                                  ),
                                  textDirection: TextDirection.ltr,
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _EmployeePriorityBadge extends StatelessWidget {
  const _EmployeePriorityBadge({required this.priority});
  final String priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      'high' => const Color(0xFFEF4444),
      'low' => const Color(0xFF1677FF),
      _ => const Color(0xFFF59E0B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priorityLabel(AppLocalizations.of(context)!, priority),
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}
