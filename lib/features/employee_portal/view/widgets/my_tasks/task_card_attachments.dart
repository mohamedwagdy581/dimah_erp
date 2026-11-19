import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/app_localizations.dart';

class TaskCardAttachments extends StatelessWidget {
  const TaskCardAttachments({
    super.key,
    required this.attachments,
    required this.onAttachFile,
    required this.onOpenAttachment,
    this.responsive = false,
  });

  final List<Map<String, dynamic>> attachments;
  final VoidCallback onAttachFile;
  final ValueChanged<String> onOpenAttachment;
  final bool responsive;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final attachButton = OutlinedButton.icon(
      onPressed: onAttachFile,
      icon: const Icon(Icons.attach_file_outlined),
      label: Text(t.attachFile),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (responsive)
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              attachButton,
              Text(t.attachmentsCount(attachments.length)),
            ],
          )
        else
          Row(
            children: [
              attachButton,
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
                    onPressed: () => onOpenAttachment(
                      attachment['file_url']?.toString() ?? '',
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
