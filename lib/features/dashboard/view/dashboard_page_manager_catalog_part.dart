part of 'dashboard_page.dart';

extension _ManagerDashboardCatalogHelpers on _ManagerDashboardState {
  List<String> _taskCatalogForDepartments(List<String> departmentNames) {
    final catalog = <String>{'general'};
    for (final rawName in departmentNames) {
      final name = rawName.toLowerCase();
      if (name.contains('it') ||
          name.contains('tech') ||
          name.contains('develop') ||
          name.contains('برمج') ||
          name.contains('تقني') ||
          name.contains('التطوير')) {
        catalog.addAll([
          'development',
          'bug_fix',
          'testing',
          'support',
          'report',
        ]);
        continue;
      }
      if (name.contains('fin') ||
          name.contains('account') ||
          name.contains('مال') ||
          name.contains('محاسب')) {
        catalog.addAll([
          'transfer',
          'report',
          'tax',
          'payroll',
          'reconciliation',
        ]);
        continue;
      }
      if (name.contains('hr') ||
          name.contains('human') ||
          name.contains('بشر') ||
          name.contains('موارد')) {
        catalog.addAll([
          'recruitment',
          'employee_docs',
          'onboarding',
          'report',
        ]);
        continue;
      }
      catalog.add('report');
    }
    return catalog.toList();
  }
}
