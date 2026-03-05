import 'package:equatable/equatable.dart';
import '../../domain/models/employee_document.dart';

class EmployeeDocsState extends Equatable {
  const EmployeeDocsState({
    required this.items,
    required this.total,
    required this.loading,
    required this.page,
    required this.pageSize,
    required this.search,
    required this.docType,
    required this.sortBy,
    required this.ascending,
    this.error,
  });

  final List<EmployeeDocument> items;
  final int total;
  final bool loading;
  final int page;
  final int pageSize;
  final String search;
  final String? docType;
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
    List<EmployeeDocument>? items,
    int? total,
    bool? loading,
    int? page,
    int? pageSize,
    String? search,
    Object? docType = _unset,
    String? sortBy,
    bool? ascending,
    String? error,
    bool clearError = false,
  }) {
    return EmployeeDocsState(
      items: items ?? this.items,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      docType: docType == _unset ? this.docType : docType as String?,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      error: clearError ? null : (error ?? this.error),
    );
  }

  static const initial = EmployeeDocsState(
    items: [],
    total: 0,
    loading: false,
    page: 0,
    pageSize: 10,
    search: '',
    docType: null,
    sortBy: 'created_at',
    ascending: false,
    error: null,
  );

  @override
  List<Object?> get props => [
    items,
    total,
    loading,
    page,
    pageSize,
    search,
    docType,
    sortBy,
    ascending,
    error,
  ];
}
