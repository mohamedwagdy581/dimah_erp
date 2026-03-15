part of 'dashboard_page.dart';

extension _ManagerDashboardAssignHelpers on _ManagerDashboardState {
  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _assignTask() async {
    if (_employeeId == null || _employeeId!.isEmpty) return;
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final estimate = double.tryParse(_estimateHours.text.trim());
    if (estimate == null || estimate <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.invalidEstimateHours)));
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) throw Exception(AppLocalizations.of(context)!.sessionMissing);
      final me = await client
          .from('users')
          .select('tenant_id')
          .eq('id', uid)
          .single();
      final tenantId = me['tenant_id'].toString();
      final autoWeight = await _resolveAutoWeight(
        tenantId: tenantId,
        employeeId: _employeeId!,
        taskType: _taskType,
      );
      final inserted = await client.from('employee_tasks').insert({
        'tenant_id': tenantId,
        'employee_id': _employeeId,
        'assigned_by_employee_id': widget.managerEmployeeId,
        'title': title,
        'description': _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        'task_type': _taskType,
        'estimate_hours': estimate,
        'priority': _priority,
        'weight': autoWeight,
        'due_date': _dueDate == null
            ? null
            : DateTime(
                _dueDate!.year,
                _dueDate!.month,
                _dueDate!.day,
              ).toIso8601String().split('T').first,
        'status': 'todo',
        'progress': 0,
      }).select('id').single();
      final taskId = inserted['id']?.toString();
      if (taskId != null && taskId.isNotEmpty) {
        await _appendTaskEvent(
          taskId: taskId,
          eventType: 'assigned',
        );
      }
      if (!mounted) return;
      _title.clear();
      _description.clear();
      _estimateHours.text = '8';
      _selectedTemplateId = null;
      _priority = 'medium';
      _taskType = _visibleTaskCatalog.first;
      _dueDate = null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.taskAssigned)));
      setState(() {
        _saving = false;
        _future = _loadData();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.assignFailed(e.toString()))));
    }
  }
}
