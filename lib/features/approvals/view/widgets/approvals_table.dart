import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/approval_request.dart';

class ApprovalsTable extends StatelessWidget {
  const ApprovalsTable({
    super.key,
    required this.items,
    required this.onApprove,
    required this.onReject,
    this.showActions = true,
    this.onViewDetails,
  });

  final List<ApprovalRequest> items;
  final ValueChanged<String>? onApprove;
  final ValueChanged<String>? onReject;
  final bool showActions;
  final ValueChanged<ApprovalRequest>? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text(t.noApprovalsFound)),
        ),
      );
    }

    return Card(
      child: LayoutBuilder(
        builder: (context, c) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: c.maxWidth),
              child: DataTable(
                columns: [
                  DataColumn(label: Text(t.employee)),
                  DataColumn(label: Text(t.type)),
                  DataColumn(label: Text(t.status)),
                  DataColumn(label: Text(t.pendingWith)),
                  DataColumn(label: Text(t.created)),
                  DataColumn(label: Text(t.details)),
                  if (showActions) DataColumn(label: Text(t.actions)),
                ],
                rows: items.map((r) {
                  final isPending = r.status == 'pending';
                  final isApproved = r.status == 'approved';
                  return DataRow(
                    cells: [
                      DataCell(Text(r.employeeName)),
                      DataCell(Text(r.requestType)),
                      DataCell(
                        _StatusChip(status: r.status, t: t),
                      ),
                      DataCell(Text(_pendingWithLabel(t, r))),
                      DataCell(Text(_formatDate(r.createdAt))),
                      DataCell(
                        TextButton(
                          onPressed: onViewDetails == null
                              ? null
                              : () => onViewDetails!(r),
                          child: Text(t.view),
                        ),
                      ),
                      if (showActions)
                        DataCell(
                          isPending
                              ? Row(
                                  children: [
                                    TextButton(
                                      onPressed: onApprove == null
                                          ? null
                                          : () => onApprove!(r.id),
                                      child: Text(t.approve),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: onReject == null
                                          ? null
                                          : () => onReject!(r.id),
                                      child: Text(t.reject),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Icon(
                                      isApproved
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      size: 18,
                                      color: isApproved
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isApproved
                                          ? t.processedApproved
                                          : t.processedRejected,
                                      style: TextStyle(
                                        color: isApproved
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String _pendingWithLabel(AppLocalizations t, ApprovalRequest r) {
    if (r.status != 'pending') return '-';
    final role = (r.currentApproverRole ?? '').trim();
    if (role.isEmpty) return '-';
    if (role == 'hr') return 'HR';
    if (role == 'admin') return t.roleAdmin;
    if (role == 'manager') return t.directManager;
    return role;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.t});

  final String status;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final label = s == 'pending'
        ? t.statusPending
        : s == 'approved'
            ? t.statusApproved
            : s == 'rejected'
                ? t.statusRejected
                : t.unknown;
    final isPending = s == 'pending';
    final isApproved = s == 'approved';
    final color = isPending
        ? Colors.orange
        : isApproved
            ? Colors.green
            : Colors.red;
    final icon = isPending
        ? Icons.hourglass_top
        : isApproved
            ? Icons.check_circle
            : Icons.cancel;
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
