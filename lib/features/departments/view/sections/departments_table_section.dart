import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/departments_cubit.dart';
import '../cubit/departments_state.dart';
import '../widgets/department_table.dart';
import 'departments_dialog_actions.dart';
import 'departments_table_section_header.dart';

class DepartmentsTableSection extends StatelessWidget {
  const DepartmentsTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DepartmentsCubit, DepartmentsState>(
      builder: (context, state) {
        final cubit = context.read<DepartmentsCubit>();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DepartmentsTableSectionHeader(cubit: cubit, state: state),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              Expanded(
                child: AppDataRegion(
                  loading: state.loading,
                  error: state.error,
                  empty: state.items.isEmpty,
                  filtered:
                      state.search.trim().isNotEmpty || state.isActive != null,
                  onClear: cubit.resetFilters,
                  onRetry: cubit.load,
                  child: DepartmentTable(
                    items: state.items,
                    onEdit: (d) => openDepartmentEditDialog(context, d),
                    onToggleActive: (d) {
                      cubit.update(
                        id: d.id,
                        name: d.name,
                        code: d.code,
                        description: d.description,
                        isActive: !d.isActive,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
