import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_user.dart';
import 'session_repo.dart';

sealed class SessionState {
  const SessionState();
}

class SessionLoading extends SessionState {
  const SessionLoading();
}

class SessionUnauthed extends SessionState {
  const SessionUnauthed();
}

class SessionReady extends SessionState {
  const SessionReady(this.user);
  final AppUser user;
}

class SessionFailed extends SessionState {
  const SessionFailed();
}

class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._repo) : super(const SessionLoading());
  final SessionRepo _repo;

  Future<void> load() async {
    emit(const SessionLoading());
    try {
      final user = await _repo.getCurrentAppUser();
      if (isClosed) return;
      if (user == null) {
        emit(const SessionUnauthed());
      } else {
        emit(SessionReady(user));
      }
    } catch (_) {
      if (!isClosed) emit(const SessionFailed());
    }
  }
}
