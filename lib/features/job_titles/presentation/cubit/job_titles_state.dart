import 'package:equatable/equatable.dart';
import '../../domain/models/job_title.dart';

class JobTitlesState extends Equatable {
  const JobTitlesState({
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

  final List<JobTitle> items;
  final int total;
  final bool loading;

  /// zero-based
  final int page;
  final int pageSize;

  final String search;

  /// null = all
  final bool? isActive;

  /// 'created_at' | 'name' | 'level'
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

  JobTitlesState copyWith({
    List<JobTitle>? items,
    int? total,
    bool? loading,
    int? page,
    int? pageSize,
    String? search,
    Object? isActive = _unset,
    String? sortBy,
    bool? ascending,
    String? error,
    bool clearError = false,
  }) {
    return JobTitlesState(
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

  static const initial = JobTitlesState(
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
