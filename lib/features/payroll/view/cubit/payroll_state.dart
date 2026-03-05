import 'package:equatable/equatable.dart';
import '../../domain/models/payroll_run.dart';

class PayrollState extends Equatable {
  const PayrollState({
    required this.items,
    required this.total,
    required this.loading,
    required this.page,
    required this.pageSize,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.sortBy,
    required this.ascending,
    this.error,
  });

  final List<PayrollRun> items;
  final int total;
  final bool loading;
  final int page;
  final int pageSize;
  final String? status;
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

  PayrollState copyWith({
    List<PayrollRun>? items,
    int? total,
    bool? loading,
    int? page,
    int? pageSize,
    Object? status = _unset,
    Object? startDate = _unset,
    Object? endDate = _unset,
    String? sortBy,
    bool? ascending,
    String? error,
    bool clearError = false,
  }) {
    return PayrollState(
      items: items ?? this.items,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      status: status == _unset ? this.status : status as String?,
      startDate:
          startDate == _unset ? this.startDate : startDate as DateTime?,
      endDate: endDate == _unset ? this.endDate : endDate as DateTime?,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      error: clearError ? null : (error ?? this.error),
    );
  }

  static const initial = PayrollState(
    items: [],
    total: 0,
    loading: false,
    page: 0,
    pageSize: 10,
    status: null,
    startDate: null,
    endDate: null,
    sortBy: 'period_start',
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
    status,
    startDate,
    endDate,
    sortBy,
    ascending,
    error,
  ];
}
