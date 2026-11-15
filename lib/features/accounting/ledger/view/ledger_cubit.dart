import 'package:flutter_bloc/flutter_bloc.dart';

import '../../accounts/domain/models/account.dart';
import '../../accounts/domain/repos/accounts_repo.dart';
import '../../reports/domain/accounting_reports_models.dart';
import '../../reports/domain/accounting_reports_repo.dart';

class LedgerState {
  const LedgerState({
    this.accounts = const [],
    this.accountId,
    required this.from,
    required this.to,
    this.loading = false,
    this.error,
    this.report,
  });

  final List<Account> accounts;
  final String? accountId;
  final DateTime from, to;
  final bool loading;
  final Object? error;
  final LedgerReport? report;

  LedgerState copyWith({
    List<Account>? accounts,
    String? accountId,
    DateTime? from,
    DateTime? to,
    bool? loading,
    Object? error,
    bool clearError = false,
    LedgerReport? report,
    bool clearReport = false,
  }) => LedgerState(
    accounts: accounts ?? this.accounts,
    accountId: accountId ?? this.accountId,
    from: from ?? this.from,
    to: to ?? this.to,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
    report: clearReport ? null : (report ?? this.report),
  );
}

class LedgerCubit extends Cubit<LedgerState> {
  LedgerCubit(this._reports, this._accounts, {required DateTime now})
    : super(
        LedgerState(
          from: DateTime(now.year, now.month),
          to: DateTime(now.year, now.month, now.day),
        ),
      );

  final AccountingReportsRepo _reports;
  final AccountsRepo _accounts;
  int _generation = 0;

  Future<void> init({String? accountId, DateTime? from, DateTime? to}) async {
    emit(
      state.copyWith(
        accountId: accountId,
        from: from,
        to: to,
        loading: true,
        clearError: true,
      ),
    );
    try {
      final result = await _accounts.fetchAccounts(page: 0, pageSize: 1000);
      if (isClosed) return;
      emit(state.copyWith(accounts: result.items, loading: false));
    } catch (e) {
      if (!isClosed) emit(state.copyWith(loading: false, error: e));
      return;
    }
    await refresh();
  }

  Future<void> selectAccount(String id) async {
    emit(state.copyWith(accountId: id, clearReport: true));
    await refresh();
  }

  Future<void> setRange(DateTime from, DateTime to) async {
    emit(state.copyWith(from: from, to: to));
    await refresh();
  }

  Future<void> refresh() async {
    if (state.accounts.isEmpty && state.error != null) {
      return init(accountId: state.accountId, from: state.from, to: state.to);
    }
    final id = state.accountId;
    if (id == null) return;
    final version = ++_generation;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final report = await _reports.fetchLedger(
        accountId: id,
        from: state.from,
        to: state.to,
      );
      if (isClosed || version != _generation) return;
      emit(state.copyWith(loading: false, report: report));
    } catch (e) {
      if (isClosed || version != _generation) return;
      emit(state.copyWith(loading: false, error: e, clearReport: true));
    }
  }
}
