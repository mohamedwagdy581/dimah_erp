import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../utils/employee_profile_utils.dart';
import 'employee_profile_edit_inputs.dart';

class EmployeeProfileEducationInsuranceSection extends StatelessWidget {
  const EmployeeProfileEducationInsuranceSection({
    super.key,
    required this.insuranceProvider,
    required this.insurancePolicyNo,
    required this.educationLevel,
    required this.major,
    required this.university,
    required this.insuranceStartDate,
    required this.insuranceExpiryDate,
    required this.onPickInsuranceStartDate,
    required this.onPickInsuranceExpiryDate,
  });

  final TextEditingController insuranceProvider;
  final TextEditingController insurancePolicyNo;
  final TextEditingController educationLevel;
  final TextEditingController major;
  final TextEditingController university;
  final DateTime? insuranceStartDate;
  final DateTime? insuranceExpiryDate;
  final VoidCallback onPickInsuranceStartDate;
  final VoidCallback onPickInsuranceExpiryDate;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: EmployeeProfileDateButton(
                label: insuranceStartDate == null ? t.insuranceStart : formatEmployeeDate(insuranceStartDate),
                icon: Icons.health_and_safety_outlined,
                onPressed: onPickInsuranceStartDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: EmployeeProfileDateButton(
                label: insuranceExpiryDate == null ? t.insuranceExpiry : formatEmployeeDate(insuranceExpiryDate),
                icon: Icons.health_and_safety,
                onPressed: onPickInsuranceExpiryDate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: EmployeeProfileEditField(controller: insuranceProvider, label: t.insuranceProvider)),
            const SizedBox(width: 10),
            Expanded(child: EmployeeProfileEditField(controller: insurancePolicyNo, label: t.insurancePolicyNo)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: EmployeeProfileEditField(controller: educationLevel, label: t.educationLevel)),
            const SizedBox(width: 10),
            Expanded(child: EmployeeProfileEditField(controller: major, label: t.major)),
          ],
        ),
        const SizedBox(height: 10),
        EmployeeProfileEditField(controller: university, label: t.university),
      ],
    );
  }
}
