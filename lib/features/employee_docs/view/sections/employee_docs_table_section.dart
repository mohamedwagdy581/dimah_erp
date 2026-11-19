import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/employee_docs_cubit.dart';
import '../cubit/employee_docs_state.dart';
import '../widgets/employee_docs_pagination_bar.dart';
import '../widgets/employee_docs_table.dart';
import 'employee_docs_table_section_header.dart';

class EmployeeDocsTableSection extends StatelessWidget {
  const EmployeeDocsTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeDocsCubit, EmployeeDocsState>(
      builder: (context, state) {
        final cubit = context.read<EmployeeDocsCubit>();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmployeeDocsTableSectionHeader(cubit: cubit, state: state),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              Expanded(
                child: AppDataRegion(
                  loading: state.loading,
                  error: state.error,
                  onRetry: cubit.load,
                  child: const EmployeeDocsTable(),
                ),
              ),
              const SizedBox(height: 12),
              EmployeeDocsPaginationBar(
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
