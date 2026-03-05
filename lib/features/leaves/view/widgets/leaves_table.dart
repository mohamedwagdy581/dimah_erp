import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/leave_request.dart';

class LeavesTable extends StatelessWidget {
  const LeavesTable({
    super.key,
    required this.items,
    this.onResubmit,
  });

  final List<LeaveRequest> items;
  final ValueChanged<LeaveRequest>? onResubmit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text(t.noLeaveRequestsFound)),
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
                  DataColumn(label: Text(t.start)),
                  DataColumn(label: Text(t.end)),
                  DataColumn(label: Text(t.status)),
                  DataColumn(label: Text(t.notes)),
                  DataColumn(label: Text(t.action)),
                ],
                rows: items.map((r) {
                  final canResubmit =
                      onResubmit != null && r.status.toLowerCase() == 'rejected';
                  return DataRow(
                    cells: [
                      DataCell(Text(r.employeeName)),
                      DataCell(Text(r.type)),
                      DataCell(Text(_formatDate(r.startDate))),
                      DataCell(Text(_formatDate(r.endDate))),
                      DataCell(_LeaveStatusBadge(status: r.status, t: t)),
                      DataCell(Text(r.notes ?? '-')),
                      DataCell(
                        canResubmit
                            ? TextButton.icon(
                                onPressed: () => onResubmit!(r),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: Text(t.resubmit),
                              )
                            : const Text('-'),
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
}

class _LeaveStatusBadge extends StatelessWidget {
  const _LeaveStatusBadge({required this.status, required this.t});

  final String status;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final color = s == 'approved'
        ? Colors.green
        : s == 'rejected'
            ? Colors.red
            : Colors.orange;
    final icon = s == 'approved'
        ? Icons.check_circle
        : s == 'rejected'
            ? Icons.cancel
            : Icons.hourglass_top;
    final label = s == 'pending'
        ? t.statusPending
        : s == 'approved'
            ? t.statusApproved
            : s == 'rejected'
                ? t.statusRejected
                : t.unknown;

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
