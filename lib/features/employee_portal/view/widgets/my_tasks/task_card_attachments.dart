import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class TaskCardAttachments extends StatelessWidget {
  const TaskCardAttachments({
    super.key,
    required this.attachments,
    required this.onAttachFile,
    required this.onOpenAttachment,
  });

  final List<Map<String, dynamic>> attachments;
  final VoidCallback onAttachFile;
  final ValueChanged<String> onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onAttachFile,
              icon: const Icon(Icons.attach_file_outlined),
              label: Text(t.attachFile),
            ),
            const SizedBox(width: 10),
            Text(t.attachmentsCount(attachments.length)),
          ],
        ),
        if (attachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attachments
                .map(
                  (attachment) => ActionChip(
                    avatar: const Icon(Icons.attach_file, size: 16),
                    label: Text(
                      attachment['file_name']?.toString() ?? '-',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () =>
                        onOpenAttachment(attachment['file_url']?.toString() ?? ''),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
