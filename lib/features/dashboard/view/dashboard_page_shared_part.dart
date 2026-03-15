part of 'dashboard_page.dart';

class _SmallStatCard extends StatelessWidget {
  const _SmallStatCard({
    required this.title,
    required this.value,
    this.trendPercent,
    this.invertTrend = false,
  });

  final String title;
  final String value;
  final double? trendPercent;
  final bool invertTrend;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              if (trendPercent != null) ...[
                const SizedBox(height: 6),
                _TrendBadge(percent: trendPercent!, invert: invertTrend),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.percent, required this.invert});

  final double percent;
  final bool invert;

  @override
  Widget build(BuildContext context) {
    final up = percent >= 0;
    final good = invert ? !up : up;
    final color = good ? Colors.green : Colors.red;
    return Row(
      children: [
        Icon(
          up ? Icons.arrow_upward : Icons.arrow_downward,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '${percent.abs().toStringAsFixed(1)}%',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
