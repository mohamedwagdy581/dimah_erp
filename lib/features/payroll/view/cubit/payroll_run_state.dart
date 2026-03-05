import 'package:equatable/equatable.dart';
import '../../domain/models/payroll_item.dart';

class PayrollRunState extends Equatable {
  const PayrollRunState({
    required this.items,
    required this.loading,
    this.error,
  });

  final List<PayrollItem> items;
  final bool loading;
  final String? error;

  PayrollRunState copyWith({
    List<PayrollItem>? items,
    bool? loading,
    String? error,
  }) {
    return PayrollRunState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  static const initial = PayrollRunState(
    items: [],
    loading: false,
    error: null,
  );

  @override
  List<Object?> get props => [items, loading, error];
}
