import '../../../../l10n/app_localizations.dart';
import '../../domain/models/approval_request.dart';

String formatApprovalDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

String approvalPendingWithLabel(AppLocalizations t, ApprovalRequest request) {
  if (request.status != 'pending') {
    return '-';
  }
  final role = (request.currentApproverRole ?? '').trim();
  if (role.isEmpty) {
    return '-';
  }
  if (role == 'hr') {
    return t.localeName.startsWith('ar') ? 'الموارد البشرية' : 'HR';
  }
  if (role == 'admin') {
    return t.roleAdmin;
  }
  if (role == 'manager') {
    return t.directManager;
  }
  if (role == 'finance_manager') {
    return t.localeName.startsWith('ar') ? 'مدير المالية' : 'Finance manager';
  }
  return role;
}

String approvalTypeLabel(AppLocalizations t, String type) => switch (type
    .toLowerCase()) {
  'leave' => t.leave,
  'payroll_run' => t.menuPayroll,
  'early_exit' =>
    t.localeName.startsWith('ar') ? 'إذن خروج مبكر' : 'Early Exit Permission',
  'attendance_correction' =>
    t.localeName.startsWith('ar') ? 'تصحيح الحضور' : 'Attendance correction',
  _ => type,
};
