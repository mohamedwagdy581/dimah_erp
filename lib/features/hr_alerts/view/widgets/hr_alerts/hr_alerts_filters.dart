import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class HrAlertsFilters extends StatelessWidget {
  const HrAlertsFilters({
    super.key,
    required this.typeFilter,
    required this.statusFilter,
    required this.allCount,
    required this.activeCount,
    required this.snoozedCount,
    required this.handledCount,
    required this.onTypeChanged,
    required this.onStatusChanged,
  });

  final String? typeFilter;
  final String statusFilter;
  final int allCount;
  final int activeCount;
  final int snoozedCount;
  final int handledCount;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        DropdownButton<String?>(
          value: typeFilter,
          onChanged: onTypeChanged,
          items: [
            DropdownMenuItem(value: null, child: Text(t.allTypes)),
            DropdownMenuItem(value: 'contract', child: Text(t.hrTypeContract)),
            DropdownMenuItem(value: 'residency', child: Text(t.hrTypeResidency)),
            DropdownMenuItem(value: 'insurance', child: Text(t.hrTypeInsurance)),
            DropdownMenuItem(value: 'document', child: Text(t.hrTypeDocument)),
          ],
        ),
        DropdownButton<String>(
          value: statusFilter,
          onChanged: (value) {
            if (value != null) onStatusChanged(value);
          },
          items: [
            DropdownMenuItem(
              value: 'all',
              child: Text(_statusLabel(context, 'all', allCount)),
            ),
            DropdownMenuItem(
              value: 'active',
              child: Text(_statusLabel(context, 'active', activeCount)),
            ),
            DropdownMenuItem(
              value: 'snoozed',
              child: Text(_statusLabel(context, 'snoozed', snoozedCount)),
            ),
            DropdownMenuItem(
              value: 'handled',
              child: Text(_statusLabel(context, 'handled', handledCount)),
            ),
          ],
        ),
      ],
    );
  }

  String _statusLabel(BuildContext context, String value, int count) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final label = switch (value) {
      'all' => isArabic ? 'كل الحالات' : 'All Statuses',
      'active' => isArabic ? 'النشطة' : 'Active',
      'snoozed' => isArabic ? 'المؤجلة' : 'Snoozed',
      'handled' => isArabic ? 'تم التعامل معها' : 'Handled',
      _ => value,
    };
    return '$label ($count)';
  }
}
