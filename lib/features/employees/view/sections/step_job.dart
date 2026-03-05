import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/di/app_di.dart';
import '../../domain/models/employee_lookup.dart';
import '../../../departments/view/cubit/departments_cubit.dart';
import '../../../departments/view/cubit/departments_state.dart';
import '../../../job_titles/presentation/cubit/job_titles_cubit.dart';
import '../../../job_titles/presentation/cubit/job_titles_state.dart';
import '../cubit/employee_wizard_cubit.dart';

class StepJob extends StatelessWidget {
  const StepJob({super.key});

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
      child: const _StepJobBody(),
    );
  }
}

class _StepJobBody extends StatelessWidget {
  const _StepJobBody();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final wizard = context.watch<EmployeeWizardCubit>();
    final selectedDepartmentId = wizard.state.departmentId;
    final selectedManagerId = wizard.state.managerId;
    final selectedJobTitleId = wizard.state.jobTitleId;

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

          // =========================
          // Department Dropdown
          // =========================
          BlocBuilder<DepartmentsCubit, DepartmentsState>(
            builder: (context, state) {
              return DropdownButtonFormField<String>(
                initialValue: selectedDepartmentId,
                decoration: InputDecoration(
                  labelText: t.department,
                  border: const OutlineInputBorder(),
                ),
                items: state.items
                    .where((d) => d.isActive)
                    .map(
                      (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                    )
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
                  if (v == null || v.trim().isEmpty) {
                    return t.departmentRequired;
                  }
                  return null;
                },
              );
            },
          ),

          const SizedBox(height: 16),
          FutureBuilder<List<EmployeeLookup>>(
            future: AppDI.employeesRepo.fetchEmployeeLookup(limit: 200),
            builder: (context, snap) {
              final managers = snap.data ?? const <EmployeeLookup>[];
              return DropdownButtonFormField<String>(
                initialValue: selectedManagerId,
                decoration: InputDecoration(
                  labelText: t.directManagerOptional,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: '',
                    child: Text(t.noDirectManager),
                  ),
                  ...managers.map(
                    (m) =>
                        DropdownMenuItem(value: m.id, child: Text(m.fullName)),
                  ),
                ],
                onChanged: (v) => context.read<EmployeeWizardCubit>().setManagerId(
                  (v == null || v.isEmpty) ? null : v,
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // =========================
          // Job Title Dropdown
          // =========================
          BlocBuilder<JobTitlesCubit, JobTitlesState>(
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
                          (jt) => DropdownMenuItem(
                            value: jt.id,
                            child: Text(jt.name),
                          ),
                        )
                        .toList(),
                    onChanged:
                        (!isDeptSelected ||
                            state.loading ||
                            state.items.isEmpty)
                        ? null
                        : (id) {
                            context.read<EmployeeWizardCubit>().setJobTitleId(
                              id,
                            );
                          },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return t.jobTitleRequired;
                      }
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
                    Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
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
          ),
          const SizedBox(height: 12),

          Builder(
            builder: (context) {
              final hireDate = context
                  .watch<EmployeeWizardCubit>()
                  .state
                  .hireDate;

              return TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: t.hireDate,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                ),
                controller: TextEditingController(
                  text: hireDate == null
                      ? ''
                      : "${hireDate.year.toString().padLeft(4, '0')}-"
                            "${hireDate.month.toString().padLeft(2, '0')}-"
                            "${hireDate.day.toString().padLeft(2, '0')}",
                ),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: hireDate ?? now,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(now.year + 2),
                  );

                  if (picked != null && context.mounted) {
                    context.read<EmployeeWizardCubit>().setHireDate(picked);
                  }
                },
                validator: (_) {
                  if (context.read<EmployeeWizardCubit>().state.hireDate ==
                      null) {
                    return t.hireDateRequired;
                  }
                  return null;
                },
              );
            },
          ),

          const SizedBox(height: 16),

          // Contract info
          DropdownButtonFormField<String>(
            initialValue: wizard.state.contractType,
            decoration: InputDecoration(
              labelText: t.contractType,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'full_time', child: Text(t.contractFullTime)),
              DropdownMenuItem(value: 'part_time', child: Text(t.contractPartTime)),
              DropdownMenuItem(value: 'contractor', child: Text(t.contractContractor)),
              DropdownMenuItem(value: 'intern', child: Text(t.contractIntern)),
            ],
            onChanged: (v) => context
                .read<EmployeeWizardCubit>()
                .setContractType(v ?? 'full_time'),
          ),
          const SizedBox(height: 12),
          _ContractDateField(
            label: t.contractStart,
            value: wizard.state.contractStart ?? wizard.state.hireDate,
            onPick: context.read<EmployeeWizardCubit>().setContractStart,
          ),
          const SizedBox(height: 12),
          _ContractDateField(
            label: t.contractEnd,
            value: wizard.state.contractEnd,
            onPick: context.read<EmployeeWizardCubit>().setContractEnd,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: wizard.state.probationMonths?.toString() ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: t.probationMonths,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => context
                .read<EmployeeWizardCubit>()
                .setProbationMonths(int.tryParse(v)),
          ),
        ],
      ),
    );
  }
}

class _ContractDateField extends FormField<DateTime> {
  _ContractDateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onPick,
  }) : super(
         initialValue: value,
         builder: (field) {
           final t = AppLocalizations.of(field.context)!;
           final v = field.value;
           final text = v == null
               ? t.selectDate
               : '${v.year.toString().padLeft(4, '0')}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';

           return InkWell(
             onTap: () async {
               final now = DateTime.now();
               final picked = await showDatePicker(
                 context: field.context,
                 initialDate: v ?? now,
                 firstDate: DateTime(now.year - 10, 1, 1),
                 lastDate: DateTime(now.year + 10, 12, 31),
               );
               field.didChange(picked);
               onPick(picked);
             },
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: label,
                 border: const OutlineInputBorder(),
                 suffixIcon: const Icon(Icons.calendar_today_outlined),
               ),
               child: Text(text),
             ),
           );
         },
       );
}
