part of 'dashboard_page.dart';

class _HrDashboard extends StatefulWidget {
  const _HrDashboard();

  @override
  State<_HrDashboard> createState() => _HrDashboardState();
}

class _HrDashboardState extends State<_HrDashboard> {
  late Future<_HrDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HrDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _HrDashboardErrorView(message: snapshot.error!, onRetry: _refresh);
        }

        final data = snapshot.data ?? const _HrDashboardData();
        return LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 1200;
            final kpiWidth = isWide ? (c.maxWidth - 48) / 3 : 280.0;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HrDashboardHeader(onRefresh: _refresh),
                const SizedBox(height: 12),
                _HrKpiSection(data: data, kpiWidth: kpiWidth),
                const SizedBox(height: 12),
                _HrWorkflowPanel(data: data),
                const SizedBox(height: 12),
                _QuickActionsPanel(data: data),
                const SizedBox(height: 12),
                _HrMetricSection(data: data, isWide: isWide, maxWidth: c.maxWidth),
                const SizedBox(height: 12),
                _HrAttendanceSection(data: data, isWide: isWide, maxWidth: c.maxWidth),
                const SizedBox(height: 12),
                _HrRequestsSection(
                  data: data,
                  isWide: isWide,
                  maxWidth: c.maxWidth,
                  dateOnly: _dateOnly,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
