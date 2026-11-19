import 'package:material_ui/material_ui.dart';
import '../../../core/di/app_di.dart';
import '../../auth/domain/repos/auth_repo.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, this.authRepo, this.onPasswordChanged});
  final AuthRepo? authRepo;
  final Future<void> Function()? onPasswordChanged;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _pass1 = TextEditingController();
  final _pass2 = TextEditingController();
  bool _loading = false;
  bool _hidePassword = true, _hideConfirmation = true, _submitted = false;
  static final _arabic = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => _ar ? a : e;

  String? get _passwordError {
    final password = _pass1.text;
    if (_arabic.hasMatch(password)) {
      return tr(
        'الكلمة تحتوي على حروف أو أرقام عربية. حوّل الكيبورد للإنجليزية وأعد كتابتها.',
        'Arabic characters detected. Switch your keyboard to English and retype the password.',
      );
    }
    if (password != password.trim()) {
      return tr(
        'احذف المسافات من بداية ونهاية كلمة المرور.',
        'Remove spaces at the start and end.',
      );
    }
    if (password.length < 12 ||
        !RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password) ||
        !RegExp(r'[^A-Za-z0-9\s]').hasMatch(password)) {
      return tr(
        'استخدم 12 حرفًا على الأقل، وحروفًا إنجليزية كبيرة وصغيرة ورقمًا ورمزًا.',
        'Use at least 12 characters, uppercase and lowercase English letters, a digit and a symbol.',
      );
    }
    return null;
  }

  @override
  void dispose() {
    _pass1.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _submitted = true);
    if (_passwordError != null || _pass1.text != _pass2.text) return;

    setState(() => _loading = true);
    try {
      await (widget.authRepo ?? AppDI.authRepo).changePassword(_pass1.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('تم تحديث كلمة المرور بنجاح', 'Password updated')),
        ),
      );
      _pass1.clear();
      _pass2.clear();
      setState(() {
        _submitted = false;
        _hidePassword = true;
        _hideConfirmation = true;
      });
      await widget.onPasswordChanged?.call();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذّر تحديث كلمة المرور. تحقق من الاتصال وصلاحية رابط الاستعادة ثم أعد المحاولة.',
              'Could not update the password. Check your connection and recovery link, then retry.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration fieldDecoration(
      String label,
      bool hidden,
      VoidCallback toggle,
      String? error,
    ) => InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      errorText: error,
      errorMaxLines: 4,
      suffixIcon: IconButton(
        tooltip: hidden
            ? tr('إظهار كلمة المرور', 'Show password')
            : tr('إخفاء كلمة المرور', 'Hide password'),
        onPressed: _loading ? null : toggle,
        icon: Icon(
          hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 520,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr('تغيير كلمة المرور', 'Change Password'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'تأكد أن لغة الكيبورد إنجليزية. اضغط على العين لمراجعة الكلمة قبل الحفظ.',
                      'Use the English keyboard. Tap the eye to check your password before saving.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF777194),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pass1,
                    obscureText: _hidePassword,
                    enabled: !_loading,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    autocorrect: false,
                    enableSuggestions: false,
                    onChanged: (_) => setState(() {}),
                    decoration: fieldDecoration(
                      tr('كلمة المرور الجديدة', 'New Password'),
                      _hidePassword,
                      () => setState(() => _hidePassword = !_hidePassword),
                      (_submitted || _pass1.text.isNotEmpty)
                          ? _passwordError
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass2,
                    obscureText: _hideConfirmation,
                    enabled: !_loading,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                    decoration: fieldDecoration(
                      tr('تأكيد كلمة المرور', 'Confirm Password'),
                      _hideConfirmation,
                      () => setState(
                        () => _hideConfirmation = !_hideConfirmation,
                      ),
                      (_submitted || _pass2.text.isNotEmpty) &&
                              _pass1.text != _pass2.text
                          ? tr(
                              'كلمتا المرور غير متطابقتين.',
                              'Passwords do not match.',
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final check in <(bool, String)>[
                    (
                      _pass1.text.length >= 12,
                      tr('12 حرفًا على الأقل', 'At least 12 characters'),
                    ),
                    (
                      RegExp(r'[A-Z]').hasMatch(_pass1.text) &&
                          RegExp(r'[a-z]').hasMatch(_pass1.text),
                      tr(
                        'حروف إنجليزية كبيرة وصغيرة',
                        'Uppercase and lowercase English letters',
                      ),
                    ),
                    (
                      RegExp(r'[0-9]').hasMatch(_pass1.text) &&
                          RegExp(r'[^A-Za-z0-9\s]').hasMatch(_pass1.text) &&
                          !_arabic.hasMatch(_pass1.text),
                      tr(
                        'رقم إنجليزي ورمز مثل @ أو #',
                        'An English digit and a symbol such as @ or #',
                      ),
                    ),
                    if (_pass2.text.isNotEmpty)
                      (
                        _pass1.text == _pass2.text,
                        tr('كلمتا المرور متطابقتان', 'Passwords match'),
                      ),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(
                            check.$1
                                ? Icons.check_circle_outline
                                : Icons.radio_button_unchecked,
                            size: 17,
                            color: check.$1
                                ? const Color(0xFF009B72)
                                : const Color(0xFF777194),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              check.$2,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(
                        _loading
                            ? tr('جارٍ الحفظ...', 'Updating...')
                            : tr('حفظ كلمة المرور', 'Update'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
