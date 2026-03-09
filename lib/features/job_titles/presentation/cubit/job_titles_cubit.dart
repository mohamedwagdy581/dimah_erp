import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_error.dart';
import '../../domain/repos/job_titles_repo.dart';
import 'job_titles_state.dart';

class JobTitlesCubit extends Cubit<JobTitlesState> {
  JobTitlesCubit(this._repo) : super(JobTitlesState.initial);

  final JobTitlesRepo _repo;
  Timer? _debounce;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  /// Load list using current filters/sort/paging.
  Future<void> load({bool resetPage = false, String? departmentId}) async {
    try {
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: true,
          clearError: true,
          page: resetPage ? 0 : state.page,
        ),
      );

      final result = await _repo.fetchJobTitles(
        page: resetPage ? 0 : state.page,
        pageSize: state.pageSize,
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        isActive: state.isActive,
        departmentId: departmentId,
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

  /// Debounced live-search.
  void searchChanged(String v) {
    emit(state.copyWith(search: v));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (isClosed) return;
      load(resetPage: true);
    });
  }

  /// Filter by active flag (null=all).
  Future<void> activeFilterChanged(bool? v) async {
    emit(state.copyWith(isActive: v));
    await load(resetPage: true);
  }

  /// Sort handling.
  Future<void> toggleSort(String sortBy) async {
    if (state.sortBy == sortBy) {
      emit(state.copyWith(ascending: !state.ascending));
    } else {
      // name/level usually ascending makes sense
      emit(state.copyWith(sortBy: sortBy, ascending: sortBy != 'created_at'));
    }
    await load(resetPage: true);
  }

  /// Page size.
  Future<void> setPageSize(int v) async {
    emit(state.copyWith(pageSize: v));
    await load(resetPage: true);
  }

  /// Next page.
  Future<void> nextPage() async {
    if (!state.canNext) return;
    emit(state.copyWith(page: state.page + 1));
    await load();
  }

  /// Previous page.
  Future<void> prevPage() async {
    if (!state.canPrev) return;
    emit(state.copyWith(page: state.page - 1));
    await load();
  }

  /// Reset search + filters.
  Future<void> resetFilters() async {
    _debounce?.cancel();
    emit(state.copyWith(search: '', isActive: null, page: 0));
    await load(resetPage: true);
  }

  /// Create job title then reload.
  Future<void> create({
    required String name,
    String? code,
    String? description,
    int? level,
  }) async {
    await _repo.createJobTitle(
      name: name,
      code: code,
      description: description,
      level: level,
    );
    await load(resetPage: true);
  }

  /// Update job title then reload.
  Future<void> update({
    required String id,
    required String name,
    String? code,
    String? description,
    int? level,
    required bool isActive,
  }) async {
    await _repo.updateJobTitle(
      id: id,
      name: name,
      code: code,
      description: description,
      level: level,
      isActive: isActive,
    );
    await load();
  }

  Future<void> loadForDepartment(String departmentId) async {
    try {
      emit(state.copyWith(loading: true, error: null));

      final res = await _repo.fetchJobTitles(
        page: 0,
        pageSize: 200,
        search: null,
        isActive: true,
        departmentId: departmentId,
        sortBy: 'name',
        ascending: true,
      );
      if (kDebugMode) {
        print('[JobTitles] dept=$departmentId items=${res.items.length}');
        print(res.items.map((e) => e.name).toList());
      }
      if (isClosed) return;
      emit(state.copyWith(loading: false, items: res.items, total: res.total));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  void clear() {
    emit(state.copyWith(items: [], total: 0, loading: false, error: null));
  }
}
