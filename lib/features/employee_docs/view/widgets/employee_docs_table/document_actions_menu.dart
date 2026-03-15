import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/utils/safe_file_picker.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_document.dart';
import '../../cubit/employee_docs_cubit.dart';
import '../employee_docs_form_dialog.dart';
import 'document_file_utils.dart';

enum DocAction { preview, download, edit, delete }

class DocumentActionsMenu extends StatelessWidget {
  const DocumentActionsMenu({
    super.key,
    required this.doc,
    required this.onPreview,
  });

  final EmployeeDocument doc;
  final Future<void> Function() onPreview;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return PopupMenuButton<DocAction>(
      tooltip: t.actions,
      onSelected: (value) async {
        switch (value) {
          case DocAction.preview:
            await onPreview();
            break;
          case DocAction.download:
            await _downloadFile(context, t);
            break;
          case DocAction.edit:
            await _editDocument(context, t);
            break;
          case DocAction.delete:
            await _deleteDocument(context, t);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<DocAction>(value: DocAction.preview, child: Text(t.preview)),
        PopupMenuItem<DocAction>(value: DocAction.download, child: Text(t.download)),
        PopupMenuItem<DocAction>(value: DocAction.edit, child: Text(t.edit)),
        PopupMenuItem<DocAction>(value: DocAction.delete, child: Text(t.delete)),
      ],
      child: Container(
        height: 28,
        width: 28,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.more_horiz, size: 16, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  Future<void> _editDocument(BuildContext context, AppLocalizations t) async {
    final cubit = context.read<EmployeeDocsCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(value: cubit, child: EmployeeDocsFormDialog(initialDocument: doc)),
    );
    if (ok == true && context.mounted) {
      cubit.load();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.documentUpdated)));
    }
  }

  Future<void> _deleteDocument(BuildContext context, AppLocalizations t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.deleteDocument),
        content: Text(t.deleteDocumentConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(t.delete)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<EmployeeDocsCubit>().delete(id: doc.id, employeeId: doc.employeeId, fileUrl: doc.fileUrl);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.documentDeleted)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.saveFailed(e.toString()))));
    }
  }

  Future<void> _downloadFile(BuildContext context, AppLocalizations t) async {
    try {
      final path = storagePathFromPublicUrl(doc.fileUrl);
      if (path == null) throw Exception(t.invalidFileUrl);
      final suggestedName = Uri.tryParse(doc.fileUrl)?.pathSegments.last ?? '${doc.docType}.bin';
      final ext = suggestedName.contains('.') ? suggestedName.split('.').last.toLowerCase() : '';
      final saveLocation = await SafeFilePicker.saveLocation(
        context: context,
        suggestedName: suggestedName,
        acceptedTypeGroups: [XTypeGroup(label: t.file, extensions: ext.isEmpty ? null : [ext])],
      );
      if (saveLocation == null || saveLocation.path.isEmpty) return;

      final bytes = await Supabase.instance.client.storage.from('employee_docs').download(path);
      await File(saveLocation.path).writeAsBytes(bytes, flush: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.fileSavedTo(saveLocation.path))));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.fileDownloadFailed(e.toString()))));
    }
  }
}
