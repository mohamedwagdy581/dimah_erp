import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/repos/auth_repo.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthIdle()) {
    on<AuthLoginPressed>(_onLogin);
    on<AuthLogoutPressed>(_onLogout);
  }

  final AuthRepo _repo;

  Future<void> _onLogin(AuthLoginPressed e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _repo.signIn(email: e.email, password: e.password);
      emit(const AuthSuccess());
    } catch (err) {
      emit(AuthFailure(err.toString()));
    } finally {
      emit(const AuthIdle());
    }
  }

  Future<void> _onLogout(AuthLogoutPressed e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _repo.signOut();
      emit(const AuthSuccess());
    } catch (err) {
      emit(AuthFailure(err.toString()));
    } finally {
      emit(const AuthIdle());
    }
  }
}
