part of '../../dashboard_page.dart';

class _ManagerPerformanceSection extends StatelessWidget {
  const _ManagerPerformanceSection({required this.data});

  final _ManagerDashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _PerformanceListCard(title: t.topPerformers, emptyText: t.noTeamDataYet, members: data.topPerformers, color: Colors.green),
        _PerformanceListCard(title: t.needsAttention, emptyText: t.noTeamDataYet, members: data.needsAttention, color: Colors.orange),
      ],
    );
  }
}
