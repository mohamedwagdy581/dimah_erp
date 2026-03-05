import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_error.dart';
import '../../domain/repos/departments_repo.dart';
import 'departments_state.dart';

class DepartmentsCubit extends Cubit<DepartmentsState> {
  DepartmentsCubit(this._repo) : super(DepartmentsState.initial);

  final DepartmentsRepo _repo;

  /// Debounce timer used for "live search" to avoid firing a request per keystroke.
  Timer? _debounce;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  // =========================
  // Data loading
  // =========================

  /// Fetch departments from backend using current state:
  /// search, isActive, pagination, sorting.
  /// If [resetPage] is true => starts from page 0.
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

      final result = await _repo.fetchDepartments(
        page: resetPage ? 0 : state.page,
        pageSize: state.pageSize,
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        isActive: state.isActive,
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
      if (isClosed) return;
      if (AppError.isTransient(e)) {
        emit(state.copyWith(loading: false));
        return;
      }

      emit(state.copyWith(loading: false, error: AppError.message(e)));
    }
  }

  // =========================
  // UI actions (Search / Filter / Sort / Paging)
  // =========================

  /// Live-search handler (debounced).
  /// Updates [search] and triggers a load after 350ms of inactivity.
  void searchChanged(String v) {
    if (isClosed) return;

    emit(state.copyWith(search: v));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (isClosed) return;
      load(resetPage: true);
    });
  }

  /// Sets Active filter:
  /// - null => All
  /// - true => Active only
  /// - false => Inactive only
  /// Triggers reload from page 0.
  Future<void> activeFilterChanged(bool? v) async {
    emit(state.copyWith(isActive: v));
    await load(resetPage: true);
  }

  /// Toggles sorting:
  /// - If same column => flip ascending/descending.
  /// - If new column => set it; default ascending for name, descending for created_at.
  Future<void> toggleSort(String sortBy) async {
    if (state.sortBy == sortBy) {
      emit(state.copyWith(ascending: !state.ascending));
    } else {
      emit(state.copyWith(sortBy: sortBy, ascending: sortBy == 'name'));
    }
    await load(resetPage: true);
  }

  /// Changes page size and reloads from page 0.
  Future<void> setPageSize(int v) async {
    emit(state.copyWith(pageSize: v));
    await load(resetPage: true);
  }

  /// Go to next page (if allowed) then reload.
  Future<void> nextPage() async {
    if (!state.canNext) return;
    emit(state.copyWith(page: state.page + 1));
    await load();
  }

  /// Go to previous page (if allowed) then reload.
  Future<void> prevPage() async {
    if (!state.canPrev) return;
    emit(state.copyWith(page: state.page - 1));
    await load();
  }

  /// Resets filters to defaults (All + empty search) and reloads.
  Future<void> resetFilters() async {
    _debounce?.cancel();
    emit(
      state.copyWith(
        search: '',
        isActive: null, // ✅ يرجّع All
        page: 0,
      ),
    );
    await load(resetPage: true);
  }

  // =========================
  // CRUD
  // =========================

  /// Creates a new department then refreshes list from page 0.
  Future<void> create({
    required String name,
    String? code,
    String? description,
    String? managerId,
  }) async {
    await _repo.createDepartment(
      name: name,
      code: code,
      description: description,
      managerId: managerId,
    );
    await load(resetPage: true);
  }

  /// Updates an existing department then refreshes current page.
  Future<void> update({
    required String id,
    required String name,
    String? code,
    String? description,
    String? managerId,
    required bool isActive,
  }) async {
    await _repo.updateDepartment(
      id: id,
      name: name,
      code: code,
      description: description,
      managerId: managerId,
      isActive: isActive,
    );
    await load();
  }

  Future<int> autoAssignManagers() async {
    final count = await _repo.autoAssignManagers();
    await load(resetPage: true);
    return count;
  }
}
