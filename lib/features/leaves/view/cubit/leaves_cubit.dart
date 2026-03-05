import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_error.dart';
import '../../domain/models/leave_balance.dart';
import '../../domain/repos/leaves_repo.dart';
import 'leaves_state.dart';

class LeavesCubit extends Cubit<LeavesState> {
  LeavesCubit(this._repo, {this.employeeId}) : super(LeavesState.initial);

  final LeavesRepo _repo;
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

      final result = await _repo.fetchLeaves(
        page: resetPage ? 0 : state.page,
        pageSize: state.pageSize,
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        status: state.status,
        type: state.type,
        startDate: state.startDate,
        endDate: state.endDate,
        employeeId: employeeId,
        sortBy: state.sortBy,
        ascending: state.ascending,
      );
      List<LeaveBalance> balances = const [];
      if (employeeId != null && employeeId!.trim().isNotEmpty) {
        balances = await _repo.fetchLeaveBalances(
          employeeId: employeeId!,
          year: DateTime.now().year,
        );
      }

      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          items: result.items,
          balances: balances,
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

  Future<void> typeFilterChanged(String? v) async {
    emit(state.copyWith(type: v));
    await load(resetPage: true);
  }

  Future<void> startDateChanged(DateTime? v) async {
    emit(state.copyWith(startDate: v));
    await load(resetPage: true);
  }

  Future<void> endDateChanged(DateTime? v) async {
    emit(state.copyWith(endDate: v));
    await load(resetPage: true);
  }

  Future<void> toggleSort(String sortBy) async {
    if (state.sortBy == sortBy) {
      emit(state.copyWith(ascending: !state.ascending));
    } else {
      emit(state.copyWith(sortBy: sortBy, ascending: sortBy == 'start_date'));
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
    emit(
      state.copyWith(
        search: '',
        status: null,
        type: null,
        startDate: null,
        endDate: null,
        page: 0,
      ),
    );
    await load(resetPage: true);
  }

  Future<void> create({
    required String employeeId,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String? fileUrl,
    String? notes,
  }) async {
    await _repo.createLeave(
      employeeId: employeeId,
      type: type,
      startDate: startDate,
      endDate: endDate,
      fileUrl: fileUrl,
      notes: notes,
    );
    await load(resetPage: true);
  }

  Future<void> resubmit({
    required String leaveId,
    required String employeeId,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String? fileUrl,
    String? notes,
  }) async {
    await _repo.resubmitLeave(
      leaveId: leaveId,
      employeeId: employeeId,
      type: type,
      startDate: startDate,
      endDate: endDate,
      fileUrl: fileUrl,
      notes: notes,
    );
    await load(resetPage: true);
  }
}
