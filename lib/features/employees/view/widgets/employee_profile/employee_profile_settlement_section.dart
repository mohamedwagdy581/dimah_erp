import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_profile_details.dart';
import '../../utils/employee_profile_utils.dart';
import 'profile_section_card.dart';

class EmployeeProfileSettlementSection extends StatelessWidget {
  const EmployeeProfileSettlementSection({
    super.key,
    required this.profile,
    required this.canEdit,
    required this.onAddSettlement,
  });

  final EmployeeProfileDetails profile;
  final bool canEdit;
  final VoidCallback onAddSettlement;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return ProfileSectionCard(
      title: t.profileSettlements,
      children: [
        if (canEdit)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onAddSettlement,
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text(t.addSettlement),
            ),
          ),
        if (canEdit) const SizedBox(height: 8),
        if (profile.settlements.isEmpty)
          Text(t.noSettlementHistory)
        else
          ...profile.settlements.map((settlement) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${t.settlementDate}: ${formatEmployeeDate(settlement.settlementDate)}'
                ' | ${t.netAmount}: ${settlement.netAmount.toStringAsFixed(2)}',
              ),
              subtitle: Text(
                '${t.finalWorkingDate}: ${formatEmployeeDate(settlement.finalWorkingDate)}'
                ' | ${t.grossAmount}: ${settlement.grossAmount.toStringAsFixed(2)}'
                ' | ${t.deductionsAmount}: ${settlement.deductionsAmount.toStringAsFixed(2)}'
                '${(settlement.notes ?? '').trim().isEmpty ? '' : ' | ${t.notes}: ${settlement.notes}'}',
              ),
            );
          }),
      ],
    );
  }
}
