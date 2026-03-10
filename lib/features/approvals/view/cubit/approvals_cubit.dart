import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_error.dart';
import '../../domain/repos/approvals_repo.dart';
import 'approvals_state.dart';

class ApprovalsCubit extends Cubit<ApprovalsState> {
  ApprovalsCubit(
    this._repo, {
    this.employeeId,
    String? initialStatus,
    String? initialRequestType,
  }) : super(
          ApprovalsState.initial.copyWith(
            status: initialStatus,
            requestType: initialRequestType,
          ),
        );

  final ApprovalsRepo _repo;
  final String? employeeId;

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

      final result = await _repo.fetchApprovals(
        page: resetPage ? 0 : state.page,
        pageSize: state.pageSize,
        status: state.status,
        requestType: state.requestType,
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

  Future<void> statusFilterChanged(String? v) async {
    emit(state.copyWith(status: v));
    await load(resetPage: true);
  }

  Future<void> typeFilterChanged(String? v) async {
    emit(state.copyWith(requestType: v));
    await load(resetPage: true);
  }

  Future<void> toggleSort(String sortBy) async {
    if (state.sortBy == sortBy) {
      emit(state.copyWith(ascending: !state.ascending));
    } else {
      emit(state.copyWith(sortBy: sortBy, ascending: sortBy == 'created_at'));
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

  Future<void> approve(String id) async {
    try {
      await _repo.approve(id);
      await load();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(error: AppError.message(e)));
      await load();
    }
  }

  Future<void> reject(String id, {String? reason}) async {
    try {
      await _repo.reject(id, reason: reason);
      await load();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(error: AppError.message(e)));
      await load();
    }
  }
}
