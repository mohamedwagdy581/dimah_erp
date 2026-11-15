import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_profile_details.dart';
import '../../utils/employee_profile_utils.dart';
import 'profile_section_card.dart';

class EmployeeProfileContracts extends StatelessWidget {
  const EmployeeProfileContracts({
    super.key,
    required this.profile,
    required this.canEdit,
    required this.onAdd,
    required this.onOpenUrl,
    this.today,
  });
  final EmployeeProfileDetails profile;
  final bool canEdit;
  final VoidCallback onAdd;
  final ValueChanged<String> onOpenUrl;
  final DateTime? today;
  static const accent = Color(0xFF8659BB);
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String a, String e) => ar ? a : e;
    String contractType(String? value) => switch (value) {
      'full_time' => t.contractFullTime,
      'part_time' => t.contractPartTime,
      'contractor' => t.contractContractor,
      'intern' => t.contractIntern,
      _ => value ?? '—',
    };
    final p = profile;
    final now = today ?? DateTime.now();
    final end = p.contractEnd;
    final remaining = end == null
        ? null
        : DateTime.utc(
            end.year,
            end.month,
            end.day,
          ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    final started =
        p.contractStart == null ||
        !DateTime(
          p.contractStart!.year,
          p.contractStart!.month,
          p.contractStart!.day,
        ).isAfter(DateTime(now.year, now.month, now.day));
    final expired = remaining != null && remaining < 0;
    final status = expired
        ? tr('منتهي', 'Expired')
        : !started
        ? tr('لم يبدأ بعد', 'Not started')
        : p.contractType == null
        ? tr('غير مسجل', 'Not recorded')
        : tr('نشط', 'Active');
    String date(DateTime? value) =>
        formatEmployeeDate(value).replaceAll('-', '/');
    String fileName(String? value) {
      if ((value ?? '').trim().isEmpty) return '—';
      final uri = Uri.tryParse(value!);
      return uri != null && uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : tr('ملف العقد', 'Contract file');
    }

    SizedBox field(String label, String value) => SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF66638B)),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
    Widget file(String? url, String title) => Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: accent.withValues(alpha: .16)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: accent),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
          IconButton(
            tooltip: t.open,
            onPressed: (url ?? '').trim().isEmpty
                ? null
                : () => onOpenUrl(url!),
            icon: const Icon(
              Icons.visibility_outlined,
              color: accent,
              size: 20,
            ),
          ),
        ],
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionCard(
          title: tr('العقد الحالي', 'Current contract'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: (expired ? Colors.red : Colors.teal).withValues(
                alpha: .08,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: expired ? Colors.red : Colors.teal,
                fontSize: 12,
              ),
            ),
          ),
          children: [
            LayoutBuilder(
              builder: (context, box) => Wrap(
                spacing: 18,
                runSpacing: 16,
                children: [
                  for (final item in [
                    field(t.type, contractType(p.contractType)),
                    field(t.startDate, date(p.contractStart)),
                    field(t.endDate, date(p.contractEnd)),
                    field(
                      t.probationMonthsLabel,
                      p.probationMonths?.toString() ?? '—',
                    ),
                  ])
                    SizedBox(
                      width: box.maxWidth >= 650
                          ? (box.maxWidth - 54) / 4
                          : box.maxWidth >= 380
                          ? (box.maxWidth - 18) / 2
                          : box.maxWidth,
                      child: item.child,
                    ),
                ],
              ),
            ),
            file(
              p.contractFileUrl,
              (p.contractFileUrl ?? '').trim().isEmpty
                  ? tr('لا يوجد ملف عقد مرفق', 'No contract file attached')
                  : fileName(p.contractFileUrl),
            ),
          ],
        ),
        ProfileSectionCard(
          title: tr('سجل إصدارات العقد', 'Contract version history'),
          children: [
            if (p.contractHistory.isEmpty)
              AppEmptyState(title: t.noContractHistory, compact: false)
            else
              LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: box.maxWidth),
                    child: DataTable(
                      headingRowHeight: 42,
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 72,
                      horizontalMargin: 12,
                      columnSpacing: 20,
                      headingRowColor: const WidgetStatePropertyAll(
                        Color(0xFFF0F1F5),
                      ),
                      columns: [
                        for (final label in [
                          '#',
                          t.type,
                          t.startDate,
                          t.endDate,
                          t.probationMonthsLabel,
                          tr('الملف', 'File'),
                          t.actions,
                        ])
                          DataColumn(
                            label: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                      rows: [
                        for (var i = 0; i < p.contractHistory.length; i++)
                          DataRow(
                            cells: [
                              DataCell(Text('${p.contractHistory.length - i}')),
                              DataCell(
                                Text(
                                  contractType(
                                    p.contractHistory[i].contractType,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(date(p.contractHistory[i].startDate)),
                              ),
                              DataCell(
                                Text(date(p.contractHistory[i].endDate)),
                              ),
                              DataCell(
                                Text(
                                  p.contractHistory[i].probationMonths
                                          ?.toString() ??
                                      '—',
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    fileName(p.contractHistory[i].fileUrl),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  tooltip: t.open,
                                  onPressed:
                                      (p.contractHistory[i].fileUrl ?? '')
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : () => onOpenUrl(
                                          p.contractHistory[i].fileUrl!,
                                        ),
                                  icon: const Icon(
                                    Icons.visibility_outlined,
                                    color: accent,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
    const alertRed = Color(0xFFD7193F);
    const alertText = Color(0xFF4B477D);
    const buttonPurple = Color(0xFF8A35FF);
    final reminder = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        border: Border.all(color: const Color(0xFFF5E4E9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: alertRed, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('تنبيه انتهاء العقد', 'Contract expiry'),
                  style: const TextStyle(
                    color: alertRed,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE3E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  remaining == null
                      ? tr(
                          'لا يوجد تاريخ انتهاء مسجل',
                          'No expiry date recorded',
                        )
                      : expired
                      ? tr('انتهى العقد منذ', 'Contract expired')
                      : tr('ينتهي العقد خلال', 'Contract expires in'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: alertText,
                  ),
                ),
                if (remaining != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    tr('${remaining.abs()} يوم', '${remaining.abs()} days'),
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: alertRed,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.endDate,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, height: 1.5, color: alertText),
          ),
          const SizedBox(height: 3),
          Text(
            date(end),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: alertText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            key: const ValueKey('contract-expiry-open'),
            onPressed: (p.contractFileUrl ?? '').trim().isEmpty
                ? null
                : () => onOpenUrl(p.contractFileUrl!),
            style: OutlinedButton.styleFrom(
              foregroundColor: buttonPurple,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: (p.contractFileUrl ?? '').trim().isEmpty
                    ? const Color(0xFFE8E2F2)
                    : buttonPurple,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              minimumSize: const Size.fromHeight(36),
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: Text(tr('عرض العقد', 'View contract')),
          ),
          if (canEdit) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('contract-expiry-add'),
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                foregroundColor: buttonPurple,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE8E2F2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                minimumSize: const Size.fromHeight(36),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: Text(tr('إضافة نسخة', 'Add version')),
            ),
          ],
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= 850
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: details),
                const SizedBox(width: 16),
                SizedBox(
                  width: (box.maxWidth * .24).clamp(210, 280),
                  child: reminder,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [details, reminder],
            ),
    );
  }
}
