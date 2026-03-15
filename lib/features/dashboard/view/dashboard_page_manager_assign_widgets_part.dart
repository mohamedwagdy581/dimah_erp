part of 'dashboard_page.dart';

class _ManagerAssignTaskSection extends StatelessWidget {
  const _ManagerAssignTaskSection({
    required this.data,
    required this.taskCatalog,
    required this.templates,
    required this.saving,
    required this.employeeId,
    required this.selectedTemplateId,
    required this.priority,
    required this.taskType,
    required this.dueDate,
    required this.title,
    required this.description,
    required this.estimateHours,
    required this.onPickDueDate,
    required this.onAssignTask,
    required this.onTemplateChanged,
    required this.onEmployeeChanged,
    required this.onPriorityChanged,
    required this.onTaskTypeChanged,
    required this.taskTypeLabelBuilder,
  });

  final _ManagerDashboardData data;
  final List<String> taskCatalog;
  final List<_TaskTemplate> templates;
  final bool saving;
  final String? employeeId;
  final String? selectedTemplateId;
  final String priority;
  final String taskType;
  final DateTime? dueDate;
  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController estimateHours;
  final VoidCallback onPickDueDate;
  final VoidCallback onAssignTask;
  final ValueChanged<String?> onTemplateChanged;
  final ValueChanged<String?> onEmployeeChanged;
  final ValueChanged<String?> onPriorityChanged;
  final ValueChanged<String?> onTaskTypeChanged;
  final String Function(AppLocalizations t, String type) taskTypeLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.assignTask, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              data.primaryManagedDepartmentName == null ? t.taskCatalog : t.taskCatalogForDepartment(data.primaryManagedDepartmentName!),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: taskCatalog.map((type) => Chip(label: Text(taskTypeLabelBuilder(t, type)), visualDensity: VisualDensity.compact)).toList(),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: selectedTemplateId,
              decoration: InputDecoration(labelText: t.taskTemplate, border: const OutlineInputBorder()),
              items: templates.map((template) => DropdownMenuItem<String>(value: template.id, child: Text(template.title))).toList(),
              onChanged: saving ? null : onTemplateChanged,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: employeeId,
              decoration: InputDecoration(labelText: t.employee, border: const OutlineInputBorder()),
              items: data.members.map((m) => DropdownMenuItem(value: m.employeeId, child: Text(m.name))).toList(),
              onChanged: saving ? null : onEmployeeChanged,
            ),
            const SizedBox(height: 10),
            TextField(controller: title, enabled: !saving, decoration: InputDecoration(labelText: t.taskTitle, border: const OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: description, enabled: !saving, maxLines: 3, decoration: InputDecoration(labelText: t.descriptionOptional, border: const OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
              controller: estimateHours,
              enabled: !saving,
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
                    onChanged: saving ? null : onPriorityChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: taskType,
                    decoration: InputDecoration(labelText: t.taskType, border: const OutlineInputBorder()),
                    items: taskCatalog.map((type) => DropdownMenuItem<String>(value: type, child: Text(taskTypeLabelBuilder(t, type)))).toList(),
                    onChanged: saving ? null : onTaskTypeChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: saving ? null : onPickDueDate,
              icon: const Icon(Icons.event),
              label: Text(
                dueDate == null
                    ? t.dueDateOptional
                    : '${dueDate!.year.toString().padLeft(4, '0')}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: saving ? null : onAssignTask,
              icon: const Icon(Icons.send_outlined),
              label: Text(saving ? t.assigning : t.assignTask),
            ),
          ],
        ),
      ),
    );
  }
}
