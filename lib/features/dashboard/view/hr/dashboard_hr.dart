part of '../dashboard_page.dart';

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
          return _HrDashboardErrorView(
            message: snapshot.error!,
            onRetry: _refresh,
          );
        }

        return _HrDashboardBody(
          data: snapshot.data ?? const _HrDashboardData(),
          onRefresh: _refresh,
        );
      },
    );
  }
}
