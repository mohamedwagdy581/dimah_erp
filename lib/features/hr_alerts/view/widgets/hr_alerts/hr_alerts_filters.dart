import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class HrAlertsFilters extends StatelessWidget {
  const HrAlertsFilters({
    super.key,
    required this.typeFilter,
    required this.onChanged,
  });

  final String? typeFilter;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        DropdownButton<String?>(
          value: typeFilter,
          onChanged: onChanged,
          items: [
            DropdownMenuItem(value: null, child: Text(t.allTypes)),
            DropdownMenuItem(value: 'contract', child: Text(t.hrTypeContract)),
            DropdownMenuItem(value: 'residency', child: Text(t.hrTypeResidency)),
            DropdownMenuItem(value: 'insurance', child: Text(t.hrTypeInsurance)),
            DropdownMenuItem(value: 'document', child: Text(t.hrTypeDocument)),
          ],
        ),
      ],
    );
  }
}
