import 'package:material_ui/material_ui.dart';

import '../../domain/models/approval_request.dart';
import 'responsive_approvals_table.dart';

import 'approvals_table_empty.dart';

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
    if (items.isEmpty) {
      return const ApprovalsTableEmpty();
    }

    return ResponsiveApprovalsTable(
      items: items,
      onApprove: onApprove,
      onReject: onReject,
      actorRole: actorRole,
      showActions: showActions,
      onViewDetails: onViewDetails,
    );
  }
}
