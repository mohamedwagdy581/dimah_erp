part of 'dashboard_page.dart';

class _AttachmentWrap extends StatelessWidget {
  const _AttachmentWrap({required this.attachments, required this.onOpenExternalUrl});

  final List<Map<String, dynamic>> attachments;
  final ValueChanged<String> onOpenExternalUrl;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (attachments.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(t.attachments, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: attachments.map((attachment) => ActionChip(
            avatar: const Icon(Icons.attach_file, size: 16),
            label: Text(attachment['file_name']?.toString() ?? '-'),
            onPressed: () => onOpenExternalUrl(attachment['file_url']?.toString() ?? ''),
          )).toList(),
        ),
      ],
    );
  }
}
