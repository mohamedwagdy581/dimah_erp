import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_error.dart';
import '../../domain/repos/payroll_repo.dart';
import 'payroll_run_state.dart';

class PayrollRunCubit extends Cubit<PayrollRunState> {
  PayrollRunCubit(this._repo) : super(PayrollRunState.initial);

  final PayrollRepo _repo;

  Future<void> load(String runId) async {
    try {
      if (isClosed) return;
      emit(state.copyWith(loading: true, error: null));
      final items = await _repo.fetchRunItems(runId: runId);
      if (isClosed) return;
      emit(state.copyWith(loading: false, items: items, error: null));
    } catch (e) {
      if (AppError.isTransient(e)) {
        if (isClosed) return;
        emit(state.copyWith(loading: false, error: null));
        return;
      }
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: AppError.message(e)));
    }
  }
}
