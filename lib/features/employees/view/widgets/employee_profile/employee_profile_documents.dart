import 'package:flutter/material.dart';
import 'package:erp_sys/core/ui/app_data_state.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../employee_docs/view/widgets/employee_docs_table/document_type_utils.dart';
import '../../../domain/models/employee_profile_details.dart';
import '../../utils/employee_profile_utils.dart';
import 'profile_section_card.dart';

class EmployeeProfileDocuments extends StatelessWidget {
  const EmployeeProfileDocuments({
    super.key,
    required this.documents,
    required this.onOpenUrl,
    this.today,
  });
  final List<EmployeeProfileDocument> documents;
  final ValueChanged<String> onOpenUrl;
  final DateTime? today;
  static const purple = Color(0xFF8659BB);
  static const ink = Color(0xFF24204E);
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String a, String e) => ar ? a : e;
    String typeName(String type) =>
        const {
          'id_card',
          'passport',
          'cv',
          'graduation_cert',
          'national_address',
          'bank_iban_certificate',
          'salary_certificate',
          'salary_definition',
          'contract',
          'residency',
          'driving_license',
          'offer_letter',
          'medical_insurance',
          'medical_report',
          'other',
        }.contains(type)
        ? docTypeLabel(t, type)
        : type;
    final now = today ?? DateTime.now();
    int? days(EmployeeProfileDocument d) => d.expiresAt == null
        ? null
        : DateTime.utc(
            d.expiresAt!.year,
            d.expiresAt!.month,
            d.expiresAt!.day,
          ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    final expired = documents
        .where((d) => days(d) != null && days(d)! < 0)
        .length;
    final due = documents
        .where((d) => days(d) != null && days(d)! >= 0 && days(d)! <= 30)
        .length;
    Widget summary(
      String title,
      int value,
      IconData icon,
      Color color,
      double width,
    ) => SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFECE7F5)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: color.withValues(alpha: .1),
              child: Icon(icon, size: 21, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: ink, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    '$value',
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth >= 650
                ? (box.maxWidth - 24) / 3
                : box.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                summary(
                  tr('إجمالي الوثائق', 'Total documents'),
                  documents.length,
                  Icons.folder_copy_outlined,
                  purple,
                  width,
                ),
                summary(
                  tr('تنتهي خلال 30 يومًا', 'Expiring within 30 days'),
                  due,
                  Icons.schedule_outlined,
                  const Color(0xFFBA7900),
                  width,
                ),
                summary(
                  tr('وثائق منتهية', 'Expired documents'),
                  expired,
                  Icons.event_busy_outlined,
                  const Color(0xFFD7193F),
                  width,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        ProfileSectionCard(
          title: tr('وثائق الموظف', 'Employee documents'),
          trailing: const Icon(
            Icons.description_outlined,
            color: purple,
            size: 22,
          ),
          children: [
            if (documents.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: AppEmptyState(title: t.noDocumentsUploaded),
              )
            else
              LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: box.maxWidth),
                    child: DataTable(
                      headingRowHeight: 44,
                      dataRowMinHeight: 62,
                      dataRowMaxHeight: 80,
                      horizontalMargin: 12,
                      columnSpacing: 24,
                      headingRowColor: const WidgetStatePropertyAll(
                        Color(0xFFF3F2F7),
                      ),
                      dividerThickness: .6,
                      columns: [
                        for (final label in [
                          tr('الوثيقة', 'Document'),
                          t.issued,
                          t.expires,
                          t.status,
                          t.actions,
                        ])
                          DataColumn(
                            label: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 13,
                                color: ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                      rows: documents.map((d) {
                        final remaining = days(d);
                        final color = remaining == null
                            ? const Color(0xFF77748B)
                            : remaining < 0
                            ? const Color(0xFFD7193F)
                            : remaining <= 30
                            ? const Color(0xFFBA7900)
                            : const Color(0xFF009B80);
                        final label = remaining == null
                            ? tr('صلاحية غير محددة', 'Expiry not specified')
                            : remaining < 0
                            ? tr('منتهية', 'Expired')
                            : remaining <= 30
                            ? tr('تنتهي قريبًا', 'Expiring soon')
                            : tr('سارية', 'Valid');
                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: purple.withValues(alpha: .08),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Icon(
                                      iconForDocType(d.docType),
                                      color: purple,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 210,
                                    child: Text(
                                      typeName(d.docType),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                formatEmployeeDate(
                                  d.issuedAt,
                                ).replaceAll('-', '/'),
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: ink,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                formatEmployeeDate(
                                  d.expiresAt,
                                ).replaceAll('-', '/'),
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: ink,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              OutlinedButton.icon(
                                key: ValueKey('profile-document-${d.id}'),
                                onPressed: d.fileUrl.trim().isEmpty
                                    ? null
                                    : () => onOpenUrl(d.fileUrl),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: purple,
                                  side: BorderSide(
                                    color: purple.withValues(alpha: .3),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                ),
                                label: Text(t.open),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
