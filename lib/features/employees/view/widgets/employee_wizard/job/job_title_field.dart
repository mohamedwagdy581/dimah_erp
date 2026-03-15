import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../../../job_titles/presentation/cubit/job_titles_cubit.dart';
import '../../../../../job_titles/presentation/cubit/job_titles_state.dart';
import '../../../cubit/employee_wizard_cubit.dart';

class JobTitleField extends StatelessWidget {
  const JobTitleField({
    super.key,
    required this.selectedDepartmentId,
    required this.selectedJobTitleId,
  });

  final String? selectedDepartmentId;
  final String? selectedJobTitleId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return BlocBuilder<JobTitlesCubit, JobTitlesState>(
      builder: (context, state) {
        final isDeptSelected = selectedDepartmentId != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedJobTitleId,
              decoration: InputDecoration(
                labelText: t.menuJobTitles,
                border: const OutlineInputBorder(),
              ),
              items: state.items
                  .where((jt) => jt.isActive)
                  .map(
                    (jt) =>
                        DropdownMenuItem(value: jt.id, child: Text(jt.name)),
                  )
                  .toList(),
              onChanged:
                  (!isDeptSelected || state.loading || state.items.isEmpty)
                  ? null
                  : (id) =>
                        context.read<EmployeeWizardCubit>().setJobTitleId(id),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return t.jobTitleRequired;
                return null;
              },
            ),
            if (!isDeptSelected) ...[
              const SizedBox(height: 8),
              Text(
                t.selectDepartmentFirst,
                style: const TextStyle(fontSize: 12),
              ),
            ] else if (state.loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ] else if (state.error != null) ...[
              const SizedBox(height: 8),
              Text(state.error!, style: const TextStyle(color: Colors.red)),
            ] else if (state.items.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                t.noJobTitlesForDepartment,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }
}
