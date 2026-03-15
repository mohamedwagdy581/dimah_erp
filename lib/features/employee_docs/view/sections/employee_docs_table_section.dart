import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/employee_docs_cubit.dart';
import '../cubit/employee_docs_state.dart';
import '../widgets/employee_docs_pagination_bar.dart';
import '../widgets/employee_docs_table.dart';
import 'employee_docs_table_section_header.dart';

class EmployeeDocsTableSection extends StatelessWidget {
  const EmployeeDocsTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              const Expanded(child: EmployeeDocsTable()),
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
