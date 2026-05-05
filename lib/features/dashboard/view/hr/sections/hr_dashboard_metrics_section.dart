part of '../../dashboard_page.dart';

class _HrMetricSection extends StatelessWidget {
  const _HrMetricSection({
    required this.data,
    required this.isWide,
    required this.maxWidth,
  });

  final _HrDashboardData data;
  final bool isWide;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cardWidth = isWide ? (maxWidth - 24) / 2 : maxWidth;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricBarCard(
          width: cardWidth,
          title: t.checkInCoverage,
          value: data.checkInCoverage,
        ),
        _MetricBarCard(
          width: cardWidth,
          title: t.approvalLoad,
          value: data.approvalLoad,
          invertColor: true,
        ),
        _MetricBarCard(
          width: cardWidth,
          title: t.documentCompliance,
          value: data.documentCompliance,
        ),
      ],
    );
  }
}
