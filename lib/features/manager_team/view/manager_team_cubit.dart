import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/manager_team_repo.dart';
import '../domain/manager_team_data.dart';

class ManagerTeamState {
  const ManagerTeamState({
    this.loading = true,
    this.failed = false,
    this.data,
    this.error,
  });
  final bool loading, failed;
  final Object? error;
  final ManagerTeamData? data;
}

class ManagerTeamCubit extends Cubit<ManagerTeamState> {
  ManagerTeamCubit(this.repo) : super(const ManagerTeamState());
  final ManagerTeamRepo repo;
  int _request = 0;
  Future<void> load() async {
    final request = ++_request;
    emit(const ManagerTeamState());
    try {
      final data = await repo.load();
      if (!isClosed && request == _request) {
        emit(ManagerTeamState(loading: false, data: data));
      }
    } catch (error) {
      if (!isClosed && request == _request) {
        emit(ManagerTeamState(loading: false, failed: true, error: error));
      }
    }
  }
}
