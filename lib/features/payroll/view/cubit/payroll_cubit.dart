import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_error.dart';
import '../../domain/repos/payroll_repo.dart';
import 'payroll_state.dart';

class PayrollCubit extends Cubit<PayrollState> {
  PayrollCubit(this._repo) : super(PayrollState.initial);

  final PayrollRepo _repo;

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

      final result = await _repo.fetchRuns(
        page: resetPage ? 0 : state.page,
        pageSize: state.pageSize,
        status: state.status,
        startDate: state.startDate,
        endDate: state.endDate,
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

  Future<void> statusFilterChanged(String? v) async {
    emit(state.copyWith(status: v));
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
      emit(state.copyWith(sortBy: sortBy, ascending: sortBy == 'period_start'));
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
    emit(state.copyWith(status: null, startDate: null, endDate: null, page: 0));
    await load(resetPage: true);
  }

  Future<void> createRun({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _repo.createRun(periodStart: startDate, periodEnd: endDate);
    await load(resetPage: true);
  }
}
