part of 'dashboard_page.dart';

class _MonthlyTrendChartCard extends StatelessWidget {
  const _MonthlyTrendChartCard({
    required this.title,
    required this.subtitle,
    required this.series,
    required this.color,
  });

  final String title;
  final String subtitle;
  final List<_MonthlyMetricPoint> series;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 180,
                child: _LineTrendChart(series: series, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTypeDistributionCard extends StatelessWidget {
  const _TaskTypeDistributionCard({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.labelBuilder,
  });

  final String title;
  final String subtitle;
  final List<_TaskTypeDistributionPoint> items;
  final String Function(String) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                Text(
                  '-',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...items.take(6).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                labelBuilder(item.taskType),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.count}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _AnimatedProgressBar(
                          value: items.first.count == 0
                              ? 0
                              : (item.count / items.first.count) * 100,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
