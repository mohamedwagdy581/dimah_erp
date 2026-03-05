import 'package:equatable/equatable.dart';
import '../../domain/models/account.dart';

class AccountsState extends Equatable {
  const AccountsState({
    required this.items,
    required this.total,
    required this.loading,
    required this.page,
    required this.pageSize,
    required this.search,
    required this.type,
    required this.sortBy,
    required this.ascending,
    this.error,
  });

  final List<Account> items;
  final int total;
  final bool loading;
  final int page;
  final int pageSize;
  final String search;
  final String? type;
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

  AccountsState copyWith({
    List<Account>? items,
    int? total,
    bool? loading,
    int? page,
    int? pageSize,
    String? search,
    Object? type = _unset,
    String? sortBy,
    bool? ascending,
    String? error,
    bool clearError = false,
  }) {
    return AccountsState(
      items: items ?? this.items,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      type: type == _unset ? this.type : type as String?,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      error: clearError ? null : (error ?? this.error),
    );
  }

  static const initial = AccountsState(
    items: [],
    total: 0,
    loading: false,
    page: 0,
    pageSize: 10,
    search: '',
    type: null,
    sortBy: 'code',
    ascending: true,
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
    type,
    sortBy,
    ascending,
    error,
  ];
}
