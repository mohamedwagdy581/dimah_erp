import 'package:equatable/equatable.dart';
import '../../domain/models/leave_balance.dart';
import '../../domain/models/leave_request.dart';

class LeavesState extends Equatable {
  const LeavesState({
    required this.items,
    required this.balances,
    required this.total,
    required this.loading,
    required this.page,
    required this.pageSize,
    required this.search,
    required this.status,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.sortBy,
    required this.ascending,
    this.error,
  });

  final List<LeaveRequest> items;
  final List<LeaveBalance> balances;
  final int total;
  final bool loading;
  final int page;
  final int pageSize;
  final String search;
  final String? status;
  final String? type;
  final DateTime? startDate;
  final DateTime? endDate;
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

  LeavesState copyWith({
    List<LeaveRequest>? items,
    List<LeaveBalance>? balances,
    int? total,
    bool? loading,
    int? page,
    int? pageSize,
    String? search,
    Object? status = _unset,
    Object? type = _unset,
    Object? startDate = _unset,
    Object? endDate = _unset,
    String? sortBy,
    bool? ascending,
    String? error,
    bool clearError = false,
  }) {
    return LeavesState(
      items: items ?? this.items,
      balances: balances ?? this.balances,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      status: status == _unset ? this.status : status as String?,
      type: type == _unset ? this.type : type as String?,
      startDate:
          startDate == _unset ? this.startDate : startDate as DateTime?,
      endDate: endDate == _unset ? this.endDate : endDate as DateTime?,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      error: clearError ? null : (error ?? this.error),
    );
  }

  static const initial = LeavesState(
    items: [],
    balances: [],
    total: 0,
    loading: false,
    page: 0,
    pageSize: 10,
    search: '',
    status: null,
    type: null,
    startDate: null,
    endDate: null,
    sortBy: 'start_date',
    ascending: false,
    error: null,
  );

  @override
  List<Object?> get props => [
    items,
    balances,
    total,
    loading,
    page,
    pageSize,
    search,
    status,
    type,
    startDate,
    endDate,
    sortBy,
    ascending,
    error,
  ];
}
