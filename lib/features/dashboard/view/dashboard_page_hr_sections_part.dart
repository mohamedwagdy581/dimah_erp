part of 'dashboard_page.dart';

extension _HrDashboardViewHelpers on _HrDashboardState {
  String _dateOnly(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}
