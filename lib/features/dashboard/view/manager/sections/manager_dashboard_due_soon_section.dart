part of '../../dashboard_page.dart';

class _ManagerDueSoonSection extends StatelessWidget {
  const _ManagerDueSoonSection({required this.data});

  final _ManagerDashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _ManagerSimpleListCard(
      title: t.dueSoonTasks,
      emptyText: t.noDueSoonTasks,
      children: data.dueSoonTasks.map((task) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.schedule),
          title: Text(task['title']?.toString() ?? '-'),
          subtitle: Text('${task['employee_name'] ?? '-'} | ${task['due_date'] ?? '-'}'),
        );
      }).toList(),
    );
  }
}
