import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import 'task_formatters.dart';
import 'task_labels.dart';
import 'task_meta_chip.dart';

class TaskCardChips extends StatelessWidget {
  const TaskCardChips({super.key, required this.task});

  final Map<String, dynamic> task;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        TaskMetaChip(
          label: taskTypeLabel(t, (task['task_type'] ?? 'general').toString()),
        ),
        TaskMetaChip(
          label: priorityLabel(t, (task['priority'] ?? 'medium').toString()),
        ),
        TaskMetaChip(
          label:
              '${t.estimateHours}: ${((task['estimate_hours'] as num?)?.toStringAsFixed(0) ?? '0')}',
        ),
        TaskMetaChip(
          label: '${t.dueDateLabel}: ${dateOnly(task['due_date']?.toString())}',
        ),
        TaskMetaChip(
          label: qaStatusLabel(t, (task['qa_status'] ?? 'pending').toString()),
        ),
      ],
    );
  }
}
