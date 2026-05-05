part of '../dashboard_page.dart';

class _HrDashboardBody extends StatelessWidget {
  const _HrDashboardBody({
    required this.data,
    required this.onRefresh,
  });

  final _HrDashboardData data;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1200;
        final kpiWidth = isWide ? (constraints.maxWidth - 48) / 3 : 280.0;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HrDashboardHeader(onRefresh: onRefresh),
            const SizedBox(height: 12),
            _HrKpiSection(data: data, kpiWidth: kpiWidth),
            const SizedBox(height: 12),
            _HrWorkflowOverviewSection(data: data),
            const SizedBox(height: 12),
            _QuickActionsPanel(data: data),
            const SizedBox(height: 12),
            _HrMetricSection(
              data: data,
              isWide: isWide,
              maxWidth: constraints.maxWidth,
            ),
            const SizedBox(height: 12),
            _HrAttendanceSection(
              data: data,
              isWide: isWide,
              maxWidth: constraints.maxWidth,
            ),
            const SizedBox(height: 12),
            _HrRequestsSection(
              data: data,
              isWide: isWide,
              maxWidth: constraints.maxWidth,
              dateOnly: _formatDateOnly,
            ),
          ],
        );
      },
    );
  }

  String _formatDateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
