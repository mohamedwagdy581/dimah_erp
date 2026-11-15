import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import 'task_card_review_info.dart';
import 'task_card_status_section.dart';
import 'task_formatters.dart';
import 'task_labels.dart';

/// Ordinary employee presentation of the existing task actions and metadata.
class EmployeeTaskDetails extends StatelessWidget {
  const EmployeeTaskDetails({
    super.key,
    required this.task,
    required this.busy,
    required this.onBack,
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
  final bool busy;
  final VoidCallback onBack;
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
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final status = (task['status'] ?? 'todo').toString();
    final progress = ((task['progress'] as num?)?.toInt() ?? 0).clamp(0, 100);
    final running =
        DateTime.tryParse(task['active_timer_started_at']?.toString() ?? '') !=
        null;
    final reviewPending = task['employee_review_status'] == 'pending';
    final priority = (task['priority'] ?? 'medium').toString();
    final priorityColor = switch (priority) {
      'high' => const Color(0xFFE53935),
      'low' => const Color(0xFF1677FF),
      _ => const Color(0xFFF59E0B),
    };
    final date = dateOnly(task['due_date']?.toString());
    final description = task['description']?.toString().trim() ?? '';
    final attachments = ((task['attachments'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();

    Widget pill(String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    Widget summary(String label, Widget value) => SizedBox(
      width: 135,
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          value,
        ],
      ),
    );
    final overview = _Panel(
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 16,
        children: [
          summary(t.priority, pill(priorityLabel(t, priority), priorityColor)),
          summary(
            t.dueDateLabel,
            Text(
              date == '-' ? '—' : date.replaceAll('-', '/'),
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          summary(
            ar ? 'التقدّم' : 'Progress',
            Text(
              '$progress%',
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          summary(
            t.status,
            Column(
              children: [
                pill(
                  reviewPending
                      ? (ar ? 'بانتظار المراجعة' : 'Awaiting review')
                      : switch (status) {
                          'done' => t.statusDone,
                          'in_progress' => t.statusInProgress,
                          _ => t.statusTodo,
                        },
                  reviewPending
                      ? const Color(0xFFEF8B17)
                      : const Color(0xFF009879),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 85,
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(8),
                    color: cs.primary,
                    backgroundColor: cs.outlineVariant.withValues(alpha: .3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: busy || reviewPending ? null : onRequestReview,
          icon: const Icon(Icons.send_outlined, size: 18),
          label: Text(
            reviewPending
                ? t.reviewPending
                : (ar ? 'طلب مراجعة' : 'Request review'),
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: busy
              ? null
              : running
              ? onStopTimer
              : onStartTimer,
          icon: Icon(
            running ? Icons.stop_circle_outlined : Icons.play_circle_fill,
            size: 20,
          ),
          label: Text(
            running
                ? (ar ? 'إيقاف المؤقت' : 'Stop Timer')
                : (ar ? 'بدء المؤقت' : 'Start Timer'),
          ),
        ),
        PopupMenuButton<String>(
          enabled: !busy,
          tooltip: ar ? 'إجراءات إضافية' : 'More actions',
          onSelected: (_) => onLogHours(),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'log',
              child: Text(ar ? 'تسجيل الوقت يدويًا' : 'Log time manually'),
            ),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      ],
    );
    final descriptionPanel = _Panel(
      title: ar ? 'وصف المهمة' : 'Task description',
      icon: Icons.notes_rounded,
      child: Text(
        description.isEmpty
            ? (ar ? 'لا يوجد وصف لهذه المهمة' : 'No description provided')
            : description,
        style: TextStyle(fontSize: 15, height: 1.8, color: cs.onSurfaceVariant),
      ),
    );
    final timePanel = _Panel(
      title: ar ? 'الوقت المقدّر والمسجّل' : 'Estimated and logged time',
      icon: Icons.schedule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _TimeTile(
                  label: ar ? 'الوقت المقدّر' : 'Estimated time',
                  value: taskLoggedTime(task['estimate_hours'], arabic: ar),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeTile(
                  label: ar ? 'الوقت المسجّل' : 'Logged time',
                  value: taskLoggedTime(task['logged_hours'], arabic: ar),
                ),
              ),
            ],
          ),
          if (running) ...[
            const SizedBox(height: 12),
            Text(
              '${ar ? 'المؤقت يعمل منذ' : 'Timer running since'}: ${dateTimeLabel(task['active_timer_started_at']?.toString())}',
              style: TextStyle(fontSize: 13, color: cs.primary),
            ),
          ],
        ],
      ),
    );
    final attachmentPanel = _Panel(
      title: ar ? 'المرفقات' : 'Attachments',
      icon: Icons.attach_file,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final upload = OutlinedButton(
            key: const ValueKey('task-upload-attachment'),
            onPressed: busy ? null : onAttachFile,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(24),
              side: BorderSide(color: cs.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.upload_file_outlined,
                  size: 30,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(height: 10),
                Text(ar ? 'إضافة مرفق' : 'Add attachment'),
                const SizedBox(height: 6),
                Text(
                  ar ? 'اختر ملفًا من جهازك' : 'Choose a file from your device',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          );
          final files = Column(
            children: [
              if (attachments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    ar ? 'لا توجد مرفقات' : 'No attachments',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
              for (final file in attachments)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(9),
                    child: ListTile(
                      key: ValueKey('task-attachment-${file['id']}'),
                      onTap:
                          busy || (file['file_url']?.toString() ?? '').isEmpty
                          ? null
                          : () => onOpenAttachment(file['file_url'].toString()),
                      leading: Icon(
                        file['mime_type'] == 'application/pdf'
                            ? Icons.picture_as_pdf
                            : Icons.insert_drive_file_outlined,
                        color: file['mime_type'] == 'application/pdf'
                            ? Colors.redAccent
                            : cs.onSurfaceVariant,
                      ),
                      title: Text(
                        file['file_name']?.toString() ?? '—',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle:
                          DateTime.tryParse(
                                file['created_at']?.toString() ?? '',
                              ) ==
                              null
                          ? null
                          : Text(
                              dateOnly(file['created_at'].toString()),
                              style: const TextStyle(fontSize: 12),
                            ),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                    ),
                  ),
                ),
            ],
          );
          return constraints.maxWidth >= 540
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: files),
                    const SizedBox(width: 12),
                    Expanded(child: upload),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [files, const SizedBox(height: 12), upload],
                );
        },
      ),
    );
    final events =
        <(String, String, IconData)>[
              (t.assignedToEmployeeAt, 'created_at', Icons.check_circle),
              (
                t.employeeReceivedAt,
                'assignee_received_at',
                Icons.mark_email_read_outlined,
              ),
              (
                t.employeeStartedAt,
                'assignee_started_at',
                Icons.play_circle_fill,
              ),
              (t.completedAtLabel, 'completed_at', Icons.task_alt),
              (
                t.reviewRequestedAt,
                'employee_review_requested_at',
                Icons.rate_review_outlined,
              ),
              (
                ar ? 'مراجعة المدير' : 'Manager review',
                'manager_reviewed_at',
                Icons.fact_check_outlined,
              ),
            ]
            .where(
              (event) =>
                  DateTime.tryParse(task[event.$2]?.toString() ?? '') != null,
            )
            .toList()
          ..sort(
            (a, b) => DateTime.parse(
              task[a.$2].toString(),
            ).compareTo(DateTime.parse(task[b.$2].toString())),
          );
    final timelinePanel = _Panel(
      title: ar ? 'سجل المتابعة' : 'Task activity',
      icon: Icons.timeline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (events.isEmpty)
            Text(
              ar ? 'لا توجد أحداث مسجلة' : 'No recorded activity',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          for (var i = 0; i < events.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 26,
                    child: Column(
                      children: [
                        Icon(
                          events[i].$3,
                          size: 20,
                          color: i == 0 ? const Color(0xFF009879) : cs.primary,
                        ),
                        if (i < events.length - 1)
                          Expanded(
                            child: VerticalDivider(color: cs.outlineVariant),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            events[i].$1,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dateTimeLabel(task[events[i].$2].toString()),
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if ((task['employee_review_status'] ?? 'none') != 'none')
            TaskCardReviewInfo(task: task),
          if ((task['qa_status'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${ar ? 'فحص الجودة' : 'Quality check'}: ${qaStatusLabel(t, task['qa_status'].toString())}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '${t.lastUpdateAt}: ${dateTimeLabel(task['updated_at']?.toString())}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: busy ? null : onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(ar ? 'العودة إلى المهام' : 'Back to tasks'),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.description_rounded, color: cs.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['title']?.toString() ?? '—',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          taskTypeLabel(
                            t,
                            (task['task_type'] ?? 'general').toString(),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (busy) const LinearProgressIndicator(),
              LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth >= 1000
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 3, child: overview),
                          const SizedBox(width: 20),
                          Expanded(flex: 2, child: actions),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          actions,
                          const SizedBox(height: 16),
                          overview,
                        ],
                      ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final textScale =
                      MediaQuery.textScalerOf(context).scale(14) / 14;
                  if (constraints.maxWidth < 900 * textScale) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        descriptionPanel,
                        const SizedBox(height: 16),
                        timePanel,
                        const SizedBox(height: 16),
                        attachmentPanel,
                        const SizedBox(height: 16),
                        timelinePanel,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            timePanel,
                            const SizedBox(height: 16),
                            timelinePanel,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            descriptionPanel,
                            const SizedBox(height: 16),
                            attachmentPanel,
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _Panel(
                title: ar ? 'تحديث المهمة' : 'Update task',
                icon: Icons.tune,
                child: AbsorbPointer(
                  absorbing: busy,
                  child: TaskCardStatusSection(
                    key: ValueKey('${task['id']}:$status:$progress'),
                    responsive: true,
                    status: status,
                    progress: progress,
                    onStatusChanged: onStatusChanged,
                    onProgressChanged: onProgressChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({this.title, this.icon, required this.child});
  final String? title;
  final IconData? icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surface
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: .4),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        child,
      ],
    ),
  );
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: .3),
      ),
    ),
    child: Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
