import 'package:equatable/equatable.dart';
import '../../domain/models/payroll_item.dart';
import '../../domain/models/payroll_run.dart';

class PayrollRunState extends Equatable {
  const PayrollRunState({
    required this.items,
    required this.loading,
    this.run,
    this.error,
  });

  final List<PayrollItem> items;
  final bool loading;
  final PayrollRun? run;
  final String? error;

  PayrollRunState copyWith({
    List<PayrollItem>? items,
    bool? loading,
    PayrollRun? run,
    String? error,
  }) {
    return PayrollRunState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      run: run ?? this.run,
      error: error,
    );
  }

  static const initial = PayrollRunState(
    items: [],
    loading: false,
    run: null,
    error: null,
  );

  @override
  List<Object?> get props => [items, loading, run, error];
}
