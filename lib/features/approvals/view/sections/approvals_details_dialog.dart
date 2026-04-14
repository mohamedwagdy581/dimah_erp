import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/approval_request.dart';

void showApprovalDetailsDialog(BuildContext context, ApprovalRequest req) {
  final t = AppLocalizations.of(context)!;
  final payload = req.payload ?? {};

  // Basic payload data
  final notes = payload['notes']?.toString();
  final fileUrl = payload['file_url']?.toString();
  final reason = req.rejectReason ?? payload['reason']?.toString() ?? '-';
  final leaveId = payload['leave_id']?.toString();

  // Payroll specific payload data
  final isPayroll = req.requestType == 'payroll_run';
  final runId = payload['run_id']?.toString();

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(
            isPayroll ? Icons.payments_outlined : Icons.info_outline,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(t.requestDetails),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: FutureBuilder<Map<String, dynamic>>(
          future: isPayroll
              ? _loadPayrollExtras(runId)
              : _loadLeaveExtras(leaveId),
          builder: (context, snap) {
            final data = snap.data ?? {};

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: t.type, value: req.requestType.toUpperCase()),
                  _InfoRow(label: t.status, value: req.status.toUpperCase()),
                  const Divider(),

                  if (isPayroll) ...[
                    _InfoRow(
                      label: 'Period',
                      value:
                          '${data['period_start'] ?? '-'} to ${data['period_end'] ?? '-'}',
                    ),
                    _InfoRow(
                      label: 'Total Amount',
                      value: '${data['total_amount'] ?? '0'} SAR',
                      isBold: true,
                    ),
                    _InfoRow(
                      label: 'Employees',
                      value: '${data['total_employees'] ?? '0'}',
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push(
                            AppRoutes.payrollRun.replaceFirst(':runId', runId!),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('View Full Payroll Items'),
                      ),
                    ),
                  ] else ...[
                    _InfoRow(
                      label: t.notes,
                      value: notes ?? data['notes']?.toString() ?? '-',
                    ),
                    if (reason != '-') _InfoRow(label: t.reason, value: reason),

                    const SizedBox(height: 8),
                    _buildFileSection(
                      context,
                      fileUrl ?? data['file_url']?.toString() ?? '',
                      t,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.close)),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildFileSection(BuildContext context, String url, AppLocalizations t) {
  if (url.isEmpty)
    return Text('${t.file}: -', style: const TextStyle(fontSize: 13));

  return Row(
    children: [
      const Icon(Icons.attach_file, size: 16, color: Colors.blue),
      const SizedBox(width: 4),
      Expanded(child: Text(t.file, style: const TextStyle(fontSize: 13))),
      TextButton(
        onPressed: () => _openAttachment(context, url),
        child: Text(t.open),
      ),
    ],
  );
}

Future<Map<String, dynamic>> _loadPayrollExtras(String? runId) async {
  if (runId == null || runId.isEmpty) return {};
  final client = Supabase.instance.client;
  final data = await client
      .from('payroll_runs')
      .select('period_start, period_end, total_employees, total_amount')
      .eq('id', runId)
      .maybeSingle();
  return data ?? {};
}

Future<Map<String, dynamic>> _loadLeaveExtras(String? leaveId) async {
  if (leaveId == null || leaveId.isEmpty) return {};
  final client = Supabase.instance.client;
  final data = await client
      .from('leave_requests')
      .select('notes, file_url')
      .eq('id', leaveId)
      .maybeSingle();
  return data ?? {};
}

Future<void> _openAttachment(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
