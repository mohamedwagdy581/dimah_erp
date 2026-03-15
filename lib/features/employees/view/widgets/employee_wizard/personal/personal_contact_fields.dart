import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../cubit/employee_wizard_cubit.dart';
import '../../../cubit/employee_wizard_state.dart';

class PersonalContactFields extends StatelessWidget {
  const PersonalContactFields({
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

    final emailField = TextFormField(
      initialValue: state.email,
      onChanged: cubit.setEmail,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: t.email,
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        final x = (v ?? '').trim();
        if (x.isEmpty) return t.emailRequired;
        if (!x.contains('@') || !x.contains('.')) return t.enterValidEmail;
        return null;
      },
    );

    final phoneField = TextFormField(
      initialValue: state.phone,
      onChanged: cubit.setPhone,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: t.phone,
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        final x = (v ?? '').trim();
        if (x.isEmpty) return t.phoneRequired;
        if (x.length < 8) return t.phoneTooShort;
        return null;
      },
    );

    if (isSmall) {
      return Column(
        children: [emailField, const SizedBox(height: 12), phoneField],
      );
    }

    return Row(
      children: [
        Expanded(child: emailField),
        const SizedBox(width: 12),
        Expanded(child: phoneField),
      ],
    );
  }
}
