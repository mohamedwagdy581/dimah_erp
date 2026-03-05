import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_di.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'sections/login_form_section.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(AppDI.authRepo),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is AuthSuccess) {
            context.go('/');
          }
        },
        child: const Scaffold(
          body: Center(child: SizedBox(width: 420, child: LoginFormSection())),
        ),
      ),
    );
  }
}
