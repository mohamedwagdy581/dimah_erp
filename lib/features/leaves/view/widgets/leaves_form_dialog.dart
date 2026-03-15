import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/utils/safe_file_picker.dart';
import '../../../employees/domain/models/employee_lookup.dart';
import '../../domain/models/leave_request.dart';
import '../cubit/leaves_cubit.dart';

part 'leaves_form_dialog_build_part.dart';
part 'leaves_form_dialog_helpers_part.dart';
part 'leaves_form_dialog_upload_part.dart';

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
  static const int _maxFileBytes = 10 * 1024 * 1024;

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
      _fileName.value = (_fileUrl == null || _fileUrl!.isEmpty) ? '' : 'Attached file';
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

  void _filter(String value) {
    if (widget.employeeId != null) return;
    final query = value.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filtered = _employees);
    } else {
      setState(() {
        _filtered = _employees
            .where((e) => e.fullName.toLowerCase().contains(query))
            .toList();
      });
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadEmployees(search: query);
    });
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => buildLeavesFormDialog(context);
}
