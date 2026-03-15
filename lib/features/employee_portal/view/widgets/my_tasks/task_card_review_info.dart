import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import 'task_formatters.dart';
import 'task_labels.dart';
import 'task_meta_chip.dart';
import 'task_meta_line.dart';

class TaskCardReviewInfo extends StatelessWidget {
  const TaskCardReviewInfo({super.key, required this.task});

  final Map<String, dynamic> task;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TaskMetaChip(label: reviewStatusLabel(t, (task['employee_review_status'] ?? 'none').toString())),
            if ((task['employee_review_requested_at'] ?? '').toString().isNotEmpty)
              TaskMetaChip(label: '${t.reviewRequestedAt}: ${dateTimeLabel(task['employee_review_requested_at']?.toString())}'),
          ],
        ),
        const SizedBox(height: 8),
        if ((task['employee_review_note'] ?? '').toString().trim().isNotEmpty)
          TaskMetaLine(label: t.yourReviewNote, value: task['employee_review_note'].toString()),
        if ((task['manager_review_note'] ?? '').toString().trim().isNotEmpty)
          TaskMetaLine(label: t.managerResponseNote, value: task['manager_review_note'].toString()),
      ],
    );
  }
}
