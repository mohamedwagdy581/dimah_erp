import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/utils/safe_file_picker.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../services/employee_profile_photo_upload_service.dart';

Future<String?> pickEmployeeProfilePhoto({
  required BuildContext context,
  required EmployeeProfilePhotoUploadService uploadService,
  required String displayName,
  required String employeeId,
}) async {
  final t = AppLocalizations.of(context)!;
  final file = await SafeFilePicker.openSingle(
    context: context,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'Images', extensions: ['png', 'jpg', 'jpeg', 'webp']),
    ],
  );
  if (file == null) return null;
  if (await file.length() > 5 * 1024 * 1024) {
    throw Exception(t.photoTooLargeMax5Mb);
  }
  return uploadService.uploadPhoto(
    fileName: file.name,
    bytes: await file.readAsBytes(),
    displayName: displayName,
    employeeId: employeeId,
  );
}
