part of '../../dashboard_page.dart';

class _ManagerMembersSection extends StatelessWidget {
  const _ManagerMembersSection({
    required this.data,
    required this.onShowTimeline,
  });

  final _ManagerDashboardData data;
  final void Function(String employeeId, String employeeName) onShowTimeline;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: data.members.map((member) {
        return SizedBox(
          width: 220,
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onShowTimeline(member.employeeId, member.name),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _ProductivityCircle(value: member.productivityPercent, title: member.name),
                    const SizedBox(height: 8),
                    _InlineMetric(label: t.monthCompletionRate, value: '${member.monthCompletionPercent.toStringAsFixed(0)}%'),
                    const SizedBox(height: 6),
                    _AnimatedProgressBar(value: member.monthCompletionPercent, color: const Color(0xFF38BDF8)),
                    const SizedBox(height: 8),
                    Text(t.tasksWithValue(member.totalTasks)),
                    Text(t.doneWithValue(member.doneTasks)),
                    Text(t.monthTasksWithValue(member.monthTotalTasks)),
                    Text(t.completedThisMonthWithValue(member.monthDoneTasks)),
                    Text(
                      isArabic
                          ? 'الساعات المسجلة: ${member.loggedHours.toStringAsFixed(1)} / ${member.estimatedHours.toStringAsFixed(1)}h'
                          : 'Logged Hours: ${member.loggedHours.toStringAsFixed(1)} / ${member.estimatedHours.toStringAsFixed(1)}h',
                    ),
                    Text(t.avgTaskProgressWithValue(member.averageProgressPercent.toStringAsFixed(0))),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
