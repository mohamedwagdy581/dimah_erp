import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/safe_file_picker.dart';

class HrFormFileService {
  static Future<void> savePdf(
    BuildContext context, {
    required String suggestedName,
    required Future<Uint8List> Function() buildBytes,
    required String successMessage,
  }) async {
    final saveLocation = await SafeFilePicker.saveLocation(
      context: context,
      suggestedName: suggestedName,
      acceptedTypeGroups: const [XTypeGroup(label: 'PDF', extensions: ['pdf'])],
    );
    if (saveLocation == null) return;

    final bytes = await buildBytes();
    await XFile.fromData(
      bytes,
      name: suggestedName,
      mimeType: 'application/pdf',
    ).saveTo(saveLocation.path);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
  }
}
