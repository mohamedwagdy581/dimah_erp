import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginPressed extends AuthEvent {
  const AuthLoginPressed(this.email, this.password);
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutPressed extends AuthEvent {
  const AuthLogoutPressed();
}
