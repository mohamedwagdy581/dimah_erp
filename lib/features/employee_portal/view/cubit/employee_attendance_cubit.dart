import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_error.dart';
import '../../../attendance/domain/models/attendance_record.dart';
import '../../../attendance/domain/repos/employee_attendance_repo.dart';

DateTime attendanceMonth(DateTime date) => DateTime(date.year, date.month);
Duration? recordedAttendanceDuration(AttendanceRecord record) {
  if (record.checkIn == null ||
      record.checkOut == null ||
      record.checkOut!.isBefore(record.checkIn!)) {
    return null;
  }
  return record.checkOut!.difference(record.checkIn!);
}

class EmployeeAttendanceState {
  const EmployeeAttendanceState({
    required this.month,
    this.records = const [],
    this.pending = const {},
    this.loading = false,
    this.saving = false,
    this.error,
    this.correctionsReady = false,
  });
  final DateTime month;
  final List<AttendanceRecord> records;
  final Set<String> pending;
  final bool loading, saving, correctionsReady;
  final String? error;
  int get recordedDays => records
      .map((r) => '${r.date.year}-${r.date.month}-${r.date.day}')
      .toSet()
      .length;
  int daysWithStatus(String status) => records
      .where((r) => r.status == status)
      .map((r) => '${r.date.year}-${r.date.month}-${r.date.day}')
      .toSet()
      .length;
  Duration get recordedDuration {
    final complete =
        records.where((r) => recordedAttendanceDuration(r) != null).toList()
          ..sort((a, b) => a.checkIn!.compareTo(b.checkIn!));
    DateTime? start, end;
    var total = Duration.zero;
    for (final record in complete) {
      if (start == null) {
        start = record.checkIn;
        end = record.checkOut;
      } else if (!record.checkIn!.isAfter(end!)) {
        if (record.checkOut!.isAfter(end)) end = record.checkOut;
      } else {
        total += end.difference(start);
        start = record.checkIn;
        end = record.checkOut;
      }
    }
    return start == null ? total : total + end!.difference(start);
  }
}

class EmployeeAttendanceCubit extends Cubit<EmployeeAttendanceState> {
  EmployeeAttendanceCubit(this.repo, {required this.employeeId, DateTime? now})
    : super(
        EmployeeAttendanceState(month: attendanceMonth(now ?? DateTime.now())),
      );
  final EmployeeAttendanceRepo repo;
  final String employeeId;
  int _load = 0;
  Future<void> load({DateTime? month}) async {
    if (isClosed || state.saving) return;
    final version = ++_load;
    final selected = attendanceMonth(month ?? state.month);
    emit(EmployeeAttendanceState(month: selected, loading: true));
    try {
      final data = await repo.fetchMonth(
        employeeId: employeeId,
        month: selected,
      );
      if (isClosed || version != _load) return;
      // Keep server filtering as the authority; avoid leaking a stale account response.
      final unique = <String, AttendanceRecord>{};
      for (final record in data.records) {
        if (record.employeeId == employeeId &&
            record.date.year == selected.year &&
            record.date.month == selected.month) {
          unique[record.id] = record;
        }
      }
      final records = unique.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      emit(
        EmployeeAttendanceState(
          month: selected,
          records: records,
          pending: data.pendingRecordIds,
          correctionsReady: data.correctionsReady,
        ),
      );
    } catch (error) {
      if (isClosed || version != _load) return;
      emit(
        EmployeeAttendanceState(
          month: selected,
          error: AppError.message(error),
        ),
      );
    }
  }

  Future<void> requestCorrection({
    required AttendanceRecord record,
    required DateTime checkIn,
    required DateTime checkOut,
    required String reason,
  }) async {
    if (isClosed || state.loading || state.saving) {
      throw StateError('Attendance is busy');
    }
    if (!state.correctionsReady ||
        record.employeeId != employeeId ||
        !state.records.any((r) => r.id == record.id) ||
        state.pending.contains(record.id)) {
      throw StateError('Correction is unavailable for this record');
    }
    if (reason.trim().isEmpty ||
        reason.trim().length > 500 ||
        !checkOut.isAfter(checkIn)) {
      throw ArgumentError('Enter valid times and a reason');
    }
    final previous = state;
    if (record.checkIn?.isAtSameMomentAs(checkIn) == true &&
        record.checkOut?.isAtSameMomentAs(checkOut) == true) {
      throw ArgumentError('At least one recorded time must change');
    }
    emit(
      EmployeeAttendanceState(
        month: state.month,
        records: state.records,
        pending: state.pending,
        correctionsReady: true,
        saving: true,
      ),
    );
    try {
      await repo.requestCorrection(
        record: record,
        checkIn: checkIn,
        checkOut: checkOut,
        reason: reason.trim(),
      );
      if (isClosed) return;
      emit(
        EmployeeAttendanceState(
          month: previous.month,
          records: previous.records,
          pending: {...previous.pending, record.id},
          correctionsReady: true,
        ),
      );
    } catch (_) {
      if (!isClosed) emit(previous);
      rethrow;
    }
  }
}
