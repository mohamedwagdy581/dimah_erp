import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class ApprovalStatusChip extends StatelessWidget {
  const ApprovalStatusChip({
    super.key,
    required this.status,
    required this.t,
  });

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
