import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_di.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'sections/login_form_section.dart';
import '../domain/repos/auth_repo.dart';
import 'widgets/login_workspace.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key, this.repo, this.onLoggedIn});
  final AuthRepo? repo;
  final VoidCallback? onLoggedIn;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(repo ?? AppDI.authRepo),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            if (onLoggedIn != null) {
              onLoggedIn!();
            } else {
              context.go('/');
            }
          }
        },
        child: const Scaffold(
          backgroundColor: Color(0xFFFAF9FD),
          body: LoginWorkspace(form: LoginFormSection()),
        ),
      ),
    );
  }
}
