part of '../../dashboard_page.dart';

class _ManagerOverviewSection extends StatelessWidget {
  const _ManagerOverviewSection({required this.data});

  final _ManagerDashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.monthDepartmentOverview, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ManagerMetricGauge(title: t.monthCompletionRate, value: data.monthCompletionRate, color: const Color(0xFF22C55E)),
                _ManagerMetricGauge(title: t.monthOnTimeRate, value: data.monthOnTimeRate, color: const Color(0xFF38BDF8)),
                _ManagerMetricGauge(title: t.monthDepartmentProductivity, value: data.monthProductivityPercent, color: const Color(0xFFF59E0B)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
