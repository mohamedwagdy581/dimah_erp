import '../../../../../l10n/app_localizations.dart';

String priorityLabel(AppLocalizations t, String priority) {
  switch (priority) {
    case 'low':
      return t.priorityLow;
    case 'high':
      return t.priorityHigh;
    default:
      return t.priorityMedium;
  }
}

String taskTypeLabel(AppLocalizations t, String type) {
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

String reviewStatusLabel(AppLocalizations t, String status) {
  switch (status) {
    case 'pending':
      return t.reviewPending;
    case 'approved':
      return t.reviewApproved;
    case 'rejected':
      return t.reviewRejected;
    default:
      return t.noActiveReview;
  }
}

String qaStatusLabel(AppLocalizations t, String status) {
  switch (status) {
    case 'accepted':
      return t.qaAccepted;
    case 'rework':
      return t.qaRework;
    case 'rejected':
      return t.qaRejected;
    default:
      return t.qaPending;
  }
}
