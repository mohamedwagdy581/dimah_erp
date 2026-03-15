import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/leaves_cubit.dart';
import '../cubit/leaves_state.dart';
import '../widgets/leaves_pagination_bar.dart';
import '../widgets/leaves_table.dart';
import 'leaves_balance_cards.dart';
import 'leaves_resubmit_dialog.dart';
import 'leaves_table_section_header.dart';

class LeavesTableSection extends StatelessWidget {
  const LeavesTableSection({super.key, this.employeeId});

  final String? employeeId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeavesCubit, LeavesState>(
      builder: (context, state) {
        final cubit = context.read<LeavesCubit>();
        final t = AppLocalizations.of(context)!;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LeavesTableSectionHeader(
                cubit: cubit,
                state: state,
                employeeId: employeeId,
              ),
              if (state.balances.isNotEmpty) ...[
                const SizedBox(height: 10),
                LeavesBalanceCards(
                  balances: state.balances,
                  t: t,
                ),
              ],
              const SizedBox(height: 12),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: LeavesTable(
                  items: state.items,
                  onResubmit: employeeId == null
                      ? null
                      : (leave) => openLeaveResubmitDialog(context, leave),
                ),
              ),
              const SizedBox(height: 12),
              LeavesPaginationBar(
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
