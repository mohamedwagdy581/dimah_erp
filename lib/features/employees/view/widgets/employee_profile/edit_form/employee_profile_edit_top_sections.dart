import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../utils/employee_profile_utils.dart';
import 'employee_profile_edit_inputs.dart';

class EmployeeProfilePhotoSection extends StatelessWidget {
  const EmployeeProfilePhotoSection({
    super.key,
    required this.photoUrl,
    required this.saving,
    required this.pickingPhoto,
    required this.onPickPhoto,
  });

  final TextEditingController photoUrl;
  final bool saving;
  final bool pickingPhoto;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: resolveEmployeePhotoProvider(photoUrl.text),
              child: photoUrl.text.trim().isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (saving || pickingPhoto) ? null : onPickPhoto,
                icon: const Icon(Icons.upload_outlined),
                label: Text(pickingPhoto ? t.pickingPhoto : t.selectPhoto),
              ),
            ),
          ],
        ),
        if (pickingPhoto) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(t.uploadingPhoto, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ],
    );
  }
}

class EmployeeProfileStatusSection extends StatelessWidget {
  const EmployeeProfileStatusSection({
    super.key,
    required this.status,
    required this.paymentMethod,
    required this.onStatusChanged,
    required this.onPaymentMethodChanged,
  });

  final String status;
  final String paymentMethod;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onPaymentMethodChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: status,
            decoration: InputDecoration(
              labelText: t.status,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'active', child: Text(t.active)),
              DropdownMenuItem(value: 'inactive', child: Text(t.inactive)),
            ],
            onChanged: onStatusChanged,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: paymentMethod,
            decoration: InputDecoration(
              labelText: t.paymentMethod,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'bank', child: Text(t.paymentMethodBank)),
              DropdownMenuItem(value: 'cash', child: Text(t.paymentMethodCash)),
            ],
            onChanged: onPaymentMethodChanged,
          ),
        ),
      ],
    );
  }
}

class EmployeeProfileBasicFields extends StatelessWidget {
  const EmployeeProfileBasicFields({
    super.key,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  final TextEditingController fullName;
  final TextEditingController email;
  final TextEditingController phone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EmployeeProfileEditField(controller: fullName, label: 'Full Name', required: true),
        const SizedBox(height: 10),
        EmployeeProfileEditField(controller: email, label: 'Email', required: true),
        const SizedBox(height: 10),
        EmployeeProfileEditField(controller: phone, label: 'Phone', required: true),
      ],
    );
  }
}
