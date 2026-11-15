import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/manager_requests_repo.dart';

class ManagerRequestsState {
  const ManagerRequestsState({
    this.data = const ManagerRequestsData(),
    this.loading = false,
    this.saving = false,
    this.failed = false,
    this.saveFailed = false,
    this.error,
  });
  final ManagerRequestsData data;
  final bool loading, saving, failed, saveFailed;
  final Object? error;
}

class ManagerRequestsCubit extends Cubit<ManagerRequestsState> {
  ManagerRequestsCubit(this.repo) : super(const ManagerRequestsState());
  final ManagerRequestsRepo repo;
  Future<void> load() async {
    if (state.loading || state.saving) return;
    emit(ManagerRequestsState(data: state.data, loading: true));
    try {
      final data = await repo.load();
      if (!isClosed) emit(ManagerRequestsState(data: data));
    } catch (error) {
      if (!isClosed) {
        emit(
          ManagerRequestsState(data: state.data, failed: true, error: error),
        );
      }
    }
  }

  Future<bool> decide(String id, bool approve, String reason) async {
    if (state.saving || state.loading || (!approve && reason.trim().isEmpty)) {
      return false;
    }
    final rows = state.data.rows.where((r) => r['id'].toString() == id);
    if (rows.isEmpty || !managerCanDecideRequest(rows.first, state.data.role)) {
      return false;
    }
    emit(ManagerRequestsState(data: state.data, saving: true));
    try {
      await repo.decide(id, approve, reason);
    } catch (error) {
      if (!isClosed) {
        emit(
          ManagerRequestsState(
            data: state.data,
            saveFailed: true,
            error: error,
          ),
        );
      }
      return false;
    }
    try {
      final data = await repo.load();
      if (!isClosed) emit(ManagerRequestsState(data: data));
    } catch (error) {
      // The decision succeeded; do not invite a duplicate submission after a refresh failure.
      if (!isClosed) {
        emit(
          ManagerRequestsState(
            data: ManagerRequestsData(
              role: state.data.role,
              rows: state.data.rows
                  .where((r) => r['id'].toString() != id)
                  .toList(),
            ),
            failed: true,
            error: error,
          ),
        );
      }
    }
    return true;
  }
}
