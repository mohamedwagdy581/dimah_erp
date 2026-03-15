part of 'employee_docs_cubit.dart';

extension EmployeeDocsCubitFiltersX on EmployeeDocsCubit {
  void onEmployeeDocsSearchChanged(String value) {
    emit(state.copyWith(search: value));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (isClosed) {
        return;
      }
      load(resetPage: true);
    });
  }

  Future<void> onEmployeeDocsDocTypeChanged(String? value) async {
    emit(state.copyWith(docType: value));
    await load(resetPage: true);
  }

  void onEmployeeDocsExpiryStatusChanged(String? value) {
    emit(state.copyWith(expiryStatus: value));
  }

  Future<void> onEmployeeDocsToggleSort(String sortBy) async {
    if (state.sortBy == sortBy) {
      emit(state.copyWith(ascending: !state.ascending));
    } else {
      emit(state.copyWith(sortBy: sortBy, ascending: sortBy == 'created_at'));
    }
    await load();
  }
}
