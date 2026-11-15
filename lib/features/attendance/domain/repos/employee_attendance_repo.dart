import '../models/attendance_record.dart';

class EmployeeAttendanceMonth {
  const EmployeeAttendanceMonth({
    required this.records,
    this.pendingRecordIds = const {},
    this.correctionsReady = true,
  });
  final List<AttendanceRecord> records;
  final Set<String> pendingRecordIds;
  final bool correctionsReady;
}

abstract class EmployeeAttendanceRepo {
  Future<EmployeeAttendanceMonth> fetchMonth({
    required String employeeId,
    required DateTime month,
  });
  Future<void> requestCorrection({
    required AttendanceRecord record,
    required DateTime checkIn,
    required DateTime checkOut,
    required String reason,
  });
}
