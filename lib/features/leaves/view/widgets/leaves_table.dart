import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/leave_request.dart';
import '../../../accounting/view/accounting_ui.dart';

class LeavesTable extends StatelessWidget {
  const LeavesTable({
    super.key,
    required this.items,
    this.onResubmit,
    this.managementStyle = false,
  });

  final List<LeaveRequest> items;
  final ValueChanged<LeaveRequest>? onResubmit;
  final bool managementStyle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: AppEmptyState(title: t.noLeaveRequestsFound, compact: false),
          ),
        ),
      );
    }

    if (managementStyle) {
      Widget cell(String value, {bool date = false}) => Text(
        value,
        textAlign: TextAlign.center,
        textDirection: date ? TextDirection.ltr : null,
        style: const TextStyle(
          color: Color(0xFF21194E),
          height: 1.6,
          fontSize: 14,
        ),
      );
      return AccountingTable(
        minimumWidth: 1050,
        headings: [t.employee, t.type, t.start, t.end, t.status, t.notes],
        widths: const [24, 14, 14, 14, 14, 22],
        rows: [
          for (final item in items)
            [
              cell(item.employeeName),
              cell(_leaveTypeLabel(item.type, t)),
              cell(_formatDate(item.startDate), date: true),
              cell(_formatDate(item.endDate), date: true),
              Center(
                child: _LeaveStatusBadge(status: item.status, t: t),
              ),
              cell(item.notes ?? '—'),
            ],
        ],
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
                      onResubmit != null &&
                      r.status.toLowerCase() == 'rejected';
                  return DataRow(
                    cells: [
                      DataCell(Text(r.employeeName)),
                      DataCell(Text(_leaveTypeLabel(r.type, t))),
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

  String _leaveTypeLabel(String type, AppLocalizations t) {
    switch (type.toLowerCase()) {
      case 'annual':
        return t.leaveTypeAnnual;
      case 'sick':
        return t.leaveTypeSick;
      case 'unpaid':
        return t.leaveTypeUnpaid;
      case 'other':
        return t.leaveTypeOther;
      default:
        return type;
    }
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
