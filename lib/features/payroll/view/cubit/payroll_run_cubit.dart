import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/payroll_item.dart';
import '../../domain/models/payroll_run.dart';
import '../../domain/repos/payroll_repo.dart';
import 'payroll_run_state.dart';

class PayrollRunCubit extends Cubit<PayrollRunState> {
  PayrollRunCubit(this._repo) : super(PayrollRunState.initial);

  final PayrollRepo _repo;

  Future<void> load(String runId) async {
    try {
      if (isClosed) return;
      emit(state.copyWith(loading: true, error: null));

      final List<PayrollItem> items = await _repo.fetchRunItems(runId: runId);
      PayrollRun? currentRun;
      // Continue across pages so older runs remain accessible from their URL.
      for (var page = 0; currentRun == null; page++) {
        final result = await _repo.fetchRuns(
          page: page,
          pageSize: 100,
          sortBy: 'created_at',
        );
        for (final run in result.items) {
          if (run.id == runId) {
            currentRun = run;
            break;
          }
        }
        if (result.items.isEmpty || (page + 1) * 100 >= result.total) break;
      }
      if (currentRun == null) throw StateError('Payroll run not found');

      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          items: items,
          run: currentRun,
          error: null,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
