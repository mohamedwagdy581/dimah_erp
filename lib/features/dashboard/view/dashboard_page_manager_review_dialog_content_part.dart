part of 'dashboard_page.dart';

class _ManagerReviewDialogContent extends StatelessWidget {
  const _ManagerReviewDialogContent({
    required this.approved,
    required this.task,
    required this.t,
    required this.title,
    required this.description,
    required this.estimate,
    required this.note,
    required this.priority,
    required this.taskType,
    required this.dueDate,
    required this.visibleTaskCatalog,
    required this.taskTypeLabelBuilder,
    required this.onPriorityChanged,
    required this.onTaskTypeChanged,
    required this.onDueDateChanged,
  });

  final bool approved;
  final Map<String, dynamic> task;
  final AppLocalizations t;
  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController estimate;
  final TextEditingController note;
  final String priority;
  final String taskType;
  final DateTime? dueDate;
  final List<String> visibleTaskCatalog;
  final String Function(AppLocalizations t, String type) taskTypeLabelBuilder;
  final ValueChanged<String> onPriorityChanged;
  final ValueChanged<String> onTaskTypeChanged;
  final ValueChanged<DateTime?> onDueDateChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 540,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t.employee}: ${task['employee_name'] ?? '-'}'),
            const SizedBox(height: 8),
            Text('${t.reviewNote}: ${task['employee_review_note'] ?? '-'}'),
            const SizedBox(height: 12),
            TextField(
              controller: title,
              enabled: approved,
              decoration: InputDecoration(labelText: t.taskTitle, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: description,
              enabled: approved,
              maxLines: 3,
              decoration: InputDecoration(labelText: t.descriptionOptional, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: estimate,
              enabled: approved,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: t.estimateHours, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: priority,
                    decoration: InputDecoration(labelText: t.priority, border: const OutlineInputBorder()),
                    items: [
                      DropdownMenuItem(value: 'low', child: Text(t.priorityLow)),
                      DropdownMenuItem(value: 'medium', child: Text(t.priorityMedium)),
                      DropdownMenuItem(value: 'high', child: Text(t.priorityHigh)),
                    ],
                    onChanged: approved
                        ? (value) {
                            if (value != null) onPriorityChanged(value);
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: taskType,
                    decoration: InputDecoration(labelText: t.taskType, border: const OutlineInputBorder()),
                    items: visibleTaskCatalog
                        .map((type) => DropdownMenuItem<String>(value: type, child: Text(taskTypeLabelBuilder(t, type))))
                        .toList(),
                    onChanged: approved
                        ? (value) {
                            if (value != null) onTaskTypeChanged(value);
                          }
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: approved
                  ? () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now(),
                        firstDate: DateTime(2024, 1, 1),
                        lastDate: DateTime(2030, 12, 31),
                      );
                      if (picked != null) onDueDateChanged(picked);
                    }
                  : null,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                dueDate == null
                    ? t.dueDateOptional
                    : '${dueDate!.year.toString().padLeft(4, '0')}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              maxLines: 4,
              decoration: InputDecoration(labelText: t.managerResponseNote, border: const OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }
}
