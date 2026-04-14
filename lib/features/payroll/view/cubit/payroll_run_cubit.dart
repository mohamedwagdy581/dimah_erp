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

      // Fetch items and all runs to find the specific one
      final List<PayrollItem> items = await _repo.fetchRunItems(runId: runId);
      final runsResult = await _repo.fetchRuns(
        page: 0,
        pageSize: 100,
        sortBy: 'created_at',
      );

      final List<PayrollRun> allRuns = runsResult.items;
      PayrollRun? currentRun;
      for (final run in allRuns) {
        if (run.id == runId) {
          currentRun = run;
          break;
        }
      }

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
