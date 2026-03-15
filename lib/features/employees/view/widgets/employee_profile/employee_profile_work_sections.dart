import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_profile_details.dart';
import '../../utils/employee_profile_utils.dart';
import 'profile_kv_row.dart';
import 'profile_section_card.dart';

class EmployeeProfileWorkSections extends StatelessWidget {
  const EmployeeProfileWorkSections({
    super.key,
    required this.profile,
    required this.canEdit,
    required this.onAddContractVersion,
    required this.onOpenUrl,
  });

  final EmployeeProfileDetails profile;
  final bool canEdit;
  final VoidCallback onAddContractVersion;
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = profile;

    return Column(
      children: [
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
            ProfileKvRow(label: t.startDate, value: formatEmployeeDate(p.contractStart)),
            ProfileKvRow(label: t.endDate, value: formatEmployeeDate(p.contractEnd)),
            ProfileKvRow(label: t.probationMonthsLabel, value: p.probationMonths == null ? '-' : '${p.probationMonths}'),
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
            Text(t.contractHistory, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (p.contractHistory.isEmpty)
              Text(t.noContractHistory)
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
        ProfileSectionCard(
          title: t.documents,
          children: [
            if (p.documents.isEmpty)
              Text(t.noDocumentsUploaded)
            else
              ...p.documents.map(
                (document) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(document.docType),
                  subtitle: Text(
                    '${t.issued}: ${formatEmployeeDate(document.issuedAt)} | ${t.expires}: ${formatEmployeeDate(document.expiresAt)}',
                  ),
                  trailing: TextButton(
                    onPressed: document.fileUrl.trim().isEmpty
                        ? null
                        : () => onOpenUrl(document.fileUrl),
                    child: Text(t.open),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
