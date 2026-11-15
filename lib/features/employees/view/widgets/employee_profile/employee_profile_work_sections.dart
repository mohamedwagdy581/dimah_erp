import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_profile_details.dart';
import '../../utils/employee_profile_utils.dart';
import 'employee_profile_leave_section.dart';
import 'employee_profile_settlement_section.dart';
import 'profile_kv_row.dart';
import 'profile_section_card.dart';
import 'employee_profile_documents.dart';

class EmployeeProfileWorkSections extends StatelessWidget {
  const EmployeeProfileWorkSections({
    super.key,
    required this.profile,
    required this.canEdit,
    required this.onAddContractVersion,
    required this.onAddSettlement,
    required this.onOpenUrl,
    this.section,
  });

  final EmployeeProfileDetails profile;
  final bool canEdit;
  final VoidCallback onAddContractVersion;
  final VoidCallback onAddSettlement;
  final ValueChanged<String> onOpenUrl;
  final int? section;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = profile;

    return Column(
      children: [
        if (section == null)
          ProfileSectionCard(
            title: t.contract,
            children: [
              if (canEdit)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onAddContractVersion,
                    icon: const Icon(Icons.add_card_outlined),
                    label: Text(t.addContractVersion),
                  ),
                ),
              const SizedBox(height: 8),
              ProfileKvRow(label: t.type, value: p.contractType),
              ProfileKvRow(
                label: t.startDate,
                value: formatEmployeeDate(p.contractStart),
              ),
              ProfileKvRow(
                label: t.endDate,
                value: formatEmployeeDate(p.contractEnd),
              ),
              ProfileKvRow(
                label: t.probationMonthsLabel,
                value: p.probationMonths == null ? '-' : '${p.probationMonths}',
              ),
              if ((p.contractFileUrl ?? '').trim().isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => onOpenUrl(p.contractFileUrl!),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(t.openContractFile),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                t.contractHistory,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              if (p.contractHistory.isEmpty)
                AppEmptyState(title: t.noContractHistory, compact: false)
              else
                ...p.contractHistory.map(
                  (item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${item.contractType} | ${formatEmployeeDate(item.startDate)} -> ${formatEmployeeDate(item.endDate)}',
                    ),
                    subtitle: Text(
                      '${t.probationMonths}: ${item.probationMonths?.toString() ?? '-'}',
                    ),
                    trailing: (item.fileUrl ?? '').trim().isEmpty
                        ? null
                        : TextButton(
                            onPressed: () => onOpenUrl(item.fileUrl!),
                            child: Text(t.open),
                          ),
                  ),
                ),
            ],
          ),
        if (section == null || section == 5)
          EmployeeProfileLeaveSection(profile: p),
        if (section == null || section == 6)
          EmployeeProfileSettlementSection(
            profile: p,
            canEdit: canEdit,
            onAddSettlement: onAddSettlement,
          ),
        if (section == null || section == 4)
          EmployeeProfileDocuments(
            documents: p.documents,
            onOpenUrl: onOpenUrl,
          ),
      ],
    );
  }
}
