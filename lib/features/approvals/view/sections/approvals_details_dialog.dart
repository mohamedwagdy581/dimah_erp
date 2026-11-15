import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/approval_request.dart';
import '../../../payroll/view/widgets/payroll_format.dart';

void showApprovalDetailsDialog(
  BuildContext context,
  ApprovalRequest req, {
  Future<Map<String, dynamic>> Function()? loadExtras,
  ValueChanged<String>? onOpenPayroll,
}) {
  final t = AppLocalizations.of(context)!;
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => ar ? a : e;
  final payload = req.payload ?? {};

  // Basic payload data
  final notes = payload['notes']?.toString();
  final fileUrl = payload['file_url']?.toString();
  final reason = req.rejectReason ?? payload['reason']?.toString() ?? '-';
  final leaveId = payload['leave_id']?.toString();

  // Payroll specific payload data
  final isPayroll = req.requestType == 'payroll_run';
  final runId = payload['run_id']?.toString();
  final loader =
      loadExtras ??
      () => isPayroll
          ? _loadPayrollExtras(runId, req.tenantId)
          : _loadLeaveExtras(leaveId, req.tenantId);
  var future = loader();

  showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, refresh) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        titlePadding: const EdgeInsets.all(24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.all(24),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFF0E5FF),
              child: Icon(
                isPayroll ? Icons.payments_outlined : Icons.info_outline,
                color: const Color(0xFF8855BF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.requestDetails,
                    style: const TextStyle(
                      color: Color(0xFF19144F),
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _approvalTypeLabel(req.requestType, t),
                    style: const TextStyle(
                      color: Color(0xFF77709A),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: t.close,
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, color: Color(0xFF77709A)),
            ),
          ],
        ),
        content: SizedBox(
          width: 560,
          child: FutureBuilder<Map<String, dynamic>>(
            future: future,
            builder: (context, snap) {
              final data = snap.data ?? {};

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: t.status,
                      value: _approvalStatusLabel(req.status, t),
                    ),
                    _InfoRow(
                      label: tr('الموظف', 'Employee'),
                      value: req.employeeName.isEmpty ? '—' : req.employeeName,
                    ),
                    _InfoRow(
                      label: tr('تاريخ الطلب', 'Request date'),
                      value: payrollDate(req.createdAt),
                      ltr: true,
                    ),
                    const SizedBox(height: 12),
                    if (snap.connectionState == ConnectionState.waiting)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            children: [
                              const SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Color(0xFF8855BF),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                tr(
                                  'جارٍ تحميل التفاصيل...',
                                  'Loading details...',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (snap.hasError)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3F3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              tr(
                                'تعذّر تحميل التفاصيل. تحقق من الاتصال وأعد المحاولة.',
                                'Could not load details. Check your connection and retry.',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            TextButton.icon(
                              onPressed: () => refresh(() {
                                future = loader();
                              }),
                              icon: const Icon(Icons.refresh),
                              label: Text(tr('إعادة المحاولة', 'Retry')),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      if (isPayroll) ...[
                        _InfoRow(
                          label: tr('فترة الرواتب', 'Payroll period'),
                          value:
                              '${data['period_start'] ?? '—'}  -  ${data['period_end'] ?? '—'}',
                          ltr: true,
                        ),
                        _InfoRow(
                          label: tr('إجمالي الرواتب', 'Total salaries'),
                          value: data['total_amount'] == null
                              ? '—'
                              : '${payrollMoney(num.tryParse(data['total_amount'].toString()) ?? 0)} ${tr('ريال', 'SAR')}',
                          isBold: true,
                        ),
                        _InfoRow(
                          label: tr('عدد الموظفين', 'Employees'),
                          value: '${data['total_employees'] ?? '—'}',
                        ),
                        if (payload['finance_review_notes'] != null)
                          _InfoRow(
                            label:
                                Localizations.localeOf(context).languageCode ==
                                    'ar'
                                ? 'ملاحظات المراجعة المالية'
                                : 'Finance review notes',
                            value: payload['finance_review_notes'].toString(),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF8855BF),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: runId == null || runId.isEmpty
                                ? null
                                : () {
                                    Navigator.pop(ctx);
                                    if (onOpenPayroll != null) {
                                      onOpenPayroll(runId);
                                    } else {
                                      context.push(
                                        AppRoutes.payrollRun.replaceFirst(
                                          ':runId',
                                          runId,
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.visibility_outlined),
                            label: Text(
                              tr(
                                'عرض تفاصيل مسير الرواتب',
                                'View full payroll details',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ] else ...[
                        if (payload['reference'] != null)
                          _InfoRow(
                            label: tr('رقم الطلب', 'Request number'),
                            value: payload['reference'].toString(),
                            ltr: true,
                          ),
                        if (req.requestType == 'early_exit') ...[
                          _InfoRow(
                            label: tr('تاريخ الخروج', 'Exit date'),
                            value: payload['date']?.toString() ?? '-',
                            ltr: true,
                          ),
                          _InfoRow(
                            label: tr('وقت الخروج', 'Departure time'),
                            value: payload['departure']?.toString() ?? '-',
                            ltr: true,
                          ),
                          _InfoRow(
                            label: tr('نهاية الدوام', 'Shift end'),
                            value: payload['shift_end']?.toString() ?? '-',
                            ltr: true,
                          ),
                        ],
                        if (req.requestType == 'leave' &&
                            payload['hr_draft_id'] != null) ...[
                          _InfoRow(
                            label: tr('من تاريخ', 'From'),
                            value: payload['start_date']?.toString() ?? '-',
                            ltr: true,
                          ),
                          _InfoRow(
                            label: tr('إلى تاريخ', 'To'),
                            value: payload['end_date']?.toString() ?? '-',
                            ltr: true,
                          ),
                          _InfoRow(
                            label: tr('نوع الإجازة', 'Leave type'),
                            value: payload['type']?.toString() ?? '-',
                          ),
                        ],
                        _InfoRow(
                          label: t.notes,
                          value: notes ?? data['notes']?.toString() ?? '-',
                        ),

                        const SizedBox(height: 8),
                        _buildFileSection(
                          context,
                          fileUrl ?? data['file_url']?.toString() ?? '',
                          t,
                        ),
                      ],
                    ],
                    if (reason != '-')
                      _InfoRow(
                        label: req.rejectReason != null
                            ? tr('سبب الرفض', 'Rejection reason')
                            : t.reason,
                        value: reason,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8855BF),
              side: const BorderSide(color: Color(0xFFE8DFFA)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(t.close),
          ),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.ltr = false,
  });
  final String label;
  final String value;
  final bool isBold;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      label,
      style: const TextStyle(color: Color(0xFF77709A), fontSize: 14),
    );
    final content = SelectableText(
      value,
      textDirection: ltr ? TextDirection.ltr : null,
      style: TextStyle(
        color: const Color(0xFF19144F),
        fontSize: isBold ? 20 : 15,
        fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
      ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isBold ? const Color(0xFFF1E8FC) : const Color(0xFFFCFAFF),
        border: Border.all(color: const Color(0xFFE8DFFA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, box) => box.maxWidth < 350
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [title, const SizedBox(height: 8), content],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: title),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: content),
                ],
              ),
      ),
    );
  }
}

Widget _buildFileSection(BuildContext context, String url, AppLocalizations t) {
  if (url.isEmpty) {
    return Text('${t.file}: -', style: const TextStyle(fontSize: 13));
  }

  return Row(
    children: [
      const Icon(Icons.attach_file, size: 20, color: Color(0xFF8855BF)),
      const SizedBox(width: 4),
      Expanded(child: Text(t.file, style: const TextStyle(fontSize: 13))),
      TextButton(
        onPressed: () => _openAttachment(context, url),
        child: Text(t.open),
      ),
    ],
  );
}

Future<Map<String, dynamic>> _loadPayrollExtras(
  String? runId,
  String tenantId,
) async {
  if (runId == null || runId.isEmpty) return {};
  final client = Supabase.instance.client;
  final data = await client
      .from('payroll_runs')
      .select('period_start, period_end, total_employees, total_amount')
      .eq('id', runId)
      .eq('tenant_id', tenantId)
      .maybeSingle();
  return data ?? {};
}

Future<Map<String, dynamic>> _loadLeaveExtras(
  String? leaveId,
  String tenantId,
) async {
  if (leaveId == null || leaveId.isEmpty) return {};
  final client = Supabase.instance.client;
  final data = await client
      .from('leave_requests')
      .select('notes, file_url')
      .eq('id', leaveId)
      .eq('tenant_id', tenantId)
      .maybeSingle();
  return data ?? {};
}

String _approvalTypeLabel(String requestType, AppLocalizations t) {
  switch (requestType.toLowerCase()) {
    case 'leave':
      return t.leave;
    case 'payroll_run':
      return t.menuPayroll;
    case 'early_exit':
      return t.localeName.startsWith('ar')
          ? 'إذن خروج مبكر'
          : 'Early Exit Permission';
    case 'attendance_correction':
      return t.localeName.startsWith('ar')
          ? 'تصحيح الحضور'
          : 'Attendance correction';
    default:
      return requestType;
  }
}

String _approvalStatusLabel(String status, AppLocalizations t) {
  switch (status.toLowerCase()) {
    case 'pending':
      return t.statusPending;
    case 'approved':
      return t.statusApproved;
    case 'rejected':
      return t.statusRejected;
    default:
      return status;
  }
}

Future<void> _openAttachment(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
