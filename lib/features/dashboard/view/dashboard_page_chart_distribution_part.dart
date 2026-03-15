part of 'dashboard_page.dart';

class _EmployeeWorkloadCard extends StatelessWidget {
  const _EmployeeWorkloadCard({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<_EmployeeWorkloadPoint> items;

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
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.employeeName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 110,
                          child: _AnimatedProgressBar(
                            value: items.first.tasks == 0
                                ? 0
                                : (item.tasks / items.first.tasks) * 100,
                            color: const Color(0xFFF97316),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${item.tasks}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
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

class _MonthlyStackedChartCard extends StatelessWidget {
  const _MonthlyStackedChartCard({
    required this.title,
    required this.subtitle,
    required this.series,
    required this.onTimeLabel,
    required this.delayedLabel,
  });

  final String title;
  final String subtitle;
  final List<_MonthlyDeliveryPoint> series;
  final String onTimeLabel;
  final String delayedLabel;

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
              ...series.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 34,
                        child: Text(
                          point.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StackedMonthBar(
                          onTime: point.onTime,
                          delayed: point.delayed,
                          onTimeLabel: onTimeLabel,
                          delayedLabel: delayedLabel,
                        ),
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
