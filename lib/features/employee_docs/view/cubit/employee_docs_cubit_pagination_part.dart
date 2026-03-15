part of 'employee_docs_cubit.dart';

extension EmployeeDocsCubitPaginationX on EmployeeDocsCubit {
  Future<void> setEmployeeDocsPageSize(int value) async {
    emit(state.copyWith(pageSize: value));
    await load(resetPage: true);
  }

  Future<void> nextEmployeeDocsPage() async {
    if (!state.canNext) {
      return;
    }
    emit(state.copyWith(page: state.page + 1));
    await load();
  }

  Future<void> prevEmployeeDocsPage() async {
    if (!state.canPrev) {
      return;
    }
    emit(state.copyWith(page: state.page - 1));
    await load();
  }
}
