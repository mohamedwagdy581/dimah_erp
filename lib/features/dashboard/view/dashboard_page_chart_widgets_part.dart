part of 'dashboard_page.dart';

class _LineTrendChart extends StatelessWidget {
  const _LineTrendChart({required this.series, required this.color});

  final List<_MonthlyMetricPoint> series;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, factor, _) => CustomPaint(
              painter: _LineTrendPainter(
                series: series,
                color: color,
                factor: factor,
                textColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: series
              .map(
                (point) => Text(
                  point.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _StackedMonthBar extends StatelessWidget {
  const _StackedMonthBar({
    required this.onTime,
    required this.delayed,
    required this.onTimeLabel,
    required this.delayedLabel,
  });

  final double onTime;
  final double delayed;
  final String onTimeLabel;
  final String delayedLabel;

  @override
  Widget build(BuildContext context) {
    final total = onTime + delayed;
    final onTimeFlex = total == 0 ? 0.5 : onTime / total;
    final delayedFlex = total == 0 ? 0.5 : delayed / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(
                  flex: (onTimeFlex * 1000).round().clamp(1, 999),
                  child: Container(color: const Color(0xFF22C55E)),
                ),
                Expanded(
                  flex: (delayedFlex * 1000).round().clamp(1, 999),
                  child: Container(color: const Color(0xFFEF4444)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$onTimeLabel ${onTime.toStringAsFixed(0)} | $delayedLabel ${delayed.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
