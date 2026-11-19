import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';

class LoginFormSection extends StatefulWidget {
  const LoginFormSection({super.key});
  @override
  State<LoginFormSection> createState() => _LoginFormSectionState();
}

class _LoginFormSectionState extends State<LoginFormSection> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true, _pending = false;
  String? _failure;
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => ar ? a : e;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_pending || context.read<AuthBloc>().state is AuthLoading) return;
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _pending = true;
      _failure = null;
    });
    context.read<AuthBloc>().add(
      AuthLoginPressed(_email.text.trim(), _password.text),
    );
  }

  void _changed(String _) {
    if (_failure != null) setState(() => _failure = null);
  }

  String _errorMessage(String message) {
    if (message.toLowerCase().contains('invalid login credentials')) {
      return tr(
        'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
        'Email or password is incorrect.',
      );
    }
    return tr(
      'تعذّر تسجيل الدخول. تحقق من الاتصال وحاول مرة أخرى.',
      'Unable to sign in. Check your connection and try again.',
    );
  }

  InputDecoration _decoration({Widget? prefix, Widget? suffix}) =>
      InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: prefix,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: _failure != null
                ? const Color(0xFFFF4056)
                : const Color(0xFFDAD4EB),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFDAD4EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF8654BC), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFFF4056)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFFF4056), width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 12),
      );
  Widget _label(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF171359),
          ),
        ),
        const Text(
          ' *',
          style: TextStyle(color: Color(0xFFF44355), fontSize: 14),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    listener: (context, state) {
      if (state is AuthFailure) {
        setState(() {
          _pending = false;
          _failure = _errorMessage(state.message);
        });
      }
      if (state is AuthSuccess) setState(() => _pending = false);
    },
    child: AutofillGroup(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('تسجيل الدخول', 'Sign in'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0E0954),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              tr('مرحبًا بك في نظام DIMAH ERP', 'Welcome to DIMAH ERP'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF514999),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (_failure != null) ...[
              Semantics(
                liveRegion: true,
                child: Container(
                  key: const ValueKey('login-error'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFFC2CA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFED203A),
                        size: 21,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _failure!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFB21B30),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            _label(tr('البريد الإلكتروني', 'Email')),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextFormField(
                key: const ValueKey('login-email'),
                controller: _email,
                enabled: !_pending,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(fontSize: 13, color: Color(0xFF171359)),
                decoration: _decoration(
                  prefix: const Icon(
                    Icons.mail_outline,
                    size: 21,
                    color: Color(0xFF514999),
                  ),
                ),
                validator: (v) =>
                    RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch((v ?? '').trim())
                    ? null
                    : tr(
                        'أدخل بريدًا إلكترونيًا صحيحًا',
                        'Enter a valid email',
                      ),
                onChanged: _changed,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
            ),
            const SizedBox(height: 22),
            _label(tr('كلمة المرور', 'Password')),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextFormField(
                key: const ValueKey('login-password'),
                controller: _password,
                focusNode: _passwordFocus,
                enabled: !_pending,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(fontSize: 14, color: Color(0xFF171359)),
                decoration: _decoration(
                  suffix: IconButton(
                    key: const ValueKey('login-visibility'),
                    tooltip: _obscure
                        ? tr('إظهار كلمة المرور', 'Show password')
                        : tr('إخفاء كلمة المرور', 'Hide password'),
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 21,
                      color: const Color(0xFF514999),
                    ),
                  ),
                ),
                validator: (v) => (v ?? '').isEmpty
                    ? tr('أدخل كلمة المرور', 'Enter your password')
                    : null,
                onChanged: _changed,
                onFieldSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: 28),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: const Key('forgot-password'),
                onPressed: _pending
                    ? null
                    : () => context.go(
                        '${AppRoutes.recoverPassword}?email=${Uri.encodeQueryComponent(_email.text.trim())}',
                      ),
                child: Text(tr('نسيت كلمة المرور؟', 'Forgot your password?')),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8654BC), Color(0xFF9367C2)],
                ),
              ),
              child: TextButton(
                key: const ValueKey('login-submit'),
                onPressed: _pending ? null : _submit,
                child: _pending
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            tr('جاري تسجيل الدخول...', 'Signing in...'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : Text(
                        tr('تسجيل الدخول', 'Sign in'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily:
                              Theme.of(
                                context,
                              ).textTheme.bodyMedium?.fontFamily ??
                              'Roboto',
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
