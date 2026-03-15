import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../cubit/employee_wizard_cubit.dart';
import 'compensation_number_field.dart';

class CompensationSalaryFields extends StatelessWidget {
  const CompensationSalaryFields({
    super.key,
    required this.basic,
    required this.housing,
    required this.transport,
    required this.other,
    required this.cubit,
    required this.parse,
  });

  final TextEditingController basic;
  final TextEditingController housing;
  final TextEditingController transport;
  final TextEditingController other;
  final EmployeeWizardCubit cubit;
  final double Function(String) parse;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        CompensationNumberField(
          controller: basic,
          label: t.basicSalaryRequired,
          onChanged: (v) => cubit.setBasicSalary(parse(v)),
          validator: (v) {
            final value = parse(v ?? '');
            if (value <= 0) return t.basicSalaryValidationRequired;
            return null;
          },
        ),
        const SizedBox(height: 12),
        CompensationNumberField(
          controller: housing,
          label: t.housingAllowance,
          onChanged: (v) => cubit.setHousingAllowance(parse(v)),
        ),
        const SizedBox(height: 12),
        CompensationNumberField(
          controller: transport,
          label: t.transportAllowance,
          onChanged: (v) => cubit.setTransportAllowance(parse(v)),
        ),
        const SizedBox(height: 12),
        CompensationNumberField(
          controller: other,
          label: t.otherAllowance,
          onChanged: (v) => cubit.setOtherAllowance(parse(v)),
        ),
      ],
    );
  }
}
