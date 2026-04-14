part of 'employee_docs_cubit.dart';

extension EmployeeDocsCubitLoadingX on EmployeeDocsCubit {
  Future<void> loadEmployeeDocsCubit({bool resetPage = false}) async {
    try {
      if (isClosed) {
        return;
      }
      _emitState(
        state.copyWith(
          loading: true,
          clearError: true,
          page: resetPage ? 0 : state.page,
        ),
      );

      final employeeResult = await _loadEmployeesForDocs(
        resetPage: resetPage,
      );
      final employeeLookups = employeeResult.items;
      final docsMap = await _loadDocsForEmployees(employeeLookups);

      if (isClosed) {
        return;
      }
      _emitState(
        state.copyWith(
          loading: false,
          employees: employeeLookups,
          docsMap: docsMap,
          total: employeeResult.total,
        ),
      );
    } catch (e) {
      if (isClosed) {
        return;
      }
      _emitState(state.copyWith(loading: false, error: AppError.message(e)));
    }
  }

  Future<({List<EmployeeLookup> items, int total})> _loadEmployeesForDocs({
    required bool resetPage,
  }) async {
    final fixedEmployeeId = state.fixedEmployeeId;
    if (fixedEmployeeId != null && fixedEmployeeId.trim().isNotEmpty) {
      final profile = await AppDI.employeesRepo.fetchEmployeeProfile(
        employeeId: fixedEmployeeId,
      );
      return (
        items: [EmployeeLookup(id: profile.id, fullName: profile.fullName)],
        total: 1,
      );
    }

    final result = await AppDI.employeesRepo.fetchEmployees(
      page: resetPage ? 0 : state.page,
      pageSize: state.pageSize,
      search: state.search.trim().isEmpty ? null : state.search.trim(),
      sortBy: 'full_name',
      ascending: true,
    );
    return (
      items: result.items.map((employee) => employee.toLookup()).toList(),
      total: result.total,
    );
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
      _emitState(state.copyWith(docsMap: newDocsMap));
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
    _emitState(state.copyWith(expandedEmployeeIds: newExpanded));
  }
}
