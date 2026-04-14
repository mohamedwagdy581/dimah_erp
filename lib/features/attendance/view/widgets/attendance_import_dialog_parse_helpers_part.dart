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

DateTime? _parseFlexibleDateTime(String value) {
  var d = DateTime.tryParse(value);
  if (d != null) return d;

  // Manual parsing for formats like "4-Mar-26 13:46" or "10-Oct-2023"
  try {
    final cleanValue = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    final parts = cleanValue.split(RegExp(r'[\s\-\/]'));
    if (parts.length >= 3) {
      int? day = int.tryParse(parts[0]);
      int? year = int.tryParse(parts[2]);
      int month = _monthToNum(parts[1]);

      if (day != null && year != null && month > 0) {
        if (year < 100) year += 2000; // Handle 2-digit year "26" -> 2026
        
        int hour = 0;
        int minute = 0;
        if (parts.length >= 4) {
          final timeParts = parts[3].split(':');
          hour = int.tryParse(timeParts[0]) ?? 0;
          if (timeParts.length > 1) minute = int.tryParse(timeParts[1]) ?? 0;
        }
        return DateTime(year, month, day, hour, minute);
      }
    }
  } catch (_) {}
  return null;
}

int _monthToNum(String m) {
  m = m.toLowerCase();
  if (m.startsWith('jan')) return 1;
  if (m.startsWith('feb')) return 2;
  if (m.startsWith('mar')) return 3;
  if (m.startsWith('apr')) return 4;
  if (m.startsWith('may')) return 5;
  if (m.startsWith('jun')) return 6;
  if (m.startsWith('jul')) return 7;
  if (m.startsWith('aug')) return 8;
  if (m.startsWith('sep')) return 9;
  if (m.startsWith('oct')) return 10;
  if (m.startsWith('nov')) return 11;
  if (m.startsWith('dec')) return 12;
  return 0;
}

Map<String, Map<String, dynamic>> _groupAttendanceRows(
  List<String> lines,
  int idxPersonId,
  int idxName,
  int idxDate,
  int idxTime,
  int idxType,
) {
  final grouped = <String, Map<String, dynamic>>{};
  for (var i = 1; i < lines.length; i++) {
    final cols = _parseCsvLineRaw(lines[i]);
    
    final personId = idxPersonId >= 0 && cols.length > idxPersonId 
        ? cols[idxPersonId].replaceAll("'", '').trim() 
        : '';
    final sourceName = idxName >= 0 && cols.length > idxName 
        ? cols[idxName].trim() 
        : '';
    
    String? combinedTimeStr;
    if (idxDate >= 0 && idxTime >= 0 && cols.length > idxDate && cols.length > idxTime) {
       combinedTimeStr = '${cols[idxDate].trim()} ${cols[idxTime].trim()}';
    } else if (idxTime >= 0 && cols.length > idxTime) {
       combinedTimeStr = cols[idxTime].trim();
    } else if (idxDate >= 0 && cols.length > idxDate) {
       combinedTimeStr = cols[idxDate].trim();
    }

    if (combinedTimeStr == null || combinedTimeStr.isEmpty) continue;
    
    final time = _parseFlexibleDateTime(combinedTimeStr);
    final status = idxType >= 0 && cols.length > idxType 
        ? cols[idxType].trim().toLowerCase() 
        : '';
    
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

    final isIn = status.contains('in') || status == '0' || status.contains('entry');
    final isOut = status.contains('out') || status == '1' || status.contains('exit');

    if (isIn) {
      final old = row['check_in'] == null ? null : DateTime.tryParse(row['check_in'] as String);
      if (old == null || time.isBefore(old)) row['check_in'] = time.toIso8601String();
    } else if (isOut) {
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
    
    final hasAnyPunch = checkIn != null || checkOut != null;
    if (!hasAnyPunch) continue;

    final lateMinutes = _lateMinutesRaw(checkIn);
    final overtimeMinutes = _overtimeMinutesRaw(checkOut);

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
      'status': lateMinutes > 0 ? 'late' : 'present',
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
