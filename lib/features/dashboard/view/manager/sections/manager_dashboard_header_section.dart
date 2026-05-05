part of '../../dashboard_page.dart';

class _ManagerDashboardHeader extends StatelessWidget {
  const _ManagerDashboardHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(
          t.teamProductivity,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: Text(t.refresh),
        ),
      ],
    );
  }
}
