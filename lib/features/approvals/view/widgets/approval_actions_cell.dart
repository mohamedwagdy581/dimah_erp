import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/approval_request.dart';
import 'approvals_table_utils.dart';

class ApprovalActionsCell extends StatelessWidget {
  const ApprovalActionsCell({
    super.key,
    required this.request,
    required this.actorRole,
    required this.onApprove,
    required this.onReject,
  });

  final ApprovalRequest request;
  final String actorRole;
  final ValueChanged<String>? onApprove;
  final ValueChanged<String>? onReject;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isPending = request.status == 'pending';
    final isApproved = request.status == 'approved';
    final canAct = isPending &&
        (request.currentApproverRole ?? '').trim() == actorRole;

    if (canAct) {
      return Row(
        children: [
          TextButton(
            onPressed: onApprove == null ? null : () => onApprove!(request.id),
            child: Text(t.approve),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onReject == null ? null : () => onReject!(request.id),
            child: Text(t.reject),
          ),
        ],
      );
    }

    final color = isPending
        ? Colors.orange
        : isApproved
            ? Colors.green
            : Colors.red;
    final icon = isPending
        ? Icons.pending_actions
        : isApproved
            ? Icons.check_circle
            : Icons.cancel;
    final label = isPending
        ? approvalPendingWithLabel(t, request)
        : isApproved
            ? t.processedApproved
            : t.processedRejected;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
