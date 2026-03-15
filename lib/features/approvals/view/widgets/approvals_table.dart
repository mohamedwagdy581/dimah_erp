import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/approval_request.dart';
import 'approval_actions_cell.dart';
import 'approval_status_chip.dart';
import 'approvals_table_empty.dart';
import 'approvals_table_utils.dart';

class ApprovalsTable extends StatelessWidget {
  const ApprovalsTable({
    super.key,
    required this.items,
    required this.onApprove,
    required this.onReject,
    required this.actorRole,
    this.showActions = true,
    this.onViewDetails,
  });

  final List<ApprovalRequest> items;
  final ValueChanged<String>? onApprove;
  final ValueChanged<String>? onReject;
  final String actorRole;
  final bool showActions;
  final ValueChanged<ApprovalRequest>? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return const ApprovalsTableEmpty();
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
                  return DataRow(
                    cells: [
                      DataCell(Text(r.employeeName)),
                      DataCell(Text(r.requestType)),
                      DataCell(
                        ApprovalStatusChip(status: r.status, t: t),
                      ),
                      DataCell(Text(approvalPendingWithLabel(t, r))),
                      DataCell(Text(formatApprovalDate(r.createdAt))),
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
                          ApprovalActionsCell(
                            request: r,
                            actorRole: actorRole,
                            onApprove: onApprove,
                            onReject: onReject,
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
}
