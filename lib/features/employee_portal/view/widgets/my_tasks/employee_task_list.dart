import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/app_localizations.dart';
import 'task_formatters.dart';
import 'task_labels.dart';

// Headers and values share column widths and alignment in both directions.
const _columnFlex = [5, 2, 3, 3, 3, 3, 3];

Widget _tableCell(int column, Widget child) => Expanded(
  flex: _columnFlex[column],
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Align(
      alignment: column == 0
          ? AlignmentDirectional.centerStart
          : Alignment.center,
      child: child,
    ),
  ),
);

class EmployeeTaskList extends StatelessWidget {
  const EmployeeTaskList({
    super.key,
    required this.tasks,
    required this.onOpen,
  });
  final List<Map<String, dynamic>> tasks;
  final ValueChanged<Map<String, dynamic>> onOpen;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final fontScale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final wide = constraints.maxWidth >= 950 * fontScale;
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      final t = AppLocalizations.of(context)!;
      final headers = [
        ar ? 'المهمة' : 'Task',
        t.priority,
        t.dueDateLabel,
        t.status,
        ar ? 'التقدّم' : 'Progress',
        ar ? 'الوقت المسجّل' : 'Logged time',
        ar ? 'الإجراءات' : 'Actions',
      ];
      return Column(
        children: [
          if (wide)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surfaceContainerLow
                    : const Color(0xFFF5F7F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < headers.length; i++)
                    _tableCell(
                      i,
                      Text(
                        headers[i],
                        textAlign: i == 0 ? TextAlign.start : TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          for (final task in tasks)
            _EmployeeTaskRow(
              key: ValueKey(task['id']),
              task: task,
              wide: wide,
              onOpen: () => onOpen(task),
            ),
        ],
      );
    },
  );
}

class _EmployeeTaskRow extends StatelessWidget {
  const _EmployeeTaskRow({
    super.key,
    required this.task,
    required this.wide,
    required this.onOpen,
  });
  final Map<String, dynamic> task;
  final bool wide;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final cs = Theme.of(context).colorScheme;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task['title']?.toString() ?? '—',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text(
          taskTypeLabel(t, (task['task_type'] ?? 'general').toString()),
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      ],
    );
    final priority = (task['priority'] ?? 'medium').toString();
    final priorityColor = switch (priority) {
      'high' => const Color(0xFFE53935),
      'low' => const Color(0xFF1677FF),
      _ => const Color(0xFFF59E0B),
    };
    final priorityBadge = _Badge(
      label: priorityLabel(t, priority),
      color: priorityColor,
      dot: true,
    );
    final review = task['employee_review_status'] == 'pending';
    final status = (task['status'] ?? 'todo').toString();
    final statusLabel = review
        ? (ar ? 'بانتظار المراجعة' : 'Awaiting review')
        : switch (status) {
            'done' => ar ? 'مكتملة' : 'Completed',
            'in_progress' => t.statusInProgress,
            _ => ar ? 'لم يبدأ' : 'Not started',
          };
    final statusColor = review
        ? const Color(0xFFEF8B17)
        : status == 'todo'
        ? const Color(0xFF1677FF)
        : const Color(0xFF009879);
    final statusBadge = _Badge(label: statusLabel, color: statusColor);
    final progress = ((task['progress'] as num?)?.toInt() ?? 0).clamp(0, 100);
    final progressBar = Semantics(
      label: ar ? 'التقدّم' : 'Progress',
      value: '$progress%',
      child: SizedBox(
        width: wide ? 130 : double.infinity,
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 7,
                  color: const Color(0xFF009879),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? cs.surfaceContainerHighest
                      : const Color(0xFFEBEEF0),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$progress%',
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
    final date = dateOnly(task['due_date']?.toString());
    final due = date == '-' ? '—' : date.replaceAll('-', '/');
    final duration = taskLoggedTime(task['logged_hours'], arabic: ar);
    final time = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            duration,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        if (DateTime.tryParse(
              task['active_timer_started_at']?.toString() ?? '',
            ) !=
            null) ...[
          const SizedBox(width: 4),
          Tooltip(
            message: ar ? 'المؤقت يعمل' : 'Timer running',
            child: const Icon(
              Icons.timer_outlined,
              size: 16,
              color: Color(0xFF009879),
            ),
          ),
        ],
      ],
    );
    final details = OutlinedButton(
      key: ValueKey('task-details-${task['id']}'),
      onPressed: onOpen,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        side: BorderSide(color: cs.primary.withValues(alpha: .65)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      child: Text(
        ar ? 'عرض التفاصيل' : 'View details',
        style: const TextStyle(fontSize: 13),
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: .25)),
        ),
      ),
      child: wide
          ? Row(
              children: [
                _tableCell(0, title),
                _tableCell(1, priorityBadge),
                _tableCell(
                  2,
                  Text(
                    due,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                _tableCell(3, statusBadge),
                _tableCell(4, progressBar),
                _tableCell(5, time),
                _tableCell(6, details),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [priorityBadge, statusBadge],
                ),
                const SizedBox(height: 14),
                progressBar,
                const SizedBox(height: 12),
                Text(
                  '${t.dueDateLabel}: $due',
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  ar ? 'الوقت المسجّل: $duration' : 'Logged time: $duration',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                details,
              ],
            ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.dot = false});
  final String label;
  final Color color;
  final bool dot;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (dot) ...[
        Icon(Icons.circle, size: 7, color: color),
        const SizedBox(width: 5),
      ],
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Color.lerp(color, Colors.white, .35)
                  : color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  );
}
