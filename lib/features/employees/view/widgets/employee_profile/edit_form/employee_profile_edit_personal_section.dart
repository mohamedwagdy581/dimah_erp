import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../utils/employee_profile_utils.dart';
import 'employee_profile_edit_inputs.dart';

class EmployeeProfilePersonalSection extends StatelessWidget {
  const EmployeeProfilePersonalSection({
    super.key,
    required this.nationality,
    required this.maritalStatus,
    required this.address,
    required this.city,
    required this.country,
    required this.passportNo,
    required this.passportExpiry,
    required this.residencyIssueDate,
    required this.residencyExpiryDate,
    required this.onPickPassportExpiry,
    required this.onPickResidencyIssueDate,
    required this.onPickResidencyExpiryDate,
  });

  final TextEditingController nationality;
  final TextEditingController maritalStatus;
  final TextEditingController address;
  final TextEditingController city;
  final TextEditingController country;
  final TextEditingController passportNo;
  final DateTime? passportExpiry;
  final DateTime? residencyIssueDate;
  final DateTime? residencyExpiryDate;
  final VoidCallback onPickPassportExpiry;
  final VoidCallback onPickResidencyIssueDate;
  final VoidCallback onPickResidencyExpiryDate;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        EmployeeProfileEditField(controller: nationality, label: t.nationality),
        const SizedBox(height: 10),
        EmployeeProfileEditField(controller: maritalStatus, label: t.maritalStatus),
        const SizedBox(height: 10),
        EmployeeProfileEditField(controller: address, label: t.address),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: EmployeeProfileEditField(controller: city, label: t.city)),
            const SizedBox(width: 10),
            Expanded(child: EmployeeProfileEditField(controller: country, label: t.country)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: EmployeeProfileEditField(controller: passportNo, label: t.passportNo)),
            const SizedBox(width: 10),
            Expanded(
              child: EmployeeProfileDateButton(
                label: passportExpiry == null ? t.passportExpiry : formatEmployeeDate(passportExpiry),
                icon: Icons.event,
                onPressed: onPickPassportExpiry,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: EmployeeProfileDateButton(
                label: residencyIssueDate == null ? t.residencyIssue : formatEmployeeDate(residencyIssueDate),
                icon: Icons.badge_outlined,
                onPressed: onPickResidencyIssueDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: EmployeeProfileDateButton(
                label: residencyExpiryDate == null ? t.residencyExpiry : formatEmployeeDate(residencyExpiryDate),
                icon: Icons.badge,
                onPressed: onPickResidencyExpiryDate,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
