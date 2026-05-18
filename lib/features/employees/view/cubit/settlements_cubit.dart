import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_error.dart';
import '../../domain/repos/employee_repo.dart';
import 'settlements_state.dart';

class SettlementsCubit extends Cubit<SettlementsState> {
  SettlementsCubit(this._repo) : super(SettlementsState.initial);

  final EmployeesRepo _repo;
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

      final result = await _repo.fetchSettlements(
        page: resetPage ? 0 : state.page,
        pageSize: state.pageSize,
        search: state.search.trim().isEmpty ? null : state.search.trim(),
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

  void searchChanged(String value) {
    emit(state.copyWith(search: value));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (isClosed) return;
      load(resetPage: true);
    });
  }

  Future<void> setPageSize(int value) async {
    emit(state.copyWith(pageSize: value));
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
}
