import 'package:equatable/equatable.dart';

import '../../domain/models/employee_settlement_summary.dart';

class SettlementsState extends Equatable {
  const SettlementsState({
    required this.items,
    required this.total,
    required this.loading,
    required this.page,
    required this.pageSize,
    required this.search,
    this.error,
  });

  final List<EmployeeSettlementSummary> items;
  final int total;
  final bool loading;
  final int page;
  final int pageSize;
  final String search;
  final String? error;

  int get totalPages {
    final pages = (total / pageSize).ceil();
    return pages <= 0 ? 1 : pages;
  }

  bool get canPrev => page > 0;
  bool get canNext => page + 1 < totalPages;

  SettlementsState copyWith({
    List<EmployeeSettlementSummary>? items,
    int? total,
    bool? loading,
    int? page,
    int? pageSize,
    String? search,
    String? error,
    bool clearError = false,
  }) {
    return SettlementsState(
      items: items ?? this.items,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      error: clearError ? null : (error ?? this.error),
    );
  }

  static const initial = SettlementsState(
    items: [],
    total: 0,
    loading: false,
    page: 0,
    pageSize: 10,
    search: '',
    error: null,
  );

  @override
  List<Object?> get props => [items, total, loading, page, pageSize, search, error];
}
