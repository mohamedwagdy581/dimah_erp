import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';
import 'profile_date_button.dart';

class AddCompensationVersionForm extends StatelessWidget {
  const AddCompensationVersionForm({
    super.key,
    required this.formKey,
    required this.basic,
    required this.housing,
    required this.transport,
    required this.other,
    required this.note,
    required this.effectiveAt,
    required this.onPickEffectiveDate,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController basic;
  final TextEditingController housing;
  final TextEditingController transport;
  final TextEditingController other;
  final TextEditingController note;
  final DateTime? effectiveAt;
  final VoidCallback onPickEffectiveDate;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompensationNumberField(controller: basic, label: t.basicSalary),
          const SizedBox(height: 10),
          _CompensationNumberField(
            controller: housing,
            label: t.housingAllowance,
          ),
          const SizedBox(height: 10),
          _CompensationNumberField(
            controller: transport,
            label: t.transportAllowance,
          ),
          const SizedBox(height: 10),
          _CompensationNumberField(controller: other, label: t.otherAllowance),
          const SizedBox(height: 10),
          ProfileDateButton(
            label: t.effectiveDate,
            value: effectiveAt,
            icon: Icons.event,
            onPressed: onPickEffectiveDate,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: note,
            decoration: InputDecoration(
              labelText: t.noteOptional,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompensationNumberField extends StatelessWidget {
  const _CompensationNumberField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if ((value ?? '').trim().isEmpty) return t.fieldRequired(label);
        if (double.tryParse(value!.trim()) == null) return t.invalidNumber;
        return null;
      },
    );
  }
}
