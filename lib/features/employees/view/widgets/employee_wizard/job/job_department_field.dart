import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../../../departments/view/cubit/departments_cubit.dart';
import '../../../../../departments/view/cubit/departments_state.dart';
import '../../../../../job_titles/presentation/cubit/job_titles_cubit.dart';
import '../../../cubit/employee_wizard_cubit.dart';

class JobDepartmentField extends StatelessWidget {
  const JobDepartmentField({super.key, required this.selectedDepartmentId});

  final String? selectedDepartmentId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return BlocBuilder<DepartmentsCubit, DepartmentsState>(
      builder: (context, state) {
        return DropdownButtonFormField<String>(
          initialValue: selectedDepartmentId,
          decoration: InputDecoration(
            labelText: t.department,
            border: const OutlineInputBorder(),
          ),
          items: state.items
              .where((d) => d.isActive)
              .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
              .toList(),
          onChanged: state.loading
              ? null
              : (id) {
                  if (id == null) return;
                  context.read<EmployeeWizardCubit>().setDepartmentId(id);
                  context.read<EmployeeWizardCubit>().setJobTitleId(null);
                  context.read<JobTitlesCubit>().loadForDepartment(id);
                },
          validator: (v) {
            if (v == null || v.trim().isEmpty) return t.departmentRequired;
            return null;
          },
        );
      },
    );
  }
}
