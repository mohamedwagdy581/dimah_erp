import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_profile_details.dart';
import '../../utils/employee_profile_utils.dart';
import 'profile_kv_row.dart';
import 'profile_section_card.dart';

class EmployeeProfileFinancialSections extends StatelessWidget {
  const EmployeeProfileFinancialSections({
    super.key,
    required this.profile,
    required this.canEdit,
    required this.onAddCompensationVersion,
  });

  final EmployeeProfileDetails profile;
  final bool canEdit;
  final VoidCallback onAddCompensationVersion;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = profile;

    return Column(
      children: [
        ProfileSectionCard(
          title: t.stepCompensation,
          children: [
            if (canEdit)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onAddCompensationVersion,
                  icon: const Icon(Icons.request_quote_outlined),
                  label: Text(t.addCompensationVersion),
                ),
              ),
            const SizedBox(height: 8),
            ProfileKvRow(label: t.basicSalary, value: formatEmployeeMoney(p.basicSalary)),
            ProfileKvRow(label: t.housingAllowance, value: formatEmployeeMoney(p.housingAllowance)),
            ProfileKvRow(label: t.transportAllowance, value: formatEmployeeMoney(p.transportAllowance)),
            ProfileKvRow(label: t.otherAllowance, value: formatEmployeeMoney(p.otherAllowance)),
            ProfileKvRow(label: t.totalCompensation, value: formatEmployeeMoney(totalEmployeeCompensation(p))),
            const SizedBox(height: 10),
            Text(t.compensationHistory, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (p.compensationHistory.isEmpty)
              Text(t.noCompensationHistory)
            else
              ...p.compensationHistory.map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${t.effectiveDate}: ${formatEmployeeDate(item.effectiveAt)} | ${t.total}: ${item.total.toStringAsFixed(2)}',
                  ),
                  subtitle: Text(
                    '${t.basic} ${item.basicSalary.toStringAsFixed(2)} | '
                    '${t.housing} ${item.housingAllowance.toStringAsFixed(2)} | '
                    '${t.transport} ${item.transportAllowance.toStringAsFixed(2)} | '
                    '${t.other} ${item.otherAllowance.toStringAsFixed(2)}'
                    '${(item.note ?? '').trim().isEmpty ? '' : ' | ${t.notes}: ${item.note}'}',
                  ),
                ),
              ),
          ],
        ),
        ProfileSectionCard(
          title: t.financial,
          children: [
            ProfileKvRow(label: t.paymentMethod, value: p.paymentMethod),
            ProfileKvRow(label: t.bankName, value: p.bankName),
            ProfileKvRow(label: t.iban, value: p.iban),
            ProfileKvRow(label: t.accountNumber, value: p.accountNumber),
          ],
        ),
      ],
    );
  }
}
