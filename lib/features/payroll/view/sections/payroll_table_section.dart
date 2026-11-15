import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/payroll_cubit.dart';
import '../cubit/payroll_state.dart';
import '../widgets/payroll_pagination_bar.dart';
import '../widgets/payroll_table.dart';
import 'payroll_table_section_header.dart';
import '../widgets/payroll_list_design.dart';

class PayrollTableSection extends StatelessWidget {
  const PayrollTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PayrollCubit, PayrollState>(
      builder: (context, state) {
        final cubit = context.read<PayrollCubit>();

        return PayrollListDesign(
          header: PayrollTableSectionHeader(cubit: cubit, state: state),
          status: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'سجل مسيرات الرواتب'
                      : 'Payroll history',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF21194E),
                  ),
                ),
                if (!state.loading && state.error == null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1E6FC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${state.total}',
                      style: const TextStyle(
                        color: Color(0xFF8659BB),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          table: AppDataRegion(
            loading: state.loading,
            error: state.error,
            empty: state.items.isEmpty,
            filtered:
                state.status != null ||
                state.startDate != null ||
                state.endDate != null,
            onClear: cubit.resetFilters,
            onRetry: cubit.load,
            child: PayrollTable(
              items: state.items,
              onOpenRun: (id) => context.go('/payroll/$id'),
            ),
          ),
          pagination: PayrollPaginationBar(
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
        );
      },
    );
  }
}
