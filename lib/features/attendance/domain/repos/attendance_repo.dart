import '../models/attendance_record.dart';
import '../models/attendance_import_record.dart';

abstract class AttendanceRepo {
  Future<({List<AttendanceRecord> items, int total})> fetchAttendance({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    DateTime? date,
    String? employeeId,
    String sortBy,
    bool ascending,
  });

  Future<void> createAttendance({
    required String employeeId,
    required DateTime date,
    required String status,
    DateTime? checkIn,
    DateTime? checkOut,
    String? notes,
  });

  Future<void> createCorrectionRequest({
    required String recordId,
    required String employeeId,
    required DateTime date,
    DateTime? proposedCheckIn,
    DateTime? proposedCheckOut,
    String? reason,
  });

  Future<void> upsertAttendanceBatch(List<AttendanceImportRecord> records);
}
