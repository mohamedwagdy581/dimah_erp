import 'package:equatable/equatable.dart';
import '../../domain/models/employee_document.dart';
import '../../../employees/domain/models/employee_lookup.dart';

class EmployeeDocsState extends Equatable {
  const EmployeeDocsState({
    required this.employees,
    required this.docsMap,
    required this.expandedEmployeeIds,
    required this.loading,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.search,
    required this.docType,
    required this.expiryStatus,
    required this.sortBy,
    required this.ascending,
    this.error,
  });

  final List<EmployeeLookup> employees;
  final Map<String, List<EmployeeDocument>> docsMap;
  final Set<String> expandedEmployeeIds;
  final bool loading;
  final int total;
  final int page;
  final int pageSize;
  final String search;
  final String? docType;
  final String? expiryStatus;
  final String sortBy;
  final bool ascending;
  final String? error;

  static const Object _unset = Object();

  int get totalPages {
    final pages = (total / pageSize).ceil();
    return pages <= 0 ? 1 : pages;
  }

  bool get canPrev => page > 0;
  bool get canNext => page + 1 < totalPages;

  EmployeeDocsState copyWith({
    List<EmployeeLookup>? employees,
    Map<String, List<EmployeeDocument>>? docsMap,
    Set<String>? expandedEmployeeIds,
    bool? loading,
    int? total,
    int? page,
    int? pageSize,
    String? search,
    Object? docType = _unset,
    Object? expiryStatus = _unset,
    String? sortBy,
    bool? ascending,
    String? error,
    bool clearError = false,
  }) {
    return EmployeeDocsState(
      employees: employees ?? this.employees,
      docsMap: docsMap ?? this.docsMap,
      expandedEmployeeIds: expandedEmployeeIds ?? this.expandedEmployeeIds,
      loading: loading ?? this.loading,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      docType: docType == _unset ? this.docType : docType as String?,
      expiryStatus: expiryStatus == _unset
          ? this.expiryStatus
          : expiryStatus as String?,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      error: clearError ? null : (error ?? this.error),
    );
  }

  static const initial = EmployeeDocsState(
    employees: [],
    docsMap: {},
    expandedEmployeeIds: {},
    loading: false,
    total: 0,
    page: 0,
    pageSize: 10,
    search: '',
    docType: null,
    expiryStatus: null,
    sortBy: 'created_at',
    ascending: false,
    error: null,
  );

  @override
  List<Object?> get props => [
        employees,
        docsMap,
        expandedEmployeeIds,
        loading,
        total,
        page,
        pageSize,
        search,
        docType,
        expiryStatus,
        sortBy,
        ascending,
        error,
      ];
}
