import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/app_assets.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../widgets/email_field.dart';
import '../widgets/password_field.dart';
import '../widgets/primary_button.dart';

class LoginFormSection extends StatefulWidget {
  const LoginFormSection({super.key});

  @override
  State<LoginFormSection> createState() => _LoginFormSectionState();
}

class _LoginFormSectionState extends State<LoginFormSection> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthBloc>().add(AuthLoginPressed(_email.text, _pass.text));
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AuthBloc, bool>(
      (b) => b.state is AuthLoading,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppAssets.fullLogo, height: 60),
            const SizedBox(height: 12),
            const Text(
              'تسجيل الدخول',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            EmailField(controller: _email, onSubmit: _submit),
            const SizedBox(height: 12),
            PasswordField(controller: _pass, onSubmit: _submit),
            const SizedBox(height: 16),
            PrimaryButton(
              label: loading ? 'جاري الدخول...' : 'دخول',
              onPressed: loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
