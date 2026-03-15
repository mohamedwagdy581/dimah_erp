part of 'attendance_import_dialog.dart';

Map<String, Map<String, String>> _indexEmployeesByNormalizedName(
  List<Map<String, String>> employees,
) {
  final employeeByNorm = <String, Map<String, String>>{};
  for (final employee in employees) {
    final normalized = _normRaw(employee['full_name'] ?? '');
    if (normalized.isEmpty) continue;
    employeeByNorm[normalized] = employee;
  }
  return employeeByNorm;
}

Map<String, Map<String, dynamic>> _groupAttendanceRows(
  List<String> lines,
  int idxPersonId,
  int idxName,
  int idxTime,
  int idxType,
) {
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
      final old = row['check_in'] == null ? null : DateTime.tryParse(row['check_in'] as String);
      if (old == null || time.isBefore(old)) row['check_in'] = time.toIso8601String();
    } else if (status.contains('check-out')) {
      final old = row['check_out'] == null ? null : DateTime.tryParse(row['check_out'] as String);
      if (old == null || time.isAfter(old)) row['check_out'] = time.toIso8601String();
    }
  }
  return grouped;
}

List<Map<String, dynamic>> _buildPreviewMaps(
  Map<String, Map<String, dynamic>> grouped,
  Map<String, Map<String, String>> employeeByNorm,
) {
  final out = <Map<String, dynamic>>[];
  for (final row in grouped.values) {
    final sourceName = row['source_name'] as String;
    final matched = _findMatchRaw(sourceName, employeeByNorm);
    final checkIn = row['check_in'] == null ? null : DateTime.parse(row['check_in'] as String);
    final checkOut = row['check_out'] == null ? null : DateTime.parse(row['check_out'] as String);
    final lateMinutes = _lateMinutesRaw(checkIn);
    final overtimeMinutes = _overtimeMinutesRaw(checkOut);
    final hasAnyPunch = checkIn != null || checkOut != null;
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
      'status': hasAnyPunch ? (lateMinutes > 0 ? 'late' : 'present') : 'absent',
      'notes': 'Imported from biometric CSV (Person ID: ${row['person_id'] as String})',
    });
  }

  out.sort((a, b) {
    final dateCompare = DateTime.parse(b['date'] as String).compareTo(DateTime.parse(a['date'] as String));
    if (dateCompare != 0) return dateCompare;
    return (a['source_name'] as String).compareTo(b['source_name'] as String);
  });
  return out;
}

List<String> _parseCsvLineRaw(String line) {
  final result = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') {
      final nextIsQuote = i + 1 < line.length && line[i + 1] == '"';
      if (inQuotes && nextIsQuote) {
        buffer.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == ',' && !inQuotes) {
      result.add(buffer.toString().trim());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  result.add(buffer.toString().trim());
  return result;
}

Map<String, String>? _findMatchRaw(
  String sourceName,
  Map<String, Map<String, String>> byNorm,
) {
  final normalized = _normRaw(sourceName);
  if (normalized.isEmpty) return null;
  final exact = byNorm[normalized];
  if (exact != null) return exact;

  final candidates = byNorm.entries.where((e) {
    return e.key.contains(normalized) ||
        (normalized.length >= 4 && normalized.contains(e.key) && e.key.length >= 4);
  }).toList();
  return candidates.length == 1 ? candidates.first.value : null;
}

String _normRaw(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9؀-ۿ]'), '').trim();
}

int _lateMinutesRaw(DateTime? checkIn) {
  if (checkIn == null) return 0;
  final start = DateTime(checkIn.year, checkIn.month, checkIn.day, 9, 15);
  return checkIn.isAfter(start) ? checkIn.difference(start).inMinutes : 0;
}

int _overtimeMinutesRaw(DateTime? checkOut) {
  if (checkOut == null) return 0;
  final end = DateTime(checkOut.year, checkOut.month, checkOut.day, 17, 0);
  return checkOut.isAfter(end) ? checkOut.difference(end).inMinutes : 0;
}
