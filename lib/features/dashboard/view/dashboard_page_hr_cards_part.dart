part of 'dashboard_page.dart';

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.clamp(260, 420),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricBarCard extends StatelessWidget {
  const _MetricBarCard({
    required this.width,
    required this.title,
    required this.value,
    this.invertColor = false,
  });

  final double width;
  final String title;
  final double value;
  final bool invertColor;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 1).toDouble();
    final color = invertColor
        ? (v <= 0.2
              ? Colors.green
              : v <= 0.5
              ? Colors.orange
              : Colors.red)
        : (v >= 0.8
              ? Colors.green
              : v >= 0.5
              ? Colors.orange
              : Colors.red);
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: v,
                color: color,
                minHeight: 8,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 8),
              Text(
                '%',
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  const _MiniStatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: effectiveColor),
      title: Text(label),
      trailing: Text(
        value,
        style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}
