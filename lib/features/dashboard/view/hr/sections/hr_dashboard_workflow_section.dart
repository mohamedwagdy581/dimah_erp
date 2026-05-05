part of '../../dashboard_page.dart';

class _HrWorkflowOverviewSection extends StatelessWidget {
  const _HrWorkflowOverviewSection({required this.data});

  final _HrDashboardData data;

  @override
  Widget build(BuildContext context) {
    return _HrWorkflowPanel(data: data);
  }
}
