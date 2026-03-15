part of 'dashboard_page.dart';

extension _ManagerDashboardTaskTypeHelpers on _ManagerDashboardState {
  int _defaultWeightForType(String type) {
    switch (type) {
      case 'development':
        return 4;
      case 'bug_fix':
        return 4;
      case 'testing':
        return 3;
      case 'support':
        return 2;
      case 'transfer':
        return 1;
      case 'report':
        return 3;
      case 'tax':
        return 5;
      case 'payroll':
        return 4;
      case 'reconciliation':
        return 4;
      case 'recruitment':
        return 3;
      case 'onboarding':
        return 3;
      case 'employee_docs':
        return 2;
      default:
        return 3;
    }
  }

  String _taskTypeLabel(AppLocalizations t, String type) {
    switch (type) {
      case 'development':
        return t.taskTypeDevelopment;
      case 'bug_fix':
        return t.taskTypeBugFix;
      case 'testing':
        return t.taskTypeTesting;
      case 'support':
        return t.taskTypeSupport;
      case 'transfer':
        return t.taskTypeTransfer;
      case 'report':
        return t.taskTypeReport;
      case 'tax':
        return t.taskTypeTax;
      case 'payroll':
        return t.taskTypePayroll;
      case 'reconciliation':
        return t.taskTypeReconciliation;
      case 'recruitment':
        return t.taskTypeRecruitment;
      case 'onboarding':
        return t.taskTypeOnboarding;
      case 'employee_docs':
        return t.taskTypeEmployeeDocs;
      default:
        return t.taskTypeGeneral;
    }
  }
}
