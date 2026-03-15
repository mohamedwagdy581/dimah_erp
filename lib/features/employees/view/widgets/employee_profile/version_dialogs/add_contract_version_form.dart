import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';
import 'profile_date_button.dart';

class AddContractVersionForm extends StatelessWidget {
  const AddContractVersionForm({
    super.key,
    required this.formKey,
    required this.contractType,
    required this.probationMonths,
    required this.fileUrl,
    required this.startDate,
    required this.endDate,
    required this.onPickStartDate,
    required this.onPickEndDate,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController contractType;
  final TextEditingController probationMonths;
  final TextEditingController fileUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: contractType,
            decoration: InputDecoration(
              labelText: t.contractType,
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? t.contractTypeRequired : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ProfileDateButton(
                  label: t.startDate,
                  value: startDate,
                  onPressed: onPickStartDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ProfileDateButton(
                  label: t.endDate,
                  value: endDate,
                  onPressed: onPickEndDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: probationMonths,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: t.probationMonths,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: fileUrl,
            decoration: InputDecoration(
              labelText: t.contractFileUrlOptional,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
