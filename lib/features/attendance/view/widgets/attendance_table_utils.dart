import 'package:flutter/material.dart';

import '../../domain/models/attendance_record.dart';

String formatAttendanceDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

String formatAttendanceTime(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

int attendanceLateMinutes(DateTime? checkIn) {
  if (checkIn == null) {
    return 0;
  }
  final workStart = DateTime(checkIn.year, checkIn.month, checkIn.day, 9, 15);
  if (!checkIn.isAfter(workStart)) {
    return 0;
  }
  return checkIn.difference(workStart).inMinutes;
}

int attendanceOvertimeMinutes(DateTime? checkOut) {
  if (checkOut == null) {
    return 0;
  }
  final workEnd = DateTime(checkOut.year, checkOut.month, checkOut.day, 17, 0);
  if (!checkOut.isAfter(workEnd)) {
    return 0;
  }
  return checkOut.difference(workEnd).inMinutes;
}

Color attendanceRowColor(AttendanceRecord record) {
  final lateMinutes = attendanceLateMinutes(record.checkIn);
  final overtimeMinutes = attendanceOvertimeMinutes(record.checkOut);
  if (lateMinutes > 0) {
    return Colors.orange.withValues(alpha: 0.06);
  }
  if (overtimeMinutes > 0) {
    return Colors.blue.withValues(alpha: 0.06);
  }
  return Colors.transparent;
}
