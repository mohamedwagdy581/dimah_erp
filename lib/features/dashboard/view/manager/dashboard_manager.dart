part of '../dashboard_page.dart';

class _ManagerDashboard extends StatefulWidget {
  const _ManagerDashboard({
    required this.managerEmployeeId,
    this.assignmentOnly = false,
    this.reviewsOnly = false,
  });

  final String managerEmployeeId;
  final bool assignmentOnly;
  final bool reviewsOnly;

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
  bool _pickingAttachment = false;
  ManagerTaskAttachment? _assignmentAttachment;
  final _submission = ManagerTaskSubmission();
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

  void _refreshData() {
    setState(() {
      _future = _loadData();
    });
  }

  void _setDueDate(DateTime? value) {
    setState(() {
      _dueDate = value;
    });
  }

  void _setSaving(bool value) {
    setState(() {
      _saving = value;
    });
  }

  void _setPickingAttachment(bool value) =>
      setState(() => _pickingAttachment = value);
  void _setAssignmentAttachment(ManagerTaskAttachment value) =>
      setState(() => _assignmentAttachment = value);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return FutureBuilder<_ManagerDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState();
        }
        final data = snapshot.data ?? const _ManagerDashboardData();
        if (snapshot.hasError) {
          return AppFailureState(error: snapshot.error, onRetry: _refreshData);
        }
        final taskCatalog = _taskCatalogForDepartments(
          data.managedDepartmentNames,
        );
        final templates = _taskTemplatesForDepartments(
          t,
          data.managedDepartmentNames,
        );
        _syncVisibleTaskCatalog(taskCatalog: taskCatalog, templates: templates);
        if (widget.reviewsOnly) {
          final rows = <String, Map<String, dynamic>>{};
          for (final row in [
            ...data.pendingReviewRequests,
            ...data.pendingQaTasks,
          ]) {
            rows[row['id'].toString()] = row;
          }
          return ManagerTaskReviewsView(
            tasks: rows.values.toList(),
            members: data.members
                .map(
                  (m) => TeamMember(
                    id: m.employeeId,
                    name: m.name,
                    jobTitle: m.jobTitle,
                  ),
                )
                .toList(),
            onRefresh: _refreshData,
            onOpenFile: _openExternalUrl,
            onDecision: _reviewTaskFromPage,
          );
        }
        if (widget.assignmentOnly) {
          return ManagerTaskAssignmentView(
            members: data.members
                .map(
                  (m) => TeamMember(
                    id: m.employeeId,
                    name: m.name,
                    jobTitle: m.jobTitle,
                  ),
                )
                .toList(),
            activeTasks: {
              for (final m in data.members)
                m.employeeId: m.totalTasks - m.doneTasks,
            },
            completion: {
              for (final m in data.members)
                m.employeeId: m.totalTasks == 0
                    ? 0.0
                    : m.doneTasks / m.totalTasks,
            },
            upcoming: data.dueSoonTasks,
            averageProgress: {
              for (final m in data.members)
                m.employeeId: m.averageProgressPercent / 100,
            },
            onRefresh: _refreshData,
            taskTypes: {
              for (final type in taskCatalog) type: _taskTypeLabel(t, type),
            },
            title: _title,
            description: _description,
            hours: _estimateHours,
            employeeId: _employeeId,
            taskType: _taskType,
            priority: _priority,
            dueDate: _dueDate,
            saving: _saving,
            attachmentName: _assignmentAttachment?.name,
            attachmentBytes: _assignmentAttachment?.bytes.length,
            pickingAttachment: _pickingAttachment,
            attachmentRetry: _submission.taskId != null,
            onPickAttachment: _pickAssignmentAttachment,
            onRemoveAttachment: () =>
                setState(() => _assignmentAttachment = null),
            onEmployee: (value) => setState(() => _employeeId = value),
            onType: (value) {
              if (value != null) setState(() => _taskType = value);
            },
            onPriority: (value) {
              if (value != null) setState(() => _priority = value);
            },
            onDate: _pickDueDate,
            onSubmit: _assignTask,
            onCancel: () {
              if (_saving) return;
              setState(() {
                _employeeId = null;
                _assignmentAttachment = null;
                _submission.clear();
                _title.clear();
                _description.clear();
                _estimateHours.text = '8';
                _dueDate = null;
                _priority = 'medium';
                _taskType = taskCatalog.first;
              });
            },
            onWeight: (employee, type) async {
              if (employee == null) return _defaultWeightForType(type);
              final client = Supabase.instance.client;
              final actor = await client
                  .from('users')
                  .select('tenant_id')
                  .eq('id', client.auth.currentUser!.id)
                  .single();
              return _resolveAutoWeight(
                tenantId: actor['tenant_id'].toString(),
                employeeId: employee,
                taskType: type,
              );
            },
          );
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
          onRefresh: _refreshData,
          onShowTimeline: _showMemberTimeline,
          onQaDecision: _openQaDecisionDialog,
          onReviewDecision: _openTaskReviewDialog,
          onPickDueDate: _pickDueDate,
          onAssignTask: _assignTask,
          onTemplateChanged: (value) =>
              _handleTemplateChanged(value: value, templates: templates),
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

  void _syncVisibleTaskCatalog({
    required List<String> taskCatalog,
    required List<_TaskTemplate> templates,
  }) {
    _visibleTaskCatalog = taskCatalog;
    if (!taskCatalog.contains(_taskType)) {
      _taskType = taskCatalog.first;
    }
    if (_selectedTemplateId != null &&
        !templates.any((template) => template.id == _selectedTemplateId)) {
      _selectedTemplateId = null;
    }
  }

  void _handleTemplateChanged({
    required String? value,
    required List<_TaskTemplate> templates,
  }) {
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
      appliedTemplate.estimateHours.truncateToDouble() ==
              appliedTemplate.estimateHours
          ? 0
          : 1,
    );
    setState(() {
      _taskType = appliedTemplate.taskType;
      _priority = appliedTemplate.priority;
    });
  }

  void _showMemberTimeline(String employeeId, String employeeName) {
    _showMemberTaskTimeline(employeeId: employeeId, employeeName: employeeName);
  }
}
