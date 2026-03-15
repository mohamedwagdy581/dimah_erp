import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../utils/employee_profile_utils.dart';
import 'employee_profile_edit_inputs.dart';

class EmployeeProfileFinancialContractSection extends StatelessWidget {
  const EmployeeProfileFinancialContractSection({
    super.key,
    required this.bankName,
    required this.iban,
    required this.accountNumber,
    required this.contractType,
    required this.probationMonths,
    required this.contractFileUrl,
    required this.contractStart,
    required this.contractEnd,
    required this.onPickContractStart,
    required this.onPickContractEnd,
  });

  final TextEditingController bankName;
  final TextEditingController iban;
  final TextEditingController accountNumber;
  final TextEditingController contractType;
  final TextEditingController probationMonths;
  final TextEditingController contractFileUrl;
  final DateTime? contractStart;
  final DateTime? contractEnd;
  final VoidCallback onPickContractStart;
  final VoidCallback onPickContractEnd;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: EmployeeProfileEditField(controller: bankName, label: t.bankName)),
            const SizedBox(width: 10),
            Expanded(child: EmployeeProfileEditField(controller: iban, label: t.iban)),
          ],
        ),
        const SizedBox(height: 10),
        EmployeeProfileEditField(controller: accountNumber, label: t.accountNumber),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: EmployeeProfileEditField(controller: contractType, label: t.contractType)),
            const SizedBox(width: 10),
            Expanded(
              child: EmployeeProfileEditField(
                controller: probationMonths,
                label: t.probationMonths,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: EmployeeProfileDateButton(
                label: contractStart == null ? t.contractStart : formatEmployeeDate(contractStart),
                icon: Icons.event_note,
                onPressed: onPickContractStart,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: EmployeeProfileDateButton(
                label: contractEnd == null ? t.contractEnd : formatEmployeeDate(contractEnd),
                icon: Icons.event_busy,
                onPressed: onPickContractEnd,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        EmployeeProfileEditField(controller: contractFileUrl, label: t.contractFileUrl),
      ],
    );
  }
}
