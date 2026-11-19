import 'package:material_ui/material_ui.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../approvals/domain/models/approval_request.dart';
import 'request_history_labels.dart';

class RequestHistoryDetails extends StatelessWidget {
  const RequestHistoryDetails({
    super.key,
    required this.request,
    required this.onResubmit,
    required this.onAttachment,
    this.busy = false,
  });
  final ApprovalRequest request;
  final VoidCallback onResubmit;
  final ValueChanged<String> onAttachment;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final p = request.payload ?? {};
    final color = historyStatusColor(request.status);
    final leave = request.requestType == 'leave';
    Widget field(String label, String value) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          SelectableText(
            value,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
    Widget heading(String label, IconData icon) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: cs.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    String leaveType() => switch (p['type']) {
      'annual' => t.leaveTypeAnnual,
      'sick' => t.leaveTypeSick,
      'unpaid' => t.leaveTypeUnpaid,
      'other' => t.leaveTypeOther,
      _ => '—',
    };
    final url = p['file_url']?.toString() ?? '';
    final approver = switch (request.currentApproverRole) {
      'manager' || 'direct_manager' => ar ? 'المدير المباشر' : 'Direct manager',
      'hr' => ar ? 'الموارد البشرية' : 'HR',
      'admin' => ar ? 'مدير النظام' : 'Administrator',
      null || '' => '—',
      _ => request.currentApproverRole!,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: .25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(historyStatusIcon(request.status), color: color, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${historyType(t, request.requestType, ar)} • ${historyStatus(t, request.status)}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      '${ar ? 'رقم الطلب' : 'Request ID'}: ${request.id}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        HistoryPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading(
                ar ? 'معلومات الطلب' : 'Request information',
                Icons.calendar_month,
              ),
              if (leave) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: field(t.startDate, historyDate(p['start_date'])),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: field(t.endDate, historyDate(p['end_date'])),
                    ),
                  ],
                ),
                field(ar ? 'نوع الإجازة' : 'Leave type', leaveType()),
                field(
                  ar ? 'سبب الإجازة' : 'Leave reason',
                  p['notes']?.toString() ?? '—',
                ),
              ] else ...[
                field(
                  ar
                      ? 'تاريخ الحضور والأوقات المقترحة'
                      : 'Attendance date and proposed times',
                  historyPeriod(request),
                ),
                field(
                  t.reason,
                  p['reason']?.toString() ?? p['notes']?.toString() ?? '—',
                ),
              ],
              if (request.rejectReason?.trim().isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ar ? 'سبب الرفض' : 'Rejection reason',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.rejectReason!,
                        style: const TextStyle(fontSize: 14, height: 1.7),
                      ),
                    ],
                  ),
                ),
              if (url.isNotEmpty)
                TextButton.icon(
                  onPressed: busy ? null : () => onAttachment(url),
                  icon: const Icon(Icons.attach_file),
                  label: Text(ar ? 'فتح المرفق' : 'Open attachment'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        HistoryPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading(ar ? 'سجل الطلب' : 'Request activity', Icons.history),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(historyStatusIcon(request.status), color: color),
                title: Text(
                  ar
                      ? 'الحالة الحالية: ${historyStatus(t, request.status)}'
                      : 'Current status: ${historyStatus(t, request.status)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: request.status == 'pending'
                    ? Text(
                        '${ar ? 'جهة المراجعة الحالية' : 'Current approver'}: $approver',
                      )
                    : null,
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.add_circle_outline, color: cs.primary),
                title: Text(
                  ar ? 'تم إنشاء الطلب' : 'Request created',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${historyDate(request.createdAt)}  ${historyTime(request.createdAt)}',
                  textDirection: TextDirection.ltr,
                ),
              ),
              if (historyResubmittableLeave(request) != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: ValueKey('request-resubmit-${request.id}'),
                  onPressed: busy ? null : onResubmit,
                  icon: const Icon(Icons.refresh),
                  label: Text(ar ? 'تعديل وإعادة تقديم' : 'Edit and resubmit'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
