import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import 'task_card_chips.dart';
import 'task_card_attachments.dart';
import 'task_card_header.dart';
import 'task_card_review_info.dart';
import 'task_card_status_section.dart';
import 'task_formatters.dart';
import 'task_meta_line.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onStatusChanged,
    required this.onProgressChanged,
    required this.onRequestReview,
    required this.onAttachFile,
    required this.onLogHours,
    required this.onStartTimer,
    required this.onStopTimer,
    required this.onOpenAttachment,
  });

  final Map<String, dynamic> task;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<int> onProgressChanged;
  final VoidCallback onRequestReview;
  final VoidCallback onAttachFile;
  final VoidCallback onLogHours;
  final VoidCallback onStartTimer;
  final VoidCallback onStopTimer;
  final ValueChanged<String> onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final status = (task['status'] ?? 'todo').toString();
    final progress = (task['progress'] as num?)?.toInt() ?? 0;
    final timerStartedAt = (task['active_timer_started_at'] ?? '').toString();
    final timerRunning = timerStartedAt.isNotEmpty;
    final attachments =
        ((task['attachments'] as List?) ?? const []).cast<Map<String, dynamic>>();
    return Card(
      key: ValueKey(task['id']),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskCardHeader(
              title: task['title']?.toString() ?? '-',
              description: task['description']?.toString() ?? '',
            ),
            const SizedBox(height: 8),
            TaskCardChips(task: task),
            const SizedBox(height: 10),
            TaskMetaLine(
              label: t.assignedToEmployeeAt,
              value: dateTimeLabel(task['created_at']?.toString()),
            ),
            TaskMetaLine(
              label: t.employeeReceivedAt,
              value: dateTimeLabel(task['assignee_received_at']?.toString()),
            ),
            TaskMetaLine(
              label: t.employeeStartedAt,
              value: dateTimeLabel(task['assignee_started_at']?.toString()),
            ),
            TaskMetaLine(
              label: t.completedAtLabel,
              value: dateTimeLabel(task['completed_at']?.toString()),
            ),
            TaskMetaLine(
              label: t.lastUpdateAt,
              value: dateTimeLabel(task['updated_at']?.toString()),
            ),
            TaskMetaLine(
              label: isArabic ? 'الساعات المسجلة' : 'Logged Hours',
              value:
                  '${((task['logged_hours'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} / '
                  '${((task['estimate_hours'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}h',
            ),
            if (timerRunning)
              TaskMetaLine(
                label: isArabic ? 'المؤقت يعمل منذ' : 'Timer Running Since',
                value: dateTimeLabel(timerStartedAt),
              ),
            if ((task['employee_review_status'] ?? 'none').toString() != 'none')
              TaskCardReviewInfo(task: task),
            const SizedBox(height: 8),
            TaskCardStatusSection(
              status: status,
              progress: progress,
              onStatusChanged: onStatusChanged,
              onProgressChanged: onProgressChanged,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: timerRunning ? onStopTimer : onStartTimer,
                    icon: Icon(
                      timerRunning
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline,
                    ),
                    label: Text(
                      timerRunning
                          ? (isArabic ? 'إيقاف المؤقت' : 'Stop Timer')
                          : (isArabic ? 'بدء المؤقت' : 'Start Timer'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onLogHours,
                    icon: const Icon(Icons.timer_outlined),
                    label: Text(isArabic ? 'تسجيل يدوي' : 'Manual Log'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        (task['employee_review_status'] ?? 'none') == 'pending'
                        ? null
                        : onRequestReview,
                    icon: const Icon(Icons.rate_review_outlined),
                    label: Text(
                      (task['employee_review_status'] ?? 'none') == 'pending'
                          ? t.reviewPending
                          : t.requestManagerReview,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TaskCardAttachments(
              attachments: attachments,
              onAttachFile: onAttachFile,
              onOpenAttachment: onOpenAttachment,
            ),
          ],
        ),
      ),
    );
  }
}
