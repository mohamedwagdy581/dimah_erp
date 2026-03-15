import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/session/session_cubit.dart';
import '../cubit/approvals_cubit.dart';
import '../cubit/approvals_state.dart';
import '../widgets/approvals_pagination_bar.dart';
import '../widgets/approvals_table.dart';
import 'approvals_details_dialog.dart';
import 'approvals_reject_dialog.dart';
import 'approvals_table_section_header.dart';

class ApprovalsTableSection extends StatelessWidget {
  const ApprovalsTableSection({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApprovalsCubit, ApprovalsState>(
      builder: (context, state) {
        final cubit = context.read<ApprovalsCubit>();
        final session = context.read<SessionCubit>().state;
        final actorRole = session is SessionReady
            ? (session.user.role == 'direct_manager'
                  ? 'manager'
                  : session.user.role)
            : '';

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApprovalsTableSectionHeader(cubit: cubit, state: state),
              const SizedBox(height: 12),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: ApprovalsTable(
                  items: state.items,
                  onApprove: readOnly ? null : cubit.approve,
                  onReject: readOnly
                      ? null
                      : (id) => openApprovalRejectDialog(context, id, cubit),
                  actorRole: actorRole,
                  showActions: !readOnly,
                  onViewDetails: (req) => showApprovalDetailsDialog(context, req),
                ),
              ),
              const SizedBox(height: 12),
              ApprovalsPaginationBar(
                page: state.page,
                totalPages: state.totalPages,
                total: state.total,
                canPrev: state.canPrev,
                canNext: state.canNext,
                onPrev: cubit.prevPage,
                onNext: cubit.nextPage,
                pageSize: state.pageSize,
                onPageSizeChanged: cubit.setPageSize,
              ),
            ],
          ),
        );
      },
    );
  }
}
