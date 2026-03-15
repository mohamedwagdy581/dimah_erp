import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../cubit/employee_wizard_cubit.dart';
import '../../../cubit/employee_wizard_state.dart';

class JobContractFields extends StatelessWidget {
  const JobContractFields({super.key, required this.state});

  final EmployeeWizardState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cubit = context.read<EmployeeWizardCubit>();
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: state.contractType,
          decoration: InputDecoration(
            labelText: t.contractType,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: 'full_time',
              child: Text(t.contractFullTime),
            ),
            DropdownMenuItem(
              value: 'part_time',
              child: Text(t.contractPartTime),
            ),
            DropdownMenuItem(
              value: 'contractor',
              child: Text(t.contractContractor),
            ),
            DropdownMenuItem(value: 'intern', child: Text(t.contractIntern)),
          ],
          onChanged: (v) => cubit.setContractType(v ?? 'full_time'),
        ),
        const SizedBox(height: 12),
        ContractDateField(
          label: t.contractStart,
          value: state.contractStart ?? state.hireDate,
          onPick: cubit.setContractStart,
        ),
        const SizedBox(height: 12),
        ContractDateField(
          label: t.contractEnd,
          value: state.contractEnd,
          onPick: cubit.setContractEnd,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: state.probationMonths?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: t.probationMonths,
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) => cubit.setProbationMonths(int.tryParse(v)),
        ),
      ],
    );
  }
}

class ContractDateField extends FormField<DateTime> {
  ContractDateField({
    super.key,
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
