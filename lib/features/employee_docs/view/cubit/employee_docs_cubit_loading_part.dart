part of 'employee_docs_cubit.dart';

extension EmployeeDocsCubitLoadingX on EmployeeDocsCubit {
  Future<void> loadEmployeeDocsCubit({bool resetPage = false}) async {
    try {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          loading: true,
          clearError: true,
          page: resetPage ? 0 : state.page,
        ),
      );

      final result = await AppDI.employeesRepo.fetchEmployees(
        page: resetPage ? 0 : state.page,
        pageSize: state.pageSize,
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        sortBy: 'full_name',
        ascending: true,
      );
      final employeeLookups = result.items.map((employee) => employee.toLookup()).toList();
      final docsMap = await _loadDocsForEmployees(employeeLookups);

      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          loading: false,
          employees: employeeLookups,
          docsMap: docsMap,
          total: result.total,
        ),
      );
    } catch (e) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(loading: false, error: AppError.message(e)));
    }
  }

  Future<Map<String, List<EmployeeDocument>>> _loadDocsForEmployees(
    List<EmployeeLookup> employees,
  ) async {
    final map = <String, List<EmployeeDocument>>{};
    for (final employee in employees) {
      try {
        final result = await _repo.fetchDocs(
          page: 0,
          pageSize: 100,
          employeeId: employee.id,
          docType: state.docType,
          sortBy: state.sortBy,
          ascending: state.ascending,
        );
        map[employee.id] = result.items;
      } catch (_) {
        map[employee.id] = const [];
      }
    }
    return map;
  }

  Future<void> loadSingleEmployeeDocs(String employeeId) async {
    try {
      final result = await _repo.fetchDocs(
        page: 0,
        pageSize: 100,
        employeeId: employeeId,
        docType: state.docType,
        sortBy: state.sortBy,
        ascending: state.ascending,
      );
      if (isClosed) {
        return;
      }
      final newDocsMap = Map<String, List<EmployeeDocument>>.from(state.docsMap);
      newDocsMap[employeeId] = result.items;
      emit(state.copyWith(docsMap: newDocsMap));
    } catch (_) {}
  }

  void toggleEmployeeDocsExpansion(String employeeId) {
    final newExpanded = Set<String>.from(state.expandedEmployeeIds);
    if (newExpanded.contains(employeeId)) {
      newExpanded.remove(employeeId);
    } else {
      newExpanded.add(employeeId);
      loadSingleEmployeeDocs(employeeId);
    }
    emit(state.copyWith(expandedEmployeeIds: newExpanded));
  }
}
