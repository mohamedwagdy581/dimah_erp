import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:file_selector/file_selector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/safe_file_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repos/my_tasks_repo.dart';
import '../widgets/my_tasks/task_card.dart';
import '../widgets/my_tasks/task_filters_bar.dart';
import '../widgets/my_tasks/task_formatters.dart';
import '../widgets/my_tasks/task_filters_utils.dart';
import '../widgets/my_tasks/task_review_dialog.dart';
import '../widgets/my_tasks/employee_tasks_view.dart';
import '../widgets/my_tasks/employee_task_details.dart';

class MyTasksSection extends StatefulWidget {
  const MyTasksSection({
    super.key,
    required this.employeeId,
    this.employeeDesign = false,
    this.repo,
  });

  final String employeeId;
  final bool employeeDesign;
  final MyTasksRepo? repo;

  @override
  State<MyTasksSection> createState() => _MyTasksSectionState();
}

class _MyTasksSectionState extends State<MyTasksSection> {
  late final MyTasksRepo _repo;
  late Future<List<Map<String, dynamic>>> _future;
  String _statusFilter = 'all';
  final _selectedTask = ValueNotifier<Map<String, dynamic>>({});
  final _actionBusy = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _repo = widget.repo ?? MyTasksRepo(Supabase.instance.client);
    _future = _repo.loadTasks(
      widget.employeeId,
      loadAll: widget.employeeDesign,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _repo.loadTasks(
        widget.employeeId,
        loadAll: widget.employeeDesign,
      );
    });
    final tasks = await _future;
    if (!mounted) return;
    final selectedId = _selectedTask.value['id'];
    for (final task in tasks) {
      if (task['id'] == selectedId) _selectedTask.value = task;
    }
  }

  @override
  void didUpdateWidget(covariant MyTasksSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.employeeId != oldWidget.employeeId) {
      _selectedTask.value = {};
      _future = _repo.loadTasks(
        widget.employeeId,
        loadAll: widget.employeeDesign,
      );
    }
  }

  @override
  void dispose() {
    _selectedTask.dispose();
    _actionBusy.dispose();
    super.dispose();
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_actionBusy.value) return;
    _actionBusy.value = true;
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar
                ? 'تعذّر تنفيذ العملية؛ حاول مجددًا'
                : 'Unable to complete the action. Try again.',
          ),
        ),
      );
    } finally {
      if (mounted) _actionBusy.value = false;
    }
  }

  Widget _taskCard(Map<String, dynamic> task) => TaskCard(
    employeeLayout: widget.employeeDesign,
    key: ValueKey('${task['id']}:${task['status']}:${task['progress']}'),
    task: task,
    onStatusChanged: (value) => _runAction(
      () => _updateTask(task, value, (task['progress'] as num?)?.toInt() ?? 0),
    ),
    onProgressChanged: (value) => _runAction(
      () => _updateTask(
        task,
        value >= 100 ? 'done' : (task['status'] ?? 'todo').toString(),
        value,
      ),
    ),
    onRequestReview: () => _runAction(() => _requestReview(task)),
    onAttachFile: () =>
        _runAction(() => _pickAttachment(task['id'].toString())),
    onLogHours: () => _runAction(() => _logHours(task)),
    onStartTimer: () => _runAction(() => _startTimer(task)),
    onStopTimer: () => _runAction(() => _stopTimer(task)),
    onOpenAttachment: (url) => _runAction(() => _openAttachment(url)),
  );

  Future<void> _openTask(Map<String, dynamic> task) async {
    _selectedTask.value = task;
    if (widget.employeeDesign) return;
    final t = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 720,
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.myTasks,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: ValueListenableBuilder<Map<String, dynamic>>(
                    valueListenable: _selectedTask,
                    builder: (context, current, _) =>
                        ValueListenableBuilder<bool>(
                          valueListenable: _actionBusy,
                          builder: (context, busy, _) => Column(
                            children: [
                              if (busy) const LinearProgressIndicator(),
                              AbsorbPointer(
                                absorbing: busy,
                                child: _taskCard(current),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.employeeDesign) return _buildTasks(context);
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: _selectedTask,
      builder: (context, current, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: current.isNotEmpty,
              child: TickerMode(
                enabled: current.isEmpty,
                child: _buildTasks(context),
              ),
            ),
            if (current.isNotEmpty)
              Positioned.fill(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _actionBusy,
                  builder: (context, busy, _) => EmployeeTaskDetails(
                    task: current,
                    busy: busy,
                    onBack: () => _selectedTask.value = {},
                    onStatusChanged: (value) => _runAction(
                      () => _updateTask(
                        current,
                        value,
                        (current['progress'] as num?)?.toInt() ?? 0,
                      ),
                    ),
                    onProgressChanged: (value) => _runAction(
                      () => _updateTask(
                        current,
                        value >= 100
                            ? 'done'
                            : (current['status'] ?? 'todo').toString(),
                        value,
                      ),
                    ),
                    onRequestReview: () =>
                        _runAction(() => _requestReview(current)),
                    onAttachFile: () => _runAction(
                      () => _pickAttachment(current['id'].toString()),
                    ),
                    onLogHours: () => _runAction(() => _logHours(current)),
                    onStartTimer: () => _runAction(() => _startTimer(current)),
                    onStopTimer: () => _runAction(() => _stopTimer(current)),
                    onOpenAttachment: (url) =>
                        _runAction(() => _openAttachment(url)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTasks(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (widget.employeeDesign) {
          return EmployeeTasksView(
            tasks: snapshot.data ?? const [],
            loading: snapshot.connectionState == ConnectionState.waiting,
            failed: snapshot.hasError,
            error: snapshot.error,
            onRefresh: () => _runAction(_reload),
            onOpen: _openTask,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState();
        }
        if (snapshot.hasError) {
          return AppFailureState(error: snapshot.error);
        }
        final allItems = snapshot.data ?? const [];
        final items = applyTaskFilter(allItems, _statusFilter);
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.isEmpty ? 2 : items.length + 1,
          separatorBuilder: (_, index) => index == 0
              ? const SizedBox(height: 12)
              : const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return TaskFiltersBar(
                currentFilter: _statusFilter,
                totalCount: allItems.length,
                todoCount: countByTaskFilter(allItems, 'todo'),
                inProgressCount: countByTaskFilter(allItems, 'in_progress'),
                doneCount: countByTaskFilter(allItems, 'done'),
                reviewCount: countByTaskFilter(allItems, 'review_pending'),
                qaCount: countByTaskFilter(allItems, 'qa_pending'),
                onChanged: (value) => setState(() {
                  _statusFilter = value;
                }),
              );
            }
            if (items.isEmpty) {
              return Center(
                child: AppEmptyState(title: t.noTasksAssigned, compact: false),
              );
            }
            final task = items[index - 1];
            return TaskCard(
              task: task,
              onStatusChanged: (value) => _updateTask(
                task,
                value,
                ((task['progress'] as num?)?.toInt() ?? 0),
              ),
              onProgressChanged: (value) => _updateTask(
                task,
                value >= 100 ? 'done' : (task['status'] ?? 'todo').toString(),
                value,
              ),
              onRequestReview: () => _requestReview(task),
              onAttachFile: () => _pickAttachment(task['id'].toString()),
              onLogHours: () => _logHours(task),
              onStartTimer: () => _startTimer(task),
              onStopTimer: () => _stopTimer(task),
              onOpenAttachment: _openAttachment,
            );
          },
        );
      },
    );
  }

  Future<void> _updateTask(
    Map<String, dynamic> task,
    String status,
    int progress,
  ) async {
    await _repo.updateTask(
      id: task['id'].toString(),
      status: status,
      progress: progress,
    );
    if (!mounted) return;
    await _reload();
  }

  Future<void> _requestReview(Map<String, dynamic> task) async {
    final t = AppLocalizations.of(context)!;
    final note = await showTaskReviewDialog(context);
    if (note == null) return;
    if (note.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.reviewNoteRequired)));
      return;
    }
    await _repo.requestReview(taskId: task['id'].toString(), note: note);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.reviewRequestSent)));
    await _reload();
  }

  Future<void> _logHours(Map<String, dynamic> task) async {
    final t = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final hoursController = TextEditingController();
    final noteController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تسجيل ساعات' : 'Log Hours'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hoursController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: isArabic ? 'الساعات المسجلة' : 'Logged Hours',
                  hintText: '2.5',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(labelText: t.noteOptional),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.save),
          ),
        ],
      ),
    );
    if (result != true) return;

    final hours = double.tryParse(hoursController.text.trim());
    if (hours == null || hours <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'يرجى إدخال عدد ساعات صحيح.'
                : 'Please enter a valid logged hours value.',
          ),
        ),
      );
      return;
    }

    await _repo.logHours(
      taskId: task['id'].toString(),
      employeeId: widget.employeeId,
      hours: hours,
      note: noteController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic ? 'تم تسجيل الساعات بنجاح' : 'Hours logged successfully',
        ),
      ),
    );
    await _reload();
  }

  Future<void> _startTimer(Map<String, dynamic> task) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    await _repo.startTimer(taskId: task['id'].toString());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isArabic ? 'تم بدء المؤقت' : 'Timer started')),
    );
    await _reload();
  }

  Future<void> _stopTimer(Map<String, dynamic> task) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final noteController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'إيقاف المؤقت' : 'Stop Timer'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: isArabic ? 'ملاحظة (اختياري)' : 'Note (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isArabic ? 'إيقاف' : 'Stop'),
          ),
        ],
      ),
    );
    if (result != true) return;

    final hours = await _repo.stopTimer(
      taskId: task['id'].toString(),
      employeeId: widget.employeeId,
      note: noteController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'تم إيقاف المؤقت وتسجيل ${hours.toStringAsFixed(2)} ساعة.'
              : 'Timer stopped. $hours h logged.',
        ),
      ),
    );
    await _reload();
  }

  Future<void> _pickAttachment(String taskId) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await SafeFilePicker.openSingle(
        context: context,
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Attachments',
            extensions: [
              'pdf',
              'jpg',
              'jpeg',
              'png',
              'doc',
              'docx',
              'xlsx',
              'xls',
            ],
          ),
        ],
      );
      if (file == null) return;
      await _repo.addAttachment(
        taskId: taskId,
        fileName: file.name,
        bytes: await file.readAsBytes(),
        mimeType: contentTypeFor(file.name),
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(t.attachmentUploaded)));
      await _reload();
    } catch (e) {
      debugPrint('TASK_ATTACHMENT_UPLOAD_ERROR: $e');
      debugPrint('TASK_ATTACHMENT_UPLOAD_STACK: ${StackTrace.current}');
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(t.fileUploadFailed(e.toString()))),
      );
    }
  }

  Future<void> _openAttachment(String url) async {
    if (url.trim().isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
