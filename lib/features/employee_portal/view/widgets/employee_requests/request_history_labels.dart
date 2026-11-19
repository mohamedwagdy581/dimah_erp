import 'package:material_ui/material_ui.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../approvals/domain/models/approval_request.dart';
import '../../../../leaves/domain/models/leave_request.dart';

String historyType(AppLocalizations t, String type, bool ar) => switch (type) {
  'leave' => t.leave,
  'attendance_correction' => ar ? 'تصحيح حضور' : 'Attendance correction',
  'payroll_run' => t.menuPayroll,
  _ => type,
};
String historyStatus(AppLocalizations t, String status) => switch (status) {
  'approved' => t.statusApproved,
  'rejected' => t.statusRejected,
  'pending' => t.statusPending,
  _ => status,
};
Color historyStatusColor(String status) => switch (status) {
  'approved' => const Color(0xFF009879),
  'rejected' => const Color(0xFFE53935),
  _ => const Color(0xFFF59E0B),
};
IconData historyStatusIcon(String status) => switch (status) {
  'approved' => Icons.check_circle_outline,
  'rejected' => Icons.cancel_outlined,
  _ => Icons.schedule,
};
String historyDate(Object? raw) {
  final date = raw is DateTime ? raw : DateTime.tryParse(raw?.toString() ?? '');
  if (date == null) return '—';
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

String historyTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
String historyPeriod(ApprovalRequest request) {
  final payload = request.payload ?? {};
  if (request.requestType == 'leave') {
    return '${historyDate(payload['start_date'])}\n${historyDate(payload['end_date'])}';
  }
  if (request.requestType != 'attendance_correction') return '—';
  String clock(Object? raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '');
    return date == null ? '—' : historyTime(date);
  }

  return '${historyDate(payload['date'])}\n${clock(payload['proposed_check_in'])} – ${clock(payload['proposed_check_out'])}';
}

LeaveRequest? historyResubmittableLeave(ApprovalRequest request) {
  if (request.requestType != 'leave' || request.status != 'rejected') {
    return null;
  }
  final p = request.payload ?? {};
  final id = p['leave_id']?.toString() ?? '';
  final start = DateTime.tryParse(p['start_date']?.toString() ?? '');
  final end = DateTime.tryParse(p['end_date']?.toString() ?? '');
  final type = (p['type'] ?? 'annual').toString();
  if (id.isEmpty ||
      start == null ||
      end == null ||
      end.isBefore(start) ||
      !const {'annual', 'sick', 'unpaid', 'other'}.contains(type)) {
    return null;
  }
  return LeaveRequest(
    id: id,
    tenantId: request.tenantId,
    employeeId: request.employeeId,
    employeeName: request.employeeName,
    type: type,
    startDate: start,
    endDate: end,
    status: 'rejected',
    createdAt: request.createdAt,
    notes: p['notes']?.toString(),
    fileUrl: p['file_url']?.toString(),
  );
}

class HistoryPanel extends StatelessWidget {
  const HistoryPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surface
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: .4),
      ),
    ),
    child: child,
  );
}
