import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/di/app_di.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/ui/app_data_state.dart';
import '../../accounting/view/accounting_ui.dart';
import '../data/repos/password_recovery_repo.dart';
import 'widgets/login_workspace.dart';

String normalizeRecoveryCode(
  String value,
) => value.replaceAll(RegExp(r'\s'), '').replaceAllMapped(RegExp('[٠-٩۰-۹]'), (
  match,
) {
  const arabic = '٠١٢٣٤٥٦٧٨٩', persian = '۰۱۲۳۴۵۶۷۸۹';
  final digit = match[0]!;
  return '${arabic.contains(digit) ? arabic.indexOf(digit) : persian.indexOf(digit)}';
});

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({
    super.key,
    this.repo,
    this.initialEmail,
    this.onVerified,
    this.onCancel,
  });
  final PasswordRecoveryRepo? repo;
  final String? initialEmail;
  final VoidCallback? onVerified, onCancel;
  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  late final repo = widget.repo ?? SupabasePasswordRecoveryRepo(AppDI.supabase);
  late final email = TextEditingController(text: widget.initialEmail);
  final code = TextEditingController();
  final form = GlobalKey<FormState>();
  bool sent = false, busy = false;
  int seconds = 0;
  Timer? timer;
  String? error;
  @override
  void dispose() {
    timer?.cancel();
    email.dispose();
    code.dispose();
    super.dispose();
  }

  String tr(String ar, String en) => accountingText(context, ar, en);
  void cooldown() {
    timer?.cancel();
    seconds = 60;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => seconds--);
      if (seconds <= 0) timer?.cancel();
    });
  }

  Future<void> send() async {
    if (busy || seconds > 0) return;
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await repo.sendCode(email.text.trim());
      if (mounted) {
        setState(() {
          sent = true;
          code.clear();
          cooldown();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is AuthException && e.statusCode == '429'
              ? tr(
                  'طلبات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.',
                  'Too many requests. Please wait and retry.',
                )
              : tr(
                  'تعذر إرسال رسالة الاستعادة. تحقق من الاتصال ثم حاول مرة أخرى.',
                  'Could not send the recovery email. Check your connection and retry.',
                ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> verify() async {
    if (busy) return;
    final token = normalizeRecoveryCode(code.text);
    if (!RegExp(r'^[0-9]{6,10}$').hasMatch(token)) {
      setState(
        () => error = tr(
          'أدخل الكود الرقمي الموجود في أحدث رسالة استعادة.',
          'Enter the numeric code from your latest recovery email.',
        ),
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await repo.verifyCode(email.text.trim(), token);
      if (!mounted) return;
      code.clear();
      if (widget.onVerified != null) {
        widget.onVerified!();
      } else {
        context.go(AppRoutes.resetPassword);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = classifyDataFailure(e) == DataFailureKind.connection
              ? tr(
                  'تعذر الاتصال. تحقق من الإنترنت ثم أعد المحاولة.',
                  'Could not connect. Check your internet and retry.',
                )
              : tr(
                  'الكود غير صحيح أو انتهت صلاحيته. استخدم أحدث رسالة، أو اطلب كودًا جديدًا.',
                  'The code is invalid or expired. Use the latest email or request a new code.',
                ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      backgroundColor: const Color(0xFFFAF9FD),
      body: LoginWorkspace(
        form: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset, size: 42, color: accountingPurple),
              const SizedBox(height: 16),
              Text(
                tr('استعادة كلمة المرور', 'Recover your password'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: accountingInk,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr(
                  'استعد حسابك بكود يصل إلى بريدك الإلكتروني.',
                  'Recover your account using a code sent to your email.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF77709A)),
              ),
              const SizedBox(height: 22),
              TextFormField(
                key: const Key('recovery-email'),
                controller: email,
                enabled: !sent && !busy,
                textDirection: TextDirection.ltr,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: accountingInput(
                  tr('البريد الإلكتروني', 'Email'),
                ).copyWith(prefixIcon: const Icon(Icons.mail_outline)),
                validator: (v) =>
                    RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                    ).hasMatch((v ?? '').trim())
                    ? null
                    : tr(
                        'أدخل بريدًا إلكترونيًا صحيحًا.',
                        'Enter a valid email address.',
                      ),
              ),
              if (sent) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tr(
                      'لو البريد مرتبط بحساب، هتوصلك رسالة استعادة. أدخل الكود هنا من غير فتح رابط في المتصفح.',
                      'If the email belongs to an account, you will receive a recovery email. Enter its code here without opening a browser link.',
                    ),
                    style: const TextStyle(color: Color(0xFF16845D)),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  key: const Key('recovery-code'),
                  controller: code,
                  enabled: !busy,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: accountingInput(
                    tr('كود الاستعادة', 'Recovery code'),
                  ).copyWith(prefixIcon: const Icon(Icons.password)),
                  onSubmitted: (_) => verify(),
                ),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Color(0xFFCF3547)),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 22),
              FilledButton(
                key: const Key('recovery-submit'),
                onPressed: busy || (!sent && seconds > 0)
                    ? null
                    : sent
                    ? verify
                    : send,
                style: FilledButton.styleFrom(
                  backgroundColor: accountingPurple,
                  padding: const EdgeInsets.all(15),
                ),
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        !sent && seconds > 0
                            ? tr(
                                'الإرسال بعد $seconds ثانية',
                                'Send in $seconds seconds',
                              )
                            : tr(
                                sent ? 'تأكيد الكود' : 'إرسال كود الاستعادة',
                                sent ? 'Verify code' : 'Send recovery code',
                              ),
                      ),
              ),
              if (sent)
                TextButton(
                  onPressed: busy || seconds > 0 ? null : send,
                  child: Text(
                    seconds > 0
                        ? tr(
                            'إعادة الإرسال بعد $seconds ثانية',
                            'Resend in $seconds seconds',
                          )
                        : tr('إرسال كود جديد', 'Send a new code'),
                  ),
                ),
              if (sent)
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          sent = false;
                          code.clear();
                          error = null;
                        }),
                  child: Text(tr('تغيير البريد الإلكتروني', 'Change email')),
                ),
              TextButton(
                onPressed: busy
                    ? null
                    : () {
                        if (widget.onCancel != null) {
                          widget.onCancel!();
                        } else {
                          context.go(AppRoutes.login);
                        }
                      },
                child: Text(tr('العودة لتسجيل الدخول', 'Back to sign in')),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
