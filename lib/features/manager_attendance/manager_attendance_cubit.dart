import 'package:flutter_bloc/flutter_bloc.dart';
import 'manager_attendance_repo.dart';

class ManagerAttendanceState {
  const ManagerAttendanceState({
    required this.month,
    this.data = const ManagerAttendanceData(),
    this.loading = false,
    this.failed = false,
    this.error,
  });
  final DateTime month;
  final ManagerAttendanceData data;
  final bool loading, failed;
  final Object? error;
}

class ManagerAttendanceCubit extends Cubit<ManagerAttendanceState> {
  ManagerAttendanceCubit(this.repo, {DateTime? now})
    : super(
        ManagerAttendanceState(
          month: DateTime(
            (now ?? DateTime.now()).year,
            (now ?? DateTime.now()).month,
          ),
        ),
      );
  final ManagerAttendanceRepo repo;
  int _generation = 0;
  Future<void> load([DateTime? month]) async {
    final target = month ?? state.month;
    final normalized = DateTime(target.year, target.month);
    final generation = ++_generation;
    emit(ManagerAttendanceState(month: normalized, loading: true));
    try {
      final data = await repo.load(normalized);
      if (!isClosed && generation == _generation) {
        emit(ManagerAttendanceState(month: normalized, data: data));
      }
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          ManagerAttendanceState(month: normalized, failed: true, error: error),
        );
      }
    }
  }
}
