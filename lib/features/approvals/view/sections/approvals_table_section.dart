import 'package:erp_sys/core/ui/app_data_state.dart';
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

        final workspace = Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5DDF2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApprovalsTableSectionHeader(cubit: cubit, state: state),
                const SizedBox(height: 12),
                Expanded(
                  child: AppDataRegion(
                    loading: state.loading,
                    error: state.error,
                    empty: state.items.isEmpty,
                    filtered: state.status != null || state.requestType != null,
                    onClear: cubit.resetFilters,
                    onRetry: cubit.load,
                    child: ApprovalsTable(
                      items: state.items,
                      onApprove: readOnly ? null : cubit.approve,
                      onReject: readOnly
                          ? null
                          : (id) =>
                                openApprovalRejectDialog(context, id, cubit),
                      actorRole: actorRole,
                      showActions: !readOnly,
                      onViewDetails: (req) =>
                          showApprovalDetailsDialog(context, req),
                    ),
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
          ),
        );
        return LayoutBuilder(
          builder: (context, box) {
            final minimumHeight =
                (box.maxWidth < 600 ? 820.0 : 620.0) *
                MediaQuery.textScalerOf(context).scale(1);
            if (box.maxHeight < minimumHeight) {
              return SingleChildScrollView(
                child: SizedBox(
                  height: minimumHeight,
                  width: box.maxWidth,
                  child: workspace,
                ),
              );
            }
            return workspace;
          },
        );
      },
    );
  }
}
