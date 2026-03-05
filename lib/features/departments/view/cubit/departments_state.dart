import 'package:equatable/equatable.dart';
import '../../domain/models/department.dart';

class DepartmentsState extends Equatable {
  const DepartmentsState({
    required this.items,
    required this.total,
    required this.loading,
    required this.page,
    required this.pageSize,
    required this.search,
    required this.isActive,
    required this.sortBy,
    required this.ascending,
    this.error,
  });

  /// Rows shown in the table for the current query.
  final List<Department> items;

  /// Total rows count matching current filters (for pagination).
  final int total;

  /// True while fetching data from backend.
  final bool loading;

  /// Current page index (zero-based).
  final int page;

  /// Number of rows per page.
  final int pageSize;

  /// Search term (UI text).
  final String search;

  /// Active filter:
  /// - null => All
  /// - true => Active only
  /// - false => Inactive only
  final bool? isActive;

  /// Sorting column key. Example: 'created_at' | 'name'
  final String sortBy;

  /// Sorting direction.
  final bool ascending;

  /// Last error message (if any).
  final String? error;

  /// Sentinel used to allow "setting isActive to null" through copyWith.
  static const Object _unset = Object();

  /// Total pages based on [total] and [pageSize].
  int get totalPages {
    final pages = (total / pageSize).ceil();
    return pages <= 0 ? 1 : pages;
  }

  /// Whether user can go to previous page.
  bool get canPrev => page > 0;

  /// Whether user can go to next page.
  bool get canNext => page + 1 < totalPages;

  DepartmentsState copyWith({
    /// Replace table items
    List<Department>? items,

    /// Replace total count
    int? total,

    /// Replace loading flag
    bool? loading,

    /// Replace page index
    int? page,

    /// Replace page size
    int? pageSize,

    /// Replace search text
    String? search,

    /// Replace active filter (IMPORTANT):
    /// pass `isActive: null` to show ALL.
    /// We use `_unset` to distinguish "not provided" from "explicit null".
    Object? isActive = _unset,

    /// Replace sort column
    String? sortBy,

    /// Replace sort direction
    bool? ascending,

    /// Replace error message
    String? error,

    /// If true => clears existing error (sets error=null)
    bool clearError = false,
  }) {
    return DepartmentsState(
      items: items ?? this.items,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      isActive: isActive == _unset ? this.isActive : isActive as bool?,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Initial default state.
  static const initial = DepartmentsState(
    items: [],
    total: 0,
    loading: false,
    page: 0,
    pageSize: 10,
    search: '',
    isActive: null,
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
    isActive,
    sortBy,
    ascending,
    error,
  ];
}
