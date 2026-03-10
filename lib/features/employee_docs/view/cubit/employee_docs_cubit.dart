import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/utils/app_error.dart';
import '../../../employees/domain/models/employee.dart';
import '../../../employees/domain/models/employee_lookup.dart';
import '../../domain/models/employee_document.dart';
import '../../domain/repos/employee_docs_repo.dart';
import 'employee_docs_state.dart';

class EmployeeDocsCubit extends Cubit<EmployeeDocsState> {
  EmployeeDocsCubit(
    this._repo, {
    String? initialDocType,
    String? initialExpiryStatus,
  }) : super(
          EmployeeDocsState.initial.copyWith(
            docType: initialDocType,
            expiryStatus: initialExpiryStatus,
          ),
        );

  final EmployeeDocsRepo _repo;
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

      final result = await AppDI.employeesRepo.fetchEmployees(
        page: resetPage ? 0 : state.page,
        pageSize: state.pageSize,
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        sortBy: 'full_name', // Default sort for employee list
        ascending: true,
      );

      final employeeLookups = result.items.map((e) => e.toLookup()).toList();
      final docsMap = await _loadDocsForEmployees(employeeLookups);

      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          employees: employeeLookups,
          docsMap: docsMap,
          total: result.total,
        ),
      );
    } catch (e) {
      if (isClosed) return;
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

  Future<void> _loadEmployeeDocs(String employeeId) async {
    try {
      final result = await _repo.fetchDocs(
        page: 0,
        pageSize: 100,
        employeeId: employeeId,
        docType: state.docType,
        sortBy: state.sortBy,
        ascending: state.ascending,
      );
      
      if (isClosed) return;
      final newDocsMap = Map<String, List<EmployeeDocument>>.from(state.docsMap);
      newDocsMap[employeeId] = result.items;
      
      emit(state.copyWith(docsMap: newDocsMap));
    } catch (e) {
      // Fail silently for individual employee doc loading
    }
  }

  void toggleExpansion(String employeeId) {
    final newExpanded = Set<String>.from(state.expandedEmployeeIds);
    if (newExpanded.contains(employeeId)) {
      newExpanded.remove(employeeId);
    } else {
      newExpanded.add(employeeId);
      _loadEmployeeDocs(employeeId);
    }
    emit(state.copyWith(expandedEmployeeIds: newExpanded));
  }

  void searchChanged(String v) {
    emit(state.copyWith(search: v));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (isClosed) return;
      load(resetPage: true);
    });
  }

  Future<void> docTypeChanged(String? v) async {
    emit(state.copyWith(docType: v));
    await load(resetPage: true);
  }

  void expiryStatusChanged(String? v) {
    emit(state.copyWith(expiryStatus: v));
  }

  Future<void> toggleSort(String sortBy) async {
    if (state.sortBy == sortBy) {
      emit(state.copyWith(ascending: !state.ascending));
    } else {
      emit(state.copyWith(sortBy: sortBy, ascending: sortBy == 'created_at'));
    }
    await load();
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

  Future<void> create({
    required String employeeId,
    required String docType,
    required String fileUrl,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) async {
    await _repo.createDoc(
      employeeId: employeeId,
      docType: docType,
      fileUrl: fileUrl,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );
    await _loadEmployeeDocs(employeeId);
  }

  Future<void> update({
    required String id,
    required String employeeId,
    required String docType,
    required String fileUrl,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) async {
    await _repo.updateDoc(
      id: id,
      employeeId: employeeId,
      docType: docType,
      fileUrl: fileUrl,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );
    await _loadEmployeeDocs(employeeId);
  }

  Future<void> delete({
    required String id,
    required String employeeId,
    required String fileUrl,
  }) async {
    await _repo.deleteDoc(id: id, fileUrl: fileUrl);
    await _loadEmployeeDocs(employeeId);
  }
}

extension on Employee {
  EmployeeLookup toLookup() => EmployeeLookup(id: id, fullName: fullName);
}
