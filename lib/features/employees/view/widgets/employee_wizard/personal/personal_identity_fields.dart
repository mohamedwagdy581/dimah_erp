import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../cubit/employee_wizard_cubit.dart';
import '../../../cubit/employee_wizard_state.dart';
import 'personal_date_fields.dart';

class PersonalIdentityFields extends StatelessWidget {
  const PersonalIdentityFields({
    super.key,
    required this.state,
    required this.cubit,
    required this.isSmall,
  });

  final EmployeeWizardState state;
  final EmployeeWizardCubit cubit;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final genderField = DropdownButtonFormField<String>(
      initialValue: state.gender,
      decoration: InputDecoration(
        labelText: t.gender,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(value: 'male', child: Text(t.male)),
        DropdownMenuItem(value: 'female', child: Text(t.female)),
      ],
      onChanged: cubit.setGender,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return t.genderRequired;
        return null;
      },
    );

    final dobField = DobFormField(
      value: state.dateOfBirth,
      onPick: cubit.setDateOfBirth,
    );

    if (isSmall) {
      return Column(
        children: [genderField, const SizedBox(height: 12), dobField],
      );
    }

    return Row(
      children: [
        Expanded(child: genderField),
        const SizedBox(width: 12),
        Expanded(child: dobField),
      ],
    );
  }
}
