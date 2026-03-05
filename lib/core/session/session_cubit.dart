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

class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._repo) : super(const SessionLoading());
  final SessionRepo _repo;

  Future<void> load() async {
    emit(const SessionLoading());
    final user = await _repo.getCurrentAppUser();
    if (user == null) {
      emit(const SessionUnauthed());
    } else {
      emit(SessionReady(user));
    }
  }
}
