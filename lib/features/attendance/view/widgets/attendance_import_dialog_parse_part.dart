part of 'attendance_import_dialog.dart';

extension _AttendanceImportDialogParse on _AttendanceImportDialogState {
  Future<List<_PreviewRow>> _parseFile(
    List<int> bytes,
    List<EmployeeLookup> employees,
  ) async {
    final csvText = _decodeCsvBytes(bytes);
    final employeeMaps = employees
        .map((e) => {'id': e.id, 'full_name': e.fullName})
        .toList();

    final raw = await Isolate.run(
      () => _parseAttendanceCsvInIsolate(csvText, employeeMaps),
    );

    return raw
        .map(
          (e) => _PreviewRow(
            sourcePersonId: e['source_person_id'] as String,
            sourceName: e['source_name'] as String,
            date: DateTime.parse(e['date'] as String),
            checkIn: e['check_in'] == null ? null : DateTime.parse(e['check_in'] as String),
            checkOut: e['check_out'] == null ? null : DateTime.parse(e['check_out'] as String),
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

  String _decodeCsvBytes(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }
}

List<Map<String, dynamic>> _parseAttendanceCsvInIsolate(
  String text,
  List<Map<String, String>> employees,
) {
  final lines = const LineSplitter()
      .convert(text)
      .where((e) => e.trim().isNotEmpty)
      .toList();
  if (lines.isEmpty) throw Exception('CSV file is empty.');

  final headers = _parseCsvLineRaw(lines.first);
  
  // Try to find indices with more flexible naming
  final idxPersonId = headers.indexWhere((h) => h.trim().toLowerCase() == 'person id');
  final idxName = headers.indexWhere((h) => h.trim().toLowerCase() == 'name');
  final idxType = headers.indexWhere((h) => h.trim().toLowerCase() == 'attendance status');
  
  // Check for split Date/Time or combined Time column
  final idxDate = headers.indexWhere((h) => h.trim().toLowerCase() == 'date');
  final idxTime = headers.indexWhere((h) => h.trim().toLowerCase() == 'time');

  if (idxPersonId < 0 || idxName < 0 || idxType < 0) {
    throw Exception('CSV header is invalid. Required: Person ID, Name, Attendance Status.');
  }

  // Ensure we have some form of time information
  if (idxTime < 0 && idxDate < 0) {
    throw Exception('CSV must have at least a "Time" column or "Date" and "Time" columns.');
  }

  final employeeByNorm = _indexEmployeesByNormalizedName(employees);
  
  // Use a modified grouping function that handles split columns
  final grouped = _groupAttendanceRows(
    lines, 
    idxPersonId, 
    idxName, 
    idxDate, 
    idxTime, 
    idxType
  );

  return _buildPreviewMaps(grouped, employeeByNorm);
}
