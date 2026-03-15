import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

Future<String?> showTaskReviewDialog(BuildContext context) async {
  final t = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  try {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.requestManagerReview),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: t.reviewNote,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.send),
          ),
        ],
      ),
    );
    if (confirmed != true) return null;
    final note = controller.text.trim();
    if (note.isEmpty) return '';
    return note;
  } finally {
    controller.dispose();
  }
}
