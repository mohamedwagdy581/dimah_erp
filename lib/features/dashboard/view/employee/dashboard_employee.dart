part of '../dashboard_page.dart';

class _EmployeeDashboard extends StatefulWidget {
  const _EmployeeDashboard({required this.employeeId});

  final String employeeId;

  @override
  State<_EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<_EmployeeDashboard> {
  late Future<EmployeeDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = widget._loadData();
  }

  @override
  void didUpdateWidget(covariant _EmployeeDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.employeeId != widget.employeeId) _future = widget._loadData();
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget._loadData();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EmployeeDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState();
        }
        if (snapshot.hasError) {
          return AppFailureState(
            error: snapshot.error,
            onRetry: () {
              _reload().catchError((Object _) {});
            },
          );
        }
        return RefreshIndicator(
          onRefresh: () => _reload().catchError((Object _) {}),
          child: EmployeeDashboardView(
            data: snapshot.data ?? const EmployeeDashboardData(),
            onRefresh: () {
              _reload().catchError((Object _) {});
            },
          ),
        );
      },
    );
  }
}
