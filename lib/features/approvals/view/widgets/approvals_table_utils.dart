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
    return 'HR';
  }
  if (role == 'admin') {
    return t.roleAdmin;
  }
  if (role == 'manager') {
    return t.directManager;
  }
  return role;
}
