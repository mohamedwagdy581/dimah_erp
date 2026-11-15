import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../departments/view/cubit/departments_cubit.dart';
import '../../../job_titles/presentation/cubit/job_titles_cubit.dart';
import '../cubit/employee_wizard_cubit.dart';
import '../widgets/employee_wizard/job/job_contract_fields.dart';
import '../widgets/employee_wizard/job/job_department_field.dart';
import '../widgets/employee_wizard/job/job_hire_date_field.dart';
import '../widgets/employee_wizard/job/job_manager_field.dart';
import '../widgets/employee_wizard/job/job_title_field.dart';
import '../widgets/employee_wizard/wizard_layout.dart';

class StepJob extends StatelessWidget {
  const StepJob({super.key, this.includeContract = true});
  final bool includeContract;

  static final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DepartmentsCubit(AppDI.departmentsRepo)..load(),
        ),
        BlocProvider(create: (_) => JobTitlesCubit(AppDI.jobTitlesRepo)),
      ],
      child: _StepJobBody(includeContract: includeContract),
    );
  }
}

class _StepJobBody extends StatelessWidget {
  const _StepJobBody({required this.includeContract});
  final bool includeContract;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final wizard = context.watch<EmployeeWizardCubit>();
    final state = wizard.state;

    return Form(
      key: StepJob.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.stepJobInfo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          WizardFieldsGrid(
            children: [
              JobDepartmentField(selectedDepartmentId: state.departmentId),
              JobTitleField(
                key: ValueKey(state.departmentId),
                selectedDepartmentId: state.departmentId,
                selectedJobTitleId: state.jobTitleId,
              ),
              JobManagerField(selectedManagerId: state.managerId),
              const JobHireDateField(),
            ],
          ),
          const SizedBox(height: 16),
          if (includeContract) JobContractFields(state: state),
        ],
      ),
    );
  }
}
