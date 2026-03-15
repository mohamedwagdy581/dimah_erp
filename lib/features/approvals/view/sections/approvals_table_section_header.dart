import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/approvals_cubit.dart';
import '../cubit/approvals_state.dart';

class ApprovalsTableSectionHeader extends StatelessWidget {
  const ApprovalsTableSectionHeader({
    super.key,
    required this.cubit,
    required this.state,
  });

  final ApprovalsCubit cubit;
  final ApprovalsState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.menuApprovals,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String?>(
              value: state.status,
              onChanged: cubit.statusFilterChanged,
              items: [
                DropdownMenuItem(value: null, child: Text(t.all)),
                DropdownMenuItem(
                  value: 'pending_assigned',
                  child: Text(t.assignedToMe),
                ),
                DropdownMenuItem(value: 'pending', child: Text(t.statusPending)),
                DropdownMenuItem(value: 'approved', child: Text(t.statusApproved)),
                DropdownMenuItem(value: 'rejected', child: Text(t.statusRejected)),
              ],
            ),
            DropdownButton<String?>(
              value: state.requestType,
              onChanged: cubit.typeFilterChanged,
              items: [
                DropdownMenuItem(value: null, child: Text(t.allTypes)),
                DropdownMenuItem(value: 'leave', child: Text(t.leave)),
                DropdownMenuItem(
                  value: 'attendance_correction',
                  child: Text(t.menuAttendance),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () => cubit.toggleSort('created_at'),
              icon: const Icon(Icons.schedule),
              label: Text(
                state.sortBy == 'created_at'
                    ? (state.ascending ? t.createdAsc : t.createdDesc)
                    : t.sortCreated,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
