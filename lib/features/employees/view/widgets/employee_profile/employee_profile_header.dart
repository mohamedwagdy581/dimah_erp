import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_profile_details.dart';
import '../../utils/employee_profile_utils.dart';

class EmployeeProfileHeader extends StatelessWidget {
  const EmployeeProfileHeader({
    super.key,
    required this.profile,
    required this.canEdit,
    required this.onDownload,
    this.onEdit,
  });

  final EmployeeProfileDetails profile;
  final bool canEdit;
  final VoidCallback onDownload;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: resolveEmployeePhotoProvider(profile.photoUrl),
          child: (profile.photoUrl ?? '').trim().isEmpty ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 12),
        Text(
          profile.fullName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.download_outlined),
          label: Text(AppLocalizations.of(context)!.downloadReport),
        ),
        const SizedBox(width: 8),
        if (canEdit)
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: Text(AppLocalizations.of(context)!.editProfile),
          ),
      ],
    );
  }
}
