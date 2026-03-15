import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../cubit/employee_wizard_cubit.dart';

class JobHireDateField extends StatelessWidget {
  const JobHireDateField({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final hireDate = context.watch<EmployeeWizardCubit>().state.hireDate;
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
        if (context.read<EmployeeWizardCubit>().state.hireDate == null) {
          return t.hireDateRequired;
        }
        return null;
      },
    );
  }
}
