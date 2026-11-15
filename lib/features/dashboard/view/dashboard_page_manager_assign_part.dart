part of 'dashboard_page.dart';

extension _ManagerDashboardAssignHelpers on _ManagerDashboardState {
  Future<void> _pickAssignmentAttachment() async {
    if (_saving || _pickingAttachment || _submission.taskId != null) return;
    _setPickingAttachment(true);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    try {
      final file = await SafeFilePicker.openSingle(
        context: context,
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Task attachment',
            extensions: ManagerTaskAttachment.extensions,
          ),
        ],
      );
      if (file == null || !mounted) return;
      final length = await file.length();
      if (!ManagerTaskAttachment.accepts(file.name, length)) {
        throw FormatException(
          ar
              ? 'اختر ملفًا غير فارغ من الأنواع المسموحة بحجم لا يزيد عن 10 ميجابايت.'
              : 'Choose a supported, nonempty file up to 10 MB.',
        );
      }
      final bytes = await file.readAsBytes();
      if (!ManagerTaskAttachment.accepts(file.name, bytes.length)) {
        throw const FormatException('Invalid attachment size');
      }
      if (!mounted) return;
      _setAssignmentAttachment(
        ManagerTaskAttachment(
          name: file.name,
          bytes: bytes,
          mimeType: contentTypeFor(file.name),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${ar ? 'تعذر اختيار الملف' : 'Could not select file'}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) _setPickingAttachment(false);
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null) _setDueDate(picked);
  }

  Future<void> _assignTask() async {
    if (_saving || _pickingAttachment) return;
    if (_employeeId == null || _employeeId!.isEmpty) return;
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final estimate = double.tryParse(_estimateHours.text.trim());
    if (estimate == null || estimate <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.invalidEstimateHours),
        ),
      );
      return;
    }
    _setSaving(true);
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) {
        throw Exception(AppLocalizations.of(context)!.sessionMissing);
      }
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
      final dueDate = _dueDate;
      await _submission.submit(
        create: () async {
          final inserted = await client
              .from('employee_tasks')
              .insert({
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
                'due_date': dueDate == null
                    ? null
                    : DateTime(
                        dueDate.year,
                        dueDate.month,
                        dueDate.day,
                      ).toIso8601String().split('T').first,
                'status': 'todo',
                'progress': 0,
              })
              .select('id')
              .single();
          final taskId = inserted['id']?.toString();
          if (taskId != null && taskId.isNotEmpty) {
            await _appendTaskEvent(taskId: taskId, eventType: 'assigned');
          }
          if (taskId == null || taskId.isEmpty) {
            throw StateError('Missing assigned task ID');
          }
          return taskId;
        },
        attach: (taskId) async {
          final file = _assignmentAttachment;
          if (file == null) return;
          final added = await file.upload(
            client,
            tenantId: tenantId,
            taskId: taskId,
            userId: uid,
          );
          if (added) {
            await _appendTaskEvent(
              taskId: taskId,
              eventType: 'attachment_added',
              note: file.name,
            );
          }
        },
      );
      if (!mounted) return;
      _submission.clear();
      _assignmentAttachment = null;
      _title.clear();
      _description.clear();
      _estimateHours.text = '8';
      _selectedTemplateId = null;
      _priority = 'medium';
      _taskType = _visibleTaskCatalog.first;
      _dueDate = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.taskAssigned)),
      );
      _setSaving(false);
      _refreshData();
    } catch (e) {
      if (!mounted) return;
      _setSaving(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _submission.taskId != null
                ? (Localizations.localeOf(context).languageCode == 'ar'
                      ? 'المهمة اتسندت، لكن رفع المرفق فشل. اضغط إعادة رفع المرفق للمحاولة على نفس المهمة. $e'
                      : 'Task assigned, but attachment upload failed. Retry the attachment on the same task. $e')
                : AppLocalizations.of(context)!.assignFailed(e.toString()),
          ),
        ),
      );
    }
  }
}
