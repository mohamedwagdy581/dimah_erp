import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/utils/safe_file_picker.dart';
import '../../../employees/domain/models/employee_lookup.dart';
import '../../domain/models/leave_request.dart';
import '../cubit/leaves_cubit.dart';

class LeavesFormDialog extends StatefulWidget {
  const LeavesFormDialog({
    super.key,
    this.employeeId,
    this.initialLeave,
  });

  final String? employeeId;
  final LeaveRequest? initialLeave;

  @override
  State<LeavesFormDialog> createState() => _LeavesFormDialogState();
}

class _LeavesFormDialogState extends State<LeavesFormDialog> {
  static const int _maxFileBytes = 10 * 1024 * 1024; // 10 MB

  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  final _search = TextEditingController();
  final _fileName = ValueNotifier<String>('');
  List<EmployeeLookup> _employees = const [];
  List<EmployeeLookup> _filtered = const [];
  String? _employeeId;
  String _type = 'annual';
  DateTime? _start;
  DateTime? _end;
  String? _fileUrl;
  bool _uploading = false;
  bool _saving = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _employeeId = widget.initialLeave?.employeeId ?? widget.employeeId;
    if (widget.initialLeave != null) {
      _type = widget.initialLeave!.type;
      _start = widget.initialLeave!.startDate;
      _end = widget.initialLeave!.endDate;
      _notes.text = widget.initialLeave!.notes ?? '';
      _fileUrl = widget.initialLeave!.fileUrl;
      _fileName.value = (_fileUrl == null || _fileUrl!.isEmpty)
          ? ''
          : 'Attached file';
    }
    if (widget.employeeId == null && widget.initialLeave == null) {
      _loadEmployees();
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    _search.dispose();
    _fileName.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadEmployees({String? search}) async {
    if (widget.employeeId != null) return;
    final items = await AppDI.employeesRepo.fetchEmployeeLookup(
      search: search,
      limit: 200,
    );
    if (!mounted) return;
    setState(() {
      _employees = items;
      _filtered = items;
    });
  }

  void _filter(String v) {
    if (widget.employeeId != null) return;
    final q = v.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _employees);
      return;
    }
    setState(() {
      _filtered = _employees
          .where((e) => e.fullName.toLowerCase().contains(q))
          .toList();
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadEmployees(search: q);
    });
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _start ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _end ?? _start ?? now,
      firstDate: _start ?? DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null) setState(() => _end = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_start == null || _end == null) return;
    if (_uploading || _saving) return;

    setState(() => _saving = true);
    try {
      if (widget.initialLeave == null) {
        await context.read<LeavesCubit>().create(
          employeeId: _employeeId!,
          type: _type,
          startDate: _start!,
          endDate: _end!,
          fileUrl: _fileUrl,
          notes: _notes.text.trim(),
        );
      } else {
        await context.read<LeavesCubit>().resubmit(
          leaveId: widget.initialLeave!.id,
          employeeId: _employeeId!,
          type: _type,
          startDate: _start!,
          endDate: _end!,
          fileUrl: _fileUrl,
          notes: _notes.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialLeave == null ? 'Add Leave' : 'Resubmit Leave'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.employeeId == null) ...[
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    labelText: 'Search employee',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: _filter,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _employeeId,
                  items: _filtered
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _employeeId = v),
                  decoration: const InputDecoration(
                    labelText: 'Employee',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Employee is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: const [
                  DropdownMenuItem(value: 'annual', child: Text('Annual')),
                  DropdownMenuItem(value: 'sick', child: Text('Sick')),
                  DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'annual'),
                decoration: const InputDecoration(
                  labelText: 'Leave Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (_uploading || _saving) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _uploading
                        ? 'Uploading attachment...'
                        : 'Saving leave request...',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_uploading || _saving) ? null : _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Attach PDF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: _fileName,
                      builder: (context, name, _) {
                        return Text(
                          name.isEmpty ? 'No file' : name,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_uploading || _saving) ? null : _pickStart,
                      icon: const Icon(Icons.event),
                      label: Text(
                        _start == null
                            ? 'Start Date'
                            : '${_start!.year.toString().padLeft(4, '0')}-'
                                  '${_start!.month.toString().padLeft(2, '0')}-'
                                  '${_start!.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_uploading || _saving) ? null : _pickEnd,
                      icon: const Icon(Icons.event_available),
                      label: Text(
                        _end == null
                            ? 'End Date'
                            : '${_end!.year.toString().padLeft(4, '0')}-'
                                  '${_end!.month.toString().padLeft(2, '0')}-'
                                  '${_end!.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: (_uploading || _saving)
              ? null
              : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_uploading || _saving) ? null : _submit,
          child: Text(
            _saving
                ? 'Saving...'
                : (widget.initialLeave == null ? 'Save' : 'Resubmit'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    if (_uploading || _saving) return;
    try {
      final file = await SafeFilePicker.openSingle(
        context: context,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'PDF', extensions: ['pdf']),
        ],
      );
      if (file == null) return;
      setState(() => _uploading = true);

      final length = await file.length();
      if (length > _maxFileBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File is too large. Max size is 10 MB.')),
        );
        return;
      }

      final bytes = await file.readAsBytes();
      final client = Supabase.instance.client;
      final tenantId = await _fetchTenantId(client);
      final employeeId = _employeeId ?? 'unknown';
      final path =
          '$tenantId/$employeeId/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      await client.storage
          .from('leave_docs')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'application/pdf'),
          )
          .timeout(const Duration(minutes: 2));

      final url = client.storage.from('leave_docs').getPublicUrl(path);
      _fileUrl = url;
      _fileName.value = file.name;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('File upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<String> _fetchTenantId(SupabaseClient client) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    final me = await client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();
    return me['tenant_id'].toString();
  }
}
