import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../../../employees/domain/models/employee_lookup.dart';
import '../cubit/attendance_cubit.dart';

part 'attendance_form_dialog_build_part.dart';
part 'attendance_form_dialog_helpers_part.dart';

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

  void _filter(String value) {
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
    if (_date == null) {
      setState(() => _dateError = 'Date is required');
      return;
    }

    final checkIn = _merge(_date, _checkIn);
    final checkOut = _merge(_date, _checkOut);
    if (checkIn != null && checkOut != null && checkOut.isBefore(checkIn)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-out must be after check-in')),
      );
      return;
    }

    await context.read<AttendanceCubit>().create(
          employeeId: _employeeId!,
          date: _date!,
          status: _status,
          checkIn: checkIn,
          checkOut: checkOut,
          notes: _notes.text.trim(),
        );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => buildAttendanceFormDialog(context);
}
