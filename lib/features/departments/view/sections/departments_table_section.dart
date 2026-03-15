import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/departments_cubit.dart';
import '../cubit/departments_state.dart';
import '../widgets/department_table.dart';
import 'departments_dialog_actions.dart';
import 'departments_table_section_header.dart';

class DepartmentsTableSection extends StatelessWidget {
  const DepartmentsTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return BlocBuilder<DepartmentsCubit, DepartmentsState>(
      builder: (context, state) {
        final cubit = context.read<DepartmentsCubit>();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DepartmentsTableSectionHeader(cubit: cubit, state: state),
              const SizedBox(height: 12),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              Expanded(
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
            ],
          ),
        );
      },
    );
  }
}
