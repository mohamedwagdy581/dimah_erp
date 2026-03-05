import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../../../employees/domain/models/employee_lookup.dart';
import '../cubit/attendance_cubit.dart';

class AttendanceFormDialog extends StatefulWidget {
  const AttendanceFormDialog({super.key});

  @override
  State<AttendanceFormDialog> createState() => _AttendanceFormDialogState();
}

class _AttendanceFormDialogState extends State<AttendanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  final _search = TextEditingController();
  Timer? _debounce;

  bool _loadingEmployees = false;
  String? _loadError;
  List<EmployeeLookup> _employees = const [];
  List<EmployeeLookup> _filtered = const [];
  String? _employeeId;
  DateTime? _date;
  String? _dateError;
  String _status = 'present';
  TimeOfDay? _checkIn;
  TimeOfDay? _checkOut;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _notes.dispose();
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadEmployees({String? search}) async {
    try {
      setState(() {
        _loadingEmployees = true;
        _loadError = null;
      });
      final items = await AppDI.employeesRepo.fetchEmployeeLookup(
        search: search,
        limit: 200,
      );
      if (!mounted) return;
      setState(() {
        _employees = items;
        _filtered = items;
        _loadingEmployees = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingEmployees = false;
        _loadError = e.toString();
      });
    }
  }

  void _filter(String v) {
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateError = null;
      });
    }
  }

  Future<void> _pickTime(bool isCheckIn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  DateTime? _merge(DateTime? date, TimeOfDay? t) {
    if (date == null || t == null) return null;
    return DateTime(date.year, date.month, date.day, t.hour, t.minute);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_date == null) {
      setState(() => _dateError = 'Date is required');
      return;
    }

    final ci = _merge(_date, _checkIn);
    final co = _merge(_date, _checkOut);
    if (ci != null && co != null && co.isBefore(ci)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-out must be after check-in')),
      );
      return;
    }

    await context.read<AttendanceCubit>().create(
      employeeId: _employeeId!,
      date: _date!,
      status: _status,
      checkIn: ci,
      checkOut: co,
      notes: _notes.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Attendance'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loadingEmployees) const LinearProgressIndicator(),
              if (_loadError != null) ...[
                const SizedBox(height: 8),
                Text(_loadError!, style: const TextStyle(color: Colors.red)),
              ],
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
              if (_filtered.isEmpty) ...[
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No employees found',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _date == null
                      ? 'Pick date'
                      : '${_date!.year.toString().padLeft(4, '0')}-'
                            '${_date!.month.toString().padLeft(2, '0')}-'
                            '${_date!.day.toString().padLeft(2, '0')}',
                ),
              ),
              if (_dateError != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _dateError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                items: const [
                  DropdownMenuItem(value: 'present', child: Text('Present')),
                  DropdownMenuItem(value: 'late', child: Text('Late')),
                  DropdownMenuItem(value: 'absent', child: Text('Absent')),
                  DropdownMenuItem(value: 'on_leave', child: Text('On Leave')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'present'),
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(true),
                      child: Text(
                        _checkIn == null
                            ? 'Check In'
                            : _checkIn!.format(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(false),
                      child: Text(
                        _checkOut == null
                            ? 'Check Out'
                            : _checkOut!.format(context),
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
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
