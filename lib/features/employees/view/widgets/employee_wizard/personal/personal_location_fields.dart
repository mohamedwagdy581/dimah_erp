import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../cubit/employee_wizard_cubit.dart';
import '../../../cubit/employee_wizard_state.dart';

class PersonalLocationFields extends StatelessWidget {
  const PersonalLocationFields({
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
    final cityField = TextFormField(
      initialValue: state.city,
      onChanged: cubit.setCity,
      decoration: InputDecoration(
        labelText: t.city,
        border: const OutlineInputBorder(),
      ),
    );
    final countryField = TextFormField(
      initialValue: state.country,
      onChanged: cubit.setCountry,
      decoration: InputDecoration(
        labelText: t.country,
        border: const OutlineInputBorder(),
      ),
    );

    if (isSmall) {
      return Column(
        children: [cityField, const SizedBox(height: 12), countryField],
      );
    }

    return Row(
      children: [
        Expanded(child: cityField),
        const SizedBox(width: 12),
        Expanded(child: countryField),
      ],
    );
  }
}
