part of '../../dashboard_page.dart';

class _HrAttendanceSection extends StatelessWidget {
  const _HrAttendanceSection({
    required this.data,
    required this.isWide,
    required this.maxWidth,
  });

  final _HrDashboardData data;
  final bool isWide;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final width = isWide ? (maxWidth - 24) / 2 : maxWidth;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _InsightPanel(
          width: width,
          title: t.todayAttendanceInsights,
          count: data.checkedInToday,
          emptyText: t.noAttendanceInsightsToday,
          children: [
            _MiniStatTile(
              icon: Icons.how_to_reg_outlined,
              label: t.checkedInTodayLabel,
              value: '${data.checkedInToday}',
            ),
            _MiniStatTile(
              icon: Icons.schedule_outlined,
              label: t.attendanceLate,
              value: '${data.lateToday}',
              color: Colors.orange,
            ),
            _MiniStatTile(
              icon: Icons.more_time_outlined,
              label: t.overtime,
              value: '${data.overtimeToday}',
              color: Colors.lightBlue,
            ),
            _MiniStatTile(
              icon: Icons.person_off_outlined,
              label: t.absentTodayLabel,
              value: '${data.missingCheckInToday}',
              color: Colors.redAccent,
            ),
          ],
        ),
        _InsightPanel(
          width: width,
          title: t.attendanceAlertsToday,
          count: data.todayAttentionItems.length,
          emptyText: t.noAttendanceAlertsToday,
          children: data.todayAttentionItems
              .map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    item.type == 'late'
                        ? Icons.schedule_outlined
                        : Icons.more_time_outlined,
                  ),
                  title: Text(item.employeeName),
                  trailing: Text(
                    item.valueLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: item.type == 'late'
                          ? Colors.orange
                          : Colors.lightBlue,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
