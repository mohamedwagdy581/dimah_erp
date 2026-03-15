import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/payroll_cubit.dart';
import '../cubit/payroll_state.dart';
import '../widgets/payroll_pagination_bar.dart';
import '../widgets/payroll_table.dart';
import 'payroll_table_section_header.dart';

class PayrollTableSection extends StatelessWidget {
  const PayrollTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PayrollCubit, PayrollState>(
      builder: (context, state) {
        final cubit = context.read<PayrollCubit>();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PayrollTableSectionHeader(cubit: cubit, state: state),
              const SizedBox(height: 12),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: PayrollTable(
                  items: state.items,
                  onOpenRun: (id) => context.go('/payroll/$id'),
                ),
              ),
              const SizedBox(height: 12),
              PayrollPaginationBar(
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
