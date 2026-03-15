import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class TaskFiltersBar extends StatelessWidget {
  const TaskFiltersBar({
    super.key,
    required this.currentFilter,
    required this.totalCount,
    required this.todoCount,
    required this.inProgressCount,
    required this.doneCount,
    required this.reviewCount,
    required this.qaCount,
    required this.onChanged,
  });

  final String currentFilter;
  final int totalCount;
  final int todoCount;
  final int inProgressCount;
  final int doneCount;
  final int reviewCount;
  final int qaCount;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final filters = [
      ('all', t.allTasks, totalCount),
      ('todo', t.statusTodo, todoCount),
      ('in_progress', t.statusInProgress, inProgressCount),
      ('done', t.statusDone, doneCount),
      ('review_pending', t.reviewPending, reviewCount),
      ('qa_pending', t.qaPending, qaCount),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters
          .map(
            (item) => FilterChip(
              label: Text('${item.$2} (${item.$3})'),
              selected: currentFilter == item.$1,
              onSelected: (_) => onChanged(item.$1),
            ),
          )
          .toList(),
    );
  }
}
