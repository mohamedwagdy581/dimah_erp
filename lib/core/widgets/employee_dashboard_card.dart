import 'package:material_ui/material_ui.dart';

class EmployeeDashboardCard extends StatelessWidget {
  const EmployeeDashboardCard({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    ),
  );
}

class EmployeeStatCard extends StatelessWidget {
  const EmployeeStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: .09),
                child: Icon(icon, color: color, size: 23),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 24),
          TextButton(
            onPressed: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Text(actionLabel)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
