part of 'dashboard_page.dart';

class _ManagerDashboard extends StatefulWidget {
  const _ManagerDashboard({required this.managerEmployeeId});

  final String managerEmployeeId;

  @override
  State<_ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<_ManagerDashboard> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _estimateHours = TextEditingController(text: '8');
  String? _employeeId;
  String? _selectedTemplateId;
  String _priority = 'medium';
  String _taskType = 'general';
  List<String> _visibleTaskCatalog = const ['general'];
  bool _saving = false;
  DateTime? _dueDate;
  late Future<_ManagerDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _estimateHours.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return FutureBuilder<_ManagerDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? const _ManagerDashboardData();
        final taskCatalog = _taskCatalogForDepartments(data.managedDepartmentNames);
        final templates = _taskTemplatesForDepartments(t, data.managedDepartmentNames);
        _visibleTaskCatalog = taskCatalog;
        if (!taskCatalog.contains(_taskType)) _taskType = taskCatalog.first;
        if (_selectedTemplateId != null && !templates.any((template) => template.id == _selectedTemplateId)) {
          _selectedTemplateId = null;
        }
        return _ManagerDashboardBody(
          data: data,
          taskCatalog: taskCatalog,
          templates: templates,
          saving: _saving,
          employeeId: _employeeId,
          selectedTemplateId: _selectedTemplateId,
          priority: _priority,
          taskType: _taskType,
          dueDate: _dueDate,
          title: _title,
          description: _description,
          estimateHours: _estimateHours,
          onRefresh: () => setState(() {
            _future = _loadData();
          }),
          onShowTimeline: (employeeId, employeeName) => _showMemberTaskTimeline(employeeId: employeeId, employeeName: employeeName),
          onQaDecision: _openQaDecisionDialog,
          onReviewDecision: _openTaskReviewDialog,
          onPickDueDate: _pickDueDate,
          onAssignTask: _assignTask,
          onTemplateChanged: (value) {
            setState(() {
              _selectedTemplateId = value;
            });
            if (value == null) return;
            _TaskTemplate? selected;
            for (final template in templates) {
              if (template.id == value) {
                selected = template;
                break;
              }
            }
            if (selected == null) return;
            final appliedTemplate = selected;
            _title.text = appliedTemplate.title;
            _description.text = appliedTemplate.description;
            _estimateHours.text = appliedTemplate.estimateHours.toStringAsFixed(
              appliedTemplate.estimateHours.truncateToDouble() == appliedTemplate.estimateHours ? 0 : 1,
            );
            setState(() {
              _taskType = appliedTemplate.taskType;
              _priority = appliedTemplate.priority;
            });
          },
          onEmployeeChanged: (value) => setState(() {
            _employeeId = value;
          }),
          onPriorityChanged: (value) {
            if (value == null) return;
            setState(() {
              _priority = value;
            });
          },
          onTaskTypeChanged: (value) {
            if (value == null) return;
            setState(() {
              _taskType = value;
            });
          },
          taskTypeLabelBuilder: _taskTypeLabel,
          onOpenExternalUrl: _openExternalUrl,
        );
      },
    );
  }
}
