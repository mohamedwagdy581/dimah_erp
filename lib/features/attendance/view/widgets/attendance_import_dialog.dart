import 'dart:convert';
import 'dart:isolate';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/utils/safe_file_picker.dart';
import '../../../employees/domain/models/employee_lookup.dart';
import '../../domain/models/attendance_import_record.dart';
import '../cubit/attendance_cubit.dart';

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

  List<_PreviewRow> get _visibleRows {
    Iterable<_PreviewRow> v = _rows;
    switch (_filter) {
      case _ImportFilter.all:
        break;
      case _ImportFilter.late:
        v = v.where((e) => e.lateMinutes > 0);
        break;
      case _ImportFilter.overtime:
        v = v.where((e) => e.overtimeMinutes > 0);
        break;
      case _ImportFilter.unmatched:
        v = v.where((e) => !e.isMatched);
        break;
    }

    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      v = v.where((e) {
        return e.sourceName.toLowerCase().contains(q) ||
            e.sourcePersonId.toLowerCase().contains(q) ||
            (e.matchedEmployeeName?.toLowerCase().contains(q) ?? false);
      });
    }
    return v.toList();
  }

  Future<void> _pickAndParse() async {
    if (_parsing || _saving) return;
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

    try {
      final employees = await AppDI.employeesRepo.fetchEmployeeLookup(limit: 2000);
      final bytes = await file.readAsBytes();
      final rows = await _parseFile(bytes, employees);
      if (!mounted) return;
      setState(() {
        _rows = rows;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _parsing = false);
      }
    }
  }

  Future<List<_PreviewRow>> _parseFile(
    List<int> bytes,
    List<EmployeeLookup> employees,
  ) async {
    final text = _decodeCsv(bytes);
    final employeeMaps = employees
        .map((e) => {'id': e.id, 'full_name': e.fullName})
        .toList();
    final raw = await Isolate.run(
      () => _parseAttendanceCsvInIsolate(text, employeeMaps),
    );
    return raw
        .map(
          (e) => _PreviewRow(
            sourcePersonId: e['source_person_id'] as String,
            sourceName: e['source_name'] as String,
            date: DateTime.parse(e['date'] as String),
            checkIn: e['check_in'] == null
                ? null
                : DateTime.parse(e['check_in'] as String),
            checkOut: e['check_out'] == null
                ? null
                : DateTime.parse(e['check_out'] as String),
            matchedEmployeeId: e['matched_employee_id'] as String?,
            matchedEmployeeName: e['matched_employee_name'] as String?,
            lateMinutes: e['late_minutes'] as int,
            overtimeMinutes: e['overtime_minutes'] as int,
            status: e['status'] as String,
            notes: e['notes'] as String,
          ),
        )
        .toList();
  }

  String _decodeCsv(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }


  Future<void> _import() async {
    if (_saving || _parsing) return;
    final matched = _rows.where((e) => e.isMatched).toList();
    if (matched.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No matched employees to import.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = matched
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
          .toList();
      await context.read<AttendanceCubit>().importBatch(payload);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleRows;
    final matchedCount = _rows.where((e) => e.isMatched).length;
    final lateCount = _rows.where((e) => e.lateMinutes > 0).length;
    final overtimeCount = _rows.where((e) => e.overtimeMinutes > 0).length;
    final unmatchedCount = _rows.length - matchedCount;

    return AlertDialog(
      title: const Text('Import Attendance CSV'),
      content: SizedBox(
        width: 1180,
        height: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: (_parsing || _saving) ? null : _pickAndParse,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(_sourceName == null ? 'Choose CSV File' : 'Change File'),
                ),
                if (_sourceName != null)
                  Text(
                    _sourceName!,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                if (_rows.isNotEmpty) ...[
                  _smallStat('Rows', _rows.length.toString()),
                  _smallStat('Matched', matchedCount.toString(), color: Colors.green),
                  _smallStat('Late', lateCount.toString(), color: Colors.orange),
                  _smallStat(
                    'Overtime',
                    overtimeCount.toString(),
                    color: Colors.blue,
                  ),
                  _smallStat(
                    'Unmatched',
                    unmatchedCount.toString(),
                    color: Colors.red,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            if (_parsing || _saving) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 8),
            if (_rows.isNotEmpty) ...[
              Row(
                children: [
                  DropdownButton<_ImportFilter>(
                    value: _filter,
                    onChanged: (_parsing || _saving)
                        ? null
                        : (v) {
                            if (v == null) return;
                            setState(() => _filter = v);
                          },
                    items: const [
                      DropdownMenuItem(
                        value: _ImportFilter.all,
                        child: Text('All'),
                      ),
                      DropdownMenuItem(
                        value: _ImportFilter.late,
                        child: Text('Late'),
                      ),
                      DropdownMenuItem(
                        value: _ImportFilter.overtime,
                        child: Text('Overtime'),
                      ),
                      DropdownMenuItem(
                        value: _ImportFilter.unmatched,
                        child: Text('Unmatched'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 260,
                    child: TextField(
                      enabled: !_parsing && !_saving,
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        hintText: 'Search name/person id...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Person ID')),
                          DataColumn(label: Text('Name (CSV)')),
                          DataColumn(label: Text('Employee (ERP)')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Check In')),
                          DataColumn(label: Text('Check Out')),
                          DataColumn(label: Text('Late')),
                          DataColumn(label: Text('Overtime')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: visible.map((r) {
                          final rowColor = r.isMatched
                              ? (r.lateMinutes > 0
                                    ? Colors.orange.withValues(alpha: 0.08)
                                    : (r.overtimeMinutes > 0
                                          ? Colors.blue.withValues(alpha: 0.08)
                                          : Colors.transparent))
                              : Colors.red.withValues(alpha: 0.08);
                          return DataRow(
                            color: WidgetStatePropertyAll(rowColor),
                            cells: [
                              DataCell(Text(r.sourcePersonId)),
                              DataCell(Text(r.sourceName)),
                              DataCell(
                                Text(r.matchedEmployeeName ?? 'Not matched'),
                              ),
                              DataCell(Text(_fmtDate(r.date))),
                              DataCell(Text(_fmtTime(r.checkIn))),
                              DataCell(Text(_fmtTime(r.checkOut))),
                              DataCell(
                                Text(
                                  r.lateMinutes == 0 ? '-' : '${r.lateMinutes}m',
                                  style: TextStyle(
                                    color: r.lateMinutes > 0
                                        ? Colors.orange
                                        : null,
                                    fontWeight: r.lateMinutes > 0
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  r.overtimeMinutes == 0
                                      ? '-'
                                      : '${r.overtimeMinutes}m',
                                  style: TextStyle(
                                    color: r.overtimeMinutes > 0
                                        ? Colors.lightBlue
                                        : null,
                                    fontWeight: r.overtimeMinutes > 0
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                              DataCell(_statusChip(r)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text('Choose a CSV file to preview and import.'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: (_parsing || _saving)
              ? null
              : () => Navigator.pop(context, false),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: (_rows.isEmpty || _parsing || _saving) ? null : _import,
          icon: const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Importing...' : 'Import Matched Records'),
        ),
      ],
    );
  }

  Widget _statusChip(_PreviewRow row) {
    if (!row.isMatched) {
      return const Chip(
        label: Text('Unmatched'),
        backgroundColor: Color(0x33F44336),
      );
    }
    if (row.lateMinutes > 0) {
      return const Chip(
        label: Text('Late'),
        backgroundColor: Color(0x33FF9800),
      );
    }
    if (row.overtimeMinutes > 0) {
      return const Chip(
        label: Text('Overtime'),
        backgroundColor: Color(0x332196F3),
      );
    }
    return const Chip(
      label: Text('Present'),
      backgroundColor: Color(0x334CAF50),
    );
  }

  Widget _smallStat(String title, String value, {Color? color}) {
    return Chip(
      label: Text('$title: $value'),
      side: BorderSide(color: color ?? Colors.transparent),
      labelStyle: TextStyle(
        color: color ?? Colors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _fmtDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String _fmtTime(DateTime? d) {
    if (d == null) return '-';
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}:'
        '${d.second.toString().padLeft(2, '0')}';
  }
}

enum _ImportFilter { all, late, overtime, unmatched }

List<Map<String, dynamic>> _parseAttendanceCsvInIsolate(
  String text,
  List<Map<String, String>> employees,
) {
  final lines = const LineSplitter()
      .convert(text)
      .where((e) => e.trim().isNotEmpty)
      .toList();
  if (lines.isEmpty) {
    throw Exception('CSV file is empty.');
  }

  final headers = _parseCsvLineRaw(lines.first);
  final idxPersonId = headers.indexWhere((h) => h.trim() == 'Person ID');
  final idxName = headers.indexWhere((h) => h.trim() == 'Name');
  final idxTime = headers.indexWhere((h) => h.trim() == 'Time');
  final idxType = headers.indexWhere((h) => h.trim() == 'Attendance Status');
  if (idxPersonId < 0 || idxName < 0 || idxTime < 0 || idxType < 0) {
    throw Exception(
      'CSV header is invalid. Required: Person ID, Name, Time, Attendance Status.',
    );
  }

  final employeeByNorm = <String, Map<String, String>>{};
  for (final e in employees) {
    final n = _normRaw(e['full_name'] ?? '');
    if (n.isEmpty) continue;
    employeeByNorm[n] = e;
  }

  final grouped = <String, Map<String, dynamic>>{};
  for (var i = 1; i < lines.length; i++) {
    final cols = _parseCsvLineRaw(lines[i]);
    if (cols.length <= idxType) continue;

    final personId = cols[idxPersonId].replaceAll("'", '').trim();
    final sourceName = cols[idxName].trim();
    final time = DateTime.tryParse(cols[idxTime].trim());
    final status = cols[idxType].trim().toLowerCase();
    if (personId.isEmpty || sourceName.isEmpty || time == null) continue;

    final day = DateTime(time.year, time.month, time.day);
    final key = '$personId|${day.toIso8601String()}';
    final row = grouped.putIfAbsent(
      key,
      () => {
        'person_id': personId,
        'source_name': sourceName,
        'date': day.toIso8601String(),
        'check_in': null,
        'check_out': null,
      },
    );

    if (status.contains('check-in')) {
      final old = row['check_in'] == null
          ? null
          : DateTime.tryParse(row['check_in'] as String);
      if (old == null || time.isBefore(old)) {
        row['check_in'] = time.toIso8601String();
      }
    } else if (status.contains('check-out')) {
      final old = row['check_out'] == null
          ? null
          : DateTime.tryParse(row['check_out'] as String);
      if (old == null || time.isAfter(old)) {
        row['check_out'] = time.toIso8601String();
      }
    }
  }

  final out = <Map<String, dynamic>>[];
  for (final row in grouped.values) {
    final sourceName = row['source_name'] as String;
    final matched = _findMatchRaw(sourceName, employeeByNorm);
    final checkIn = row['check_in'] == null
        ? null
        : DateTime.parse(row['check_in'] as String);
    final checkOut = row['check_out'] == null
        ? null
        : DateTime.parse(row['check_out'] as String);
    final lateMinutes = _lateMinutesRaw(checkIn);
    final overtimeMinutes = _overtimeMinutesRaw(checkOut);
    final hasAnyPunch = checkIn != null || checkOut != null;
    final status = hasAnyPunch ? (lateMinutes > 0 ? 'late' : 'present') : 'absent';
    out.add({
      'source_person_id': row['person_id'],
      'source_name': sourceName,
      'date': row['date'],
      'check_in': row['check_in'],
      'check_out': row['check_out'],
      'matched_employee_id': matched?['id'],
      'matched_employee_name': matched?['full_name'],
      'late_minutes': lateMinutes,
      'overtime_minutes': overtimeMinutes,
      'status': status,
      'notes':
          'Imported from biometric CSV (Person ID: ${row['person_id'] as String})',
    });
  }

  out.sort((a, b) {
    final d = DateTime.parse(
      b['date'] as String,
    ).compareTo(DateTime.parse(a['date'] as String));
    if (d != 0) return d;
    return (a['source_name'] as String).compareTo(b['source_name'] as String);
  });
  return out;
}

List<String> _parseCsvLineRaw(String line) {
  final result = <String>[];
  final sb = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') {
      final nextIsQuote = i + 1 < line.length && line[i + 1] == '"';
      if (inQuotes && nextIsQuote) {
        sb.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (c == ',' && !inQuotes) {
      result.add(sb.toString().trim());
      sb.clear();
    } else {
      sb.write(c);
    }
  }
  result.add(sb.toString().trim());
  return result;
}

Map<String, String>? _findMatchRaw(
  String sourceName,
  Map<String, Map<String, String>> byNorm,
) {
  final n = _normRaw(sourceName);
  if (n.isEmpty) return null;
  final exact = byNorm[n];
  if (exact != null) return exact;

  final candidates = byNorm.entries
      .where(
        (e) => e.key.contains(n) || (n.length >= 4 && n.contains(e.key) && e.key.length >= 4),
      )
      .toList();
  if (candidates.length == 1) {
    return candidates.first.value;
  }
  return null;
}

String _normRaw(String v) {
  return v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]'), '').trim();
}

int _lateMinutesRaw(DateTime? checkIn) {
  if (checkIn == null) return 0;
  final start = DateTime(checkIn.year, checkIn.month, checkIn.day, 9, 15);
  if (!checkIn.isAfter(start)) return 0;
  return checkIn.difference(start).inMinutes;
}

int _overtimeMinutesRaw(DateTime? checkOut) {
  if (checkOut == null) return 0;
  final end = DateTime(checkOut.year, checkOut.month, checkOut.day, 17, 0);
  if (!checkOut.isAfter(end)) return 0;
  return checkOut.difference(end).inMinutes;
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
