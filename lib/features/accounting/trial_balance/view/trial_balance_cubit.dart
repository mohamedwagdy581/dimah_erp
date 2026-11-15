import 'package:flutter_bloc/flutter_bloc.dart';

import '../../reports/domain/accounting_reports_models.dart';
import '../../reports/domain/accounting_reports_repo.dart';

class TrialBalanceState {
  const TrialBalanceState({
    required this.asOf,
    this.hideZero = true,
    this.loading = false,
    this.error,
    this.rows = const [],
  });

  final DateTime asOf;
  final bool hideZero, loading;
  final Object? error;
  final List<TrialBalanceRow> rows;

  List<TrialBalanceRow> get visibleRows =>
      hideZero ? rows.where((r) => !r.isZero).toList() : rows;
  num get totalDebit => rows.fold<num>(0, (s, r) => s + r.debit);
  num get totalCredit => rows.fold<num>(0, (s, r) => s + r.credit);
  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.005;

  TrialBalanceState copyWith({
    DateTime? asOf,
    bool? hideZero,
    bool? loading,
    Object? error,
    bool clearError = false,
    List<TrialBalanceRow>? rows,
  }) => TrialBalanceState(
    asOf: asOf ?? this.asOf,
    hideZero: hideZero ?? this.hideZero,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
    rows: rows ?? this.rows,
  );
}

class TrialBalanceCubit extends Cubit<TrialBalanceState> {
  TrialBalanceCubit(this._repo, {required DateTime now})
    : super(TrialBalanceState(asOf: DateTime(now.year, now.month, now.day)));

  final AccountingReportsRepo _repo;
  int _generation = 0;

  Future<void> load() async {
    final version = ++_generation;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final rows = await _repo.fetchTrialBalance(state.asOf);
      if (isClosed || version != _generation) return;
      emit(state.copyWith(loading: false, rows: rows));
    } catch (e) {
      if (isClosed || version != _generation) return;
      emit(state.copyWith(loading: false, error: e, rows: const []));
    }
  }

  Future<void> setAsOf(DateTime d) async {
    emit(state.copyWith(asOf: DateTime(d.year, d.month, d.day)));
    await load();
  }

  void toggleHideZero(bool v) => emit(state.copyWith(hideZero: v));
}
