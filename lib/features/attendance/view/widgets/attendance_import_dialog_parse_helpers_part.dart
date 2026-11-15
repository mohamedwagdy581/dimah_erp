part of 'attendance_import_dialog.dart';

Map<String, Map<String, String>> _indexEmployeesByDeviceNumber(
  List<Map<String, String>> employees,
) {
  final employeeByNumber = <String, Map<String, String>>{};
  for (final employee in employees) {
    final number = (employee['device_employee_number'] ?? '').trim();
    if (number.isEmpty) continue;
    if (employeeByNumber.containsKey(number)) {
      throw FormatException(
        'Duplicate device number in employee mappings: $number',
      );
    }
    employeeByNumber[number] = employee;
  }
  return employeeByNumber;
}

DateTime? _parseFlexibleDateTime(String value) {
  final text = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  // iVMS numeric export uses month/day/year, including ambiguous dates such as 10/1.
  // Do not guess day/month per row: it would mix September and October records.
  final numeric = RegExp(
    r'^(\d{1,2})/(\d{1,2})/(\d{4}) (\d{1,2}):(\d{2})(?::(\d{2}))?(?:\s*(AM|PM))?$',
    caseSensitive: false,
  ).firstMatch(text);
  if (numeric != null) {
    var hour = int.parse(numeric[4]!);
    final meridiem = numeric[7]?.toUpperCase();
    if (meridiem != null) {
      if (hour < 1 || hour > 12) return null;
      hour = hour % 12 + (meridiem == 'PM' ? 12 : 0);
    }
    return _validatedAttendanceDateTime(
      int.parse(numeric[3]!),
      int.parse(numeric[1]!),
      int.parse(numeric[2]!),
      hour,
      int.parse(numeric[5]!),
      int.parse(numeric[6] ?? '0'),
    );
  }

  final isoDate = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})(?:[ T]|$)',
  ).firstMatch(text);
  if (isoDate != null) {
    final isoTime = RegExp(
      r'[ T](\d{2}):(\d{2})(?::(\d{2}))?',
    ).firstMatch(text);
    if (_validatedAttendanceDateTime(
          int.parse(isoDate[1]!),
          int.parse(isoDate[2]!),
          int.parse(isoDate[3]!),
          int.parse(isoTime?[1] ?? '0'),
          int.parse(isoTime?[2] ?? '0'),
          int.parse(isoTime?[3] ?? '0'),
        ) ==
        null) {
      return null;
    }
    return DateTime.tryParse(text);
  }

  final named = RegExp(
    r'^(\d{1,2})[- /]([A-Za-z]{3,9})[- /](\d{2}|\d{4})(?: (\d{1,2}):(\d{2})(?::(\d{2}))?)?$',
  ).firstMatch(text);
  if (named != null) {
    var year = int.parse(named[3]!);
    if (named[3]!.length == 2) year += 2000;
    return _validatedAttendanceDateTime(
      year,
      _monthToNum(named[2]!),
      int.parse(named[1]!),
      int.parse(named[4] ?? '0'),
      int.parse(named[5] ?? '0'),
      int.parse(named[6] ?? '0'),
    );
  }
  return null;
}

DateTime? _validatedAttendanceDateTime(
  int year,
  int month,
  int day,
  int hour,
  int minute,
  int second,
) {
  if (year < 1 ||
      year > 9999 ||
      month < 1 ||
      month > 12 ||
      day < 1 ||
      day > 31 ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59 ||
      second < 0 ||
      second > 59) {
    return null;
  }
  final result = DateTime(year, month, day, hour, minute, second);
  return result.year == year && result.month == month && result.day == day
      ? result
      : null;
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
    if (idxDate >= 0 &&
        idxTime >= 0 &&
        cols.length > idxDate &&
        cols.length > idxTime) {
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

    if (personId.isEmpty || time == null) continue;
    // These events require separate overtime/break rules, not normal attendance.
    if (status.contains('overtime') || status.contains('break')) continue;

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

    final isIn =
        status.contains('in') || status == '0' || status.contains('entry');
    final isOut =
        status.contains('out') || status == '1' || status.contains('exit');

    if (isIn) {
      final old = row['check_in'] == null
          ? null
          : DateTime.tryParse(row['check_in'] as String);
      if (old == null || time.isBefore(old)) {
        row['check_in'] = time.toIso8601String();
      }
    } else if (isOut) {
      final old = row['check_out'] == null
          ? null
          : DateTime.tryParse(row['check_out'] as String);
      if (old == null || time.isAfter(old)) {
        row['check_out'] = time.toIso8601String();
      }
    }
  }
  return grouped;
}

List<Map<String, dynamic>> _buildPreviewMaps(
  Map<String, Map<String, dynamic>> grouped,
  Map<String, Map<String, String>> employeeByNumber,
) {
  final out = <Map<String, dynamic>>[];
  for (final row in grouped.values) {
    final sourceName = row['source_name'] as String;
    final matched = employeeByNumber[row['person_id']];
    final checkIn = row['check_in'] == null
        ? null
        : DateTime.parse(row['check_in'] as String);
    final checkOut = row['check_out'] == null
        ? null
        : DateTime.parse(row['check_out'] as String);

    final hasAnyPunch = checkIn != null || checkOut != null;
    if (!hasAnyPunch) continue;

    if (checkIn != null && checkOut != null && !checkOut.isAfter(checkIn)) {
      throw FormatException(
        'Check-out must follow check-in for Person ID ${row['person_id']}',
      );
    }
    // Shift rules are not configured: do not invent lateness or overtime.
    const lateMinutes = 0;
    const overtimeMinutes = 0;

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
      'notes':
          'Imported from biometric CSV (Person ID: ${row['person_id'] as String})',
    });
  }

  out.sort((a, b) {
    final dateCompare = DateTime.parse(
      b['date'] as String,
    ).compareTo(DateTime.parse(a['date'] as String));
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
