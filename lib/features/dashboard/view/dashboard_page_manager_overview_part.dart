part of 'dashboard_page.dart';

class _ManagerDashboardBody extends StatelessWidget {
  const _ManagerDashboardBody({
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
    required this.onRefresh,
    required this.onShowTimeline,
    required this.onQaDecision,
    required this.onReviewDecision,
    required this.onPickDueDate,
    required this.onAssignTask,
    required this.onTemplateChanged,
    required this.onEmployeeChanged,
    required this.onPriorityChanged,
    required this.onTaskTypeChanged,
    required this.taskTypeLabelBuilder,
    required this.onOpenExternalUrl,
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
  final VoidCallback onRefresh;
  final void Function(String employeeId, String employeeName) onShowTimeline;
  final void Function(Map<String, dynamic> task, {required String decision})
      onQaDecision;
  final void Function(Map<String, dynamic> task, {required bool approved})
      onReviewDecision;
  final VoidCallback onPickDueDate;
  final VoidCallback onAssignTask;
  final ValueChanged<String?> onTemplateChanged;
  final ValueChanged<String?> onEmployeeChanged;
  final ValueChanged<String?> onPriorityChanged;
  final ValueChanged<String?> onTaskTypeChanged;
  final String Function(AppLocalizations t, String type) taskTypeLabelBuilder;
  final ValueChanged<String> onOpenExternalUrl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ManagerDashboardHeader(onRefresh: onRefresh),
            const SizedBox(height: 10),
            _ManagerStatsSection(data: data),
            const SizedBox(height: 12),
            _ManagerOverviewSection(data: data),
            const SizedBox(height: 12),
            _ManagerChartsSection(
              data: data,
              taskTypeLabelBuilder: taskTypeLabelBuilder,
            ),
            const SizedBox(height: 12),
            _ManagerPerformanceSection(data: data),
            const SizedBox(height: 12),
            _ManagerMembersSection(data: data, onShowTimeline: onShowTimeline),
            const SizedBox(height: 12),
            _ManagerSimpleListCard(
              title: AppLocalizations.of(context)!.dueSoonTasks,
              emptyText: AppLocalizations.of(context)!.noDueSoonTasks,
              children: data.dueSoonTasks.map((r) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(r['title']?.toString() ?? '-'),
                subtitle: Text('${r['employee_name'] ?? '-'} | ${r['due_date'] ?? '-'}'),
              )).toList(),
            ),
            const SizedBox(height: 14),
            _ManagerPendingQaSection(data: data, onQaDecision: onQaDecision, onOpenExternalUrl: onOpenExternalUrl, taskTypeLabelBuilder: taskTypeLabelBuilder),
            const SizedBox(height: 14),
            _ManagerPendingReviewSection(data: data, onReviewDecision: onReviewDecision, onOpenExternalUrl: onOpenExternalUrl),
            const SizedBox(height: 14),
            _ManagerAssignTaskSection(
              data: data,
              taskCatalog: taskCatalog,
              templates: templates,
              saving: saving,
              employeeId: employeeId,
              selectedTemplateId: selectedTemplateId,
              priority: priority,
              taskType: taskType,
              dueDate: dueDate,
              title: title,
              description: description,
              estimateHours: estimateHours,
              onPickDueDate: onPickDueDate,
              onAssignTask: onAssignTask,
              onTemplateChanged: onTemplateChanged,
              onEmployeeChanged: onEmployeeChanged,
              onPriorityChanged: onPriorityChanged,
              onTaskTypeChanged: onTaskTypeChanged,
              taskTypeLabelBuilder: taskTypeLabelBuilder,
            ),
          ],
        );
      },
    );
  }
}
