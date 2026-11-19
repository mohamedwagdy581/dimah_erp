import 'package:material_ui/material_ui.dart';

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
    final canAct =
        isPending && (request.currentApproverRole ?? '').trim() == actorRole;

    if (canAct) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.icon(
            icon: const Icon(Icons.check, size: 16),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8659BB),
            ),
            onPressed: onApprove == null ? null : () => onApprove!(request.id),
            label: Text(t.approve),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.close, size: 16),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC4545),
            ),
            onPressed: onReject == null ? null : () => onReject!(request.id),
            label: Text(t.reject),
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
