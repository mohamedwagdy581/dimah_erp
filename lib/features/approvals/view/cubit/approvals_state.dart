import 'package:equatable/equatable.dart';
import '../../domain/models/approval_request.dart';

class ApprovalsState extends Equatable {
  const ApprovalsState({
    required this.items,
    required this.total,
    required this.loading,
    required this.page,
    required this.pageSize,
    required this.status,
    required this.requestType,
    required this.sortBy,
    required this.ascending,
    this.error,
  });

  final List<ApprovalRequest> items;
  final int total;
  final bool loading;
  final int page;
  final int pageSize;
  final String? status;
  final String? requestType;
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

  ApprovalsState copyWith({
    List<ApprovalRequest>? items,
    int? total,
    bool? loading,
    int? page,
    int? pageSize,
    Object? status = _unset,
    Object? requestType = _unset,
    String? sortBy,
    bool? ascending,
    String? error,
    bool clearError = false,
  }) {
    return ApprovalsState(
      items: items ?? this.items,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      status: status == _unset ? this.status : status as String?,
      requestType:
          requestType == _unset ? this.requestType : requestType as String?,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      error: clearError ? null : (error ?? this.error),
    );
  }

  static const initial = ApprovalsState(
    items: [],
    total: 0,
    loading: false,
    page: 0,
    pageSize: 10,
    status: null,
    requestType: null,
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
    status,
    requestType,
    sortBy,
    ascending,
    error,
  ];
}
