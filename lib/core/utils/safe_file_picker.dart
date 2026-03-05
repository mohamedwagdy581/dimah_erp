import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

class SafeFilePicker {
  SafeFilePicker._();

  static bool _busy = false;

  static Future<XFile?> openSingle({
    required BuildContext context,
    required List<XTypeGroup> acceptedTypeGroups,
    String busyMessage = 'A file dialog is already open.',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_busy) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(busyMessage)),
        );
      }
      return null;
    }

    _busy = true;
    try {
      final ext = _extractExtensions(acceptedTypeGroups);

      // More stable on Windows for large/complex picker sessions.
      if (Platform.isWindows) {
        final result = await FilePicker.platform
            .pickFiles(
              allowMultiple: false,
              lockParentWindow: true,
              type: ext.isEmpty ? FileType.any : FileType.custom,
              allowedExtensions: ext.isEmpty ? null : ext,
              withData: false,
            )
            .timeout(timeout);
        if (result == null || result.files.isEmpty) return null;
        final f = result.files.single;
        if ((f.path ?? '').trim().isNotEmpty) {
          return XFile(f.path!);
        }
        if (f.bytes != null) {
          return XFile.fromData(f.bytes!, name: f.name);
        }
        return null;
      }

      return await openFile(
        acceptedTypeGroups: acceptedTypeGroups,
      ).timeout(timeout);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to open file picker: $e')));
      }
      return null;
    } finally {
      _busy = false;
    }
  }

  static Future<FileSaveLocation?> saveLocation({
    required BuildContext context,
    required String suggestedName,
    required List<XTypeGroup> acceptedTypeGroups,
    String busyMessage = 'A file dialog is already open.',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_busy) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(busyMessage)),
        );
      }
      return null;
    }

    _busy = true;
    try {
      final ext = _extractExtensions(acceptedTypeGroups);

      if (Platform.isWindows) {
        final path = await FilePicker.platform
            .saveFile(
              dialogTitle: 'Save File',
              fileName: suggestedName,
              lockParentWindow: true,
              type: ext.isEmpty ? FileType.any : FileType.custom,
              allowedExtensions: ext.isEmpty ? null : ext,
            )
            .timeout(timeout);
        if ((path ?? '').trim().isEmpty) return null;
        return FileSaveLocation(path!);
      }

      return await getSaveLocation(
        suggestedName: suggestedName,
        acceptedTypeGroups: acceptedTypeGroups,
      ).timeout(timeout);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open save dialog: $e')),
        );
      }
      return null;
    } finally {
      _busy = false;
    }
  }

  static List<String> _extractExtensions(List<XTypeGroup> groups) {
    final ext = <String>{};
    for (final g in groups) {
      final list = g.extensions ?? const <String>[];
      for (final e in list) {
        final v = e.trim().toLowerCase().replaceFirst('.', '');
        if (v.isNotEmpty) ext.add(v);
      }
    }
    return ext.toList();
  }
}
