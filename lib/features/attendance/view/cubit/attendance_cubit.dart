import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_error.dart';
import '../../domain/models/attendance_import_record.dart';
import '../../domain/repos/attendance_repo.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit(this._repo, {this.employeeId})
      : super(AttendanceState.initial);

  final AttendanceRepo _repo;
  final String? employeeId;
  Timer? _debounce;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> load({bool resetPage = false}) async {
    try {
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: true,
          clearError: true,
          page: resetPage ? 0 : state.page,
        ),
      );

      final result = await _repo.fetchAttendance(
        page: resetPage ? 0 : state.page,
        pageSize: state.pageSize,
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        status: state.status,
        date: state.date,
        employeeId: employeeId,
        sortBy: state.sortBy,
        ascending: state.ascending,
      );

      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          items: result.items,
          total: result.total,
        ),
      );
    } catch (e) {
      if (AppError.isTransient(e)) {
        if (isClosed) return;
        emit(state.copyWith(loading: false));
        return;
      }
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: AppError.message(e)));
    }
  }

  void searchChanged(String v) {
    emit(state.copyWith(search: v));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (isClosed) return;
      load(resetPage: true);
    });
  }

  Future<void> statusFilterChanged(String? v) async {
    emit(state.copyWith(status: v));
    await load(resetPage: true);
  }

  Future<void> dateFilterChanged(DateTime? v) async {
    emit(state.copyWith(date: v));
    await load(resetPage: true);
  }

  Future<void> toggleSort(String sortBy) async {
    if (state.sortBy == sortBy) {
      emit(state.copyWith(ascending: !state.ascending));
    } else {
      emit(state.copyWith(sortBy: sortBy, ascending: sortBy == 'date'));
    }
    await load(resetPage: true);
  }

  Future<void> setPageSize(int v) async {
    emit(state.copyWith(pageSize: v));
    await load(resetPage: true);
  }

  Future<void> nextPage() async {
    if (!state.canNext) return;
    emit(state.copyWith(page: state.page + 1));
    await load();
  }

  Future<void> prevPage() async {
    if (!state.canPrev) return;
    emit(state.copyWith(page: state.page - 1));
    await load();
  }

  Future<void> resetFilters() async {
    _debounce?.cancel();
    emit(state.copyWith(search: '', status: null, date: null, page: 0));
    await load(resetPage: true);
  }

  Future<void> create({
    required String employeeId,
    required DateTime date,
    required String status,
    DateTime? checkIn,
    DateTime? checkOut,
    String? notes,
  }) async {
    await _repo.createAttendance(
      employeeId: employeeId,
      date: date,
      status: status,
      checkIn: checkIn,
      checkOut: checkOut,
      notes: notes,
    );
    await load(resetPage: true);
  }

  Future<void> requestCorrection({
    required String recordId,
    required String employeeId,
    required DateTime date,
    DateTime? proposedCheckIn,
    DateTime? proposedCheckOut,
    String? reason,
  }) async {
    await _repo.createCorrectionRequest(
      recordId: recordId,
      employeeId: employeeId,
      date: date,
      proposedCheckIn: proposedCheckIn,
      proposedCheckOut: proposedCheckOut,
      reason: reason,
    );
    await load();
  }

  Future<void> importBatch(List<AttendanceImportRecord> records) async {
    await _repo.upsertAttendanceBatch(records);
    await load(resetPage: true);
  }
}
