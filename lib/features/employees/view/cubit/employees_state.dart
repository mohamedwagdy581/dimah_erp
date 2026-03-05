import 'package:equatable/equatable.dart';
import '../../domain/models/employee.dart';

class EmployeesState extends Equatable {
  const EmployeesState({
    required this.items,
    required this.total,
    required this.loading,
    required this.page,
    required this.pageSize,
    required this.search,
    required this.status,
    required this.sortBy,
    required this.ascending,
    this.error,
  });

  final List<Employee> items;
  final int total;
  final bool loading;
  final int page;
  final int pageSize;
  final String search;
  final String? status;
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

  EmployeesState copyWith({
    List<Employee>? items,
    int? total,
    bool? loading,
    int? page,
    int? pageSize,
    String? search,
    Object? status = _unset,
    String? sortBy,
    bool? ascending,
    String? error,
    bool clearError = false,
  }) {
    return EmployeesState(
      items: items ?? this.items,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      status: status == _unset ? this.status : status as String?,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      error: clearError ? null : (error ?? this.error),
    );
  }

  static const initial = EmployeesState(
    items: [],
    total: 0,
    loading: false,
    page: 0,
    pageSize: 10,
    search: '',
    status: null,
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
    status,
    sortBy,
    ascending,
    error,
  ];
}
