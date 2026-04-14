import 'dart:convert';
import 'dart:isolate';
import 'dart:developer' as dev;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/utils/safe_file_picker.dart';
import '../../../employees/domain/models/employee_lookup.dart';
import '../../domain/models/attendance_import_record.dart';
import '../cubit/attendance_cubit.dart';

part 'attendance_import_dialog_filters_part.dart';
part 'attendance_import_dialog_parse_part.dart';
part 'attendance_import_dialog_parse_helpers_part.dart';
part 'attendance_import_dialog_preview_part.dart';
part 'attendance_import_dialog_table_part.dart';

class AttendanceImportDialog extends StatefulWidget {
  const AttendanceImportDialog({super.key});

  @override
  State<AttendanceImportDialog> createState() => _AttendanceImportDialogState();
}

class _AttendanceImportDialogState extends State<AttendanceImportDialog> {
  bool _parsing = false;
  bool _saving = false;
  String? _error;
  String? _sourceName;
  String _search = '';
  _ImportFilter _filter = _ImportFilter.all;
  List<_PreviewRow> _rows = const [];

  void _setFilter(_ImportFilter value) => setState(() => _filter = value);

  void _setSearch(String value) => setState(() => _search = value);

  Future<void> _pickAndParse() async {
    if (_parsing || _saving) return;
    
    try {
      final file = await SafeFilePicker.openSingle(
        context: context,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'CSV', extensions: ['csv']),
          XTypeGroup(label: 'Text', extensions: ['txt']),
        ],
      );
      if (file == null) return;

      setState(() {
        _parsing = true;
        _error = null;
        _sourceName = file.name;
        _rows = const [];
      });

      dev.log('Starting fetchEmployeeLookup...');
      final employees = await AppDI.employeesRepo.fetchEmployeeLookup(limit: 5000);
      dev.log('Fetched ${employees.length} employees.');

      dev.log('Reading file bytes...');
      final bytes = await file.readAsBytes();
      dev.log('Read ${bytes.length} bytes.');

      dev.log('Calling _parseFile...');
      final rows = await _parseFile(bytes, employees);
      dev.log('Parsed ${rows.length} rows.');

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _parsing = false;
      });
      
      if (rows.isEmpty) {
        setState(() => _error = 'No valid attendance records found in the file.');
      }
    } catch (e, stack) {
      dev.log('Error during parse: $e', stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _error = 'Failed to parse file: ${e.toString()}';
        _parsing = false;
      });
    }
  }

  Future<void> _import() async {
    if (_saving || _parsing) return;
    final matched = _rows.where((e) => e.isMatched).toList();
    if (matched.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matched employees to import.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<AttendanceCubit>().importBatch(
            matched
                .map(
                  (e) => AttendanceImportRecord(
                    employeeId: e.matchedEmployeeId!,
                    date: e.date,
                    status: e.status,
                    checkIn: e.checkIn,
                    checkOut: e.checkOut,
                    notes: e.notes,
                  ),
                )
                .toList(),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => buildAttendanceImportDialog(context);
}

class _PreviewRow {
  const _PreviewRow({
    required this.sourcePersonId,
    required this.sourceName,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.matchedEmployeeId,
    required this.matchedEmployeeName,
    required this.lateMinutes,
    required this.overtimeMinutes,
    required this.status,
    required this.notes,
  });

  final String sourcePersonId;
  final String sourceName;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? matchedEmployeeId;
  final String? matchedEmployeeName;
  final int lateMinutes;
  final int overtimeMinutes;
  final String status;
  final String notes;

  bool get isMatched => matchedEmployeeId != null;
}

enum _ImportFilter { all, late, overtime, unmatched }
