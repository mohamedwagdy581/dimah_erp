import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class DocumentPreviewDialog extends StatelessWidget {
  const DocumentPreviewDialog({
    super.key,
    required this.title,
    required this.fileUrl,
  });

  final String title;
  final String fileUrl;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 720,
        height: 720,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    fileUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(t.unableOpenFile),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
