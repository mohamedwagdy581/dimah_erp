part of '../../dashboard_page.dart';


class _HrDashboardHeader extends StatelessWidget {
  const _HrDashboardHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(
          t.hrDashboard,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
