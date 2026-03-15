import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/utils/safe_file_picker.dart';
import '../../../../../../l10n/app_localizations.dart';

class PersonalPhotoPickerField extends StatefulWidget {
  const PersonalPhotoPickerField({
    super.key,
    required this.photoUrl,
    required this.onChanged,
  });

  final String photoUrl;
  final ValueChanged<String> onChanged;

  @override
  State<PersonalPhotoPickerField> createState() =>
      _PersonalPhotoPickerFieldState();
}

class _PersonalPhotoPickerFieldState extends State<PersonalPhotoPickerField> {
  static const int _maxPhotoBytes = 5 * 1024 * 1024;
  bool _picking = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final hasPhoto = widget.photoUrl.trim().isNotEmpty;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: hasPhoto
              ? _resolvePhotoProvider(widget.photoUrl)
              : null,
          child: hasPhoto ? null : const Icon(Icons.person),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _picking ? null : _pickOnly,
            icon: const Icon(Icons.upload_outlined),
            label: Text(_picking ? t.picking : t.selectEmployeePhoto),
          ),
        ),
      ],
    );
  }

  ImageProvider _resolvePhotoProvider(String rawValue) {
    final value = rawValue.trim();
    final uri = Uri.tryParse(value);
    if (uri != null) {
      final scheme = uri.scheme.toLowerCase();
      if (scheme == 'http' || scheme == 'https') return NetworkImage(value);
      if (scheme == 'file') return FileImage(File(uri.toFilePath()));
    }
    return FileImage(File(value));
  }

  Future<void> _pickOnly() async {
    final t = AppLocalizations.of(context)!;
    final file = await SafeFilePicker.openSingle(
      context: context,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Images', extensions: ['png', 'jpg', 'jpeg', 'webp']),
      ],
    );
    if (file == null) return;
    setState(() => _picking = true);
    try {
      if (await file.length() > _maxPhotoBytes)
        throw Exception(t.photoTooLargeMax5Mb);
      if (file.path.isEmpty) throw Exception(t.unableAccessSelectedFilePath);
      widget.onChanged(file.path);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.photoSelectedUploadAfterCreate)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.photoUploadFailed(error.toString()))),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }
}
