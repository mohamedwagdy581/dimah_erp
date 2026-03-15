import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_document.dart';
import 'document_actions_menu.dart';
import 'document_expiry_utils.dart';
import 'document_file_utils.dart';
import 'document_preview_dialog.dart';
import 'document_type_utils.dart';

class DocumentCard extends StatelessWidget {
  const DocumentCard({super.key, required this.doc});

  final EmployeeDocument doc;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final actionStyle = OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const Size(0, 30),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    );
    final status = expiryStatus(doc.expiresAt);
    final badgeColor = statusColor(theme, status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _previewDocument(context, t),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DocumentCardHeader(doc: doc, badgeColor: badgeColor, status: status, onPreview: () => _previewDocument(context, t)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(docTypeLabel(t, doc.docType), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(fileTypeLabel(t, doc.fileUrl), style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant)),
                  if (doc.expiresAt != null)
                    Text('${t.expires}: ${formatDocDate(doc.expiresAt)}', style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: actionStyle,
                    onPressed: () => _previewDocument(context, t),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: Text(t.open),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _previewDocument(BuildContext context, AppLocalizations t) async {
    if (!isImageFile(doc.fileUrl)) {
      return _openFile(context, t, doc.fileUrl);
    }
    await showDialog<void>(
      context: context,
      builder: (_) => DocumentPreviewDialog(title: docTypeLabel(t, doc.docType), fileUrl: doc.fileUrl),
    );
  }

  Future<void> _openFile(BuildContext context, AppLocalizations t, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.invalidFileUrl)));
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _DocumentCardHeader extends StatelessWidget {
  const _DocumentCardHeader({
    required this.doc,
    required this.badgeColor,
    required this.status,
    required this.onPreview,
  });

  final EmployeeDocument doc;
  final Color badgeColor;
  final ExpiryStatus status;
  final Future<void> Function() onPreview;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SizedBox(
      height: 96,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel(t, status),
                    style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                DocumentActionsMenu(doc: doc, onPreview: onPreview),
              ],
            ),
            const Spacer(),
            Icon(iconForDocType(doc.docType), size: 40, color: iconColorForDocType(context, doc.docType)),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
