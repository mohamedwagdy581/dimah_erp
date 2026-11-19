import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../l10n/app_localizations.dart';
import 'employee_profile_cubit.dart';

String profileInitials(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .take(2)
    .map((word) => word.characters.first)
    .join(' ');
String profilePhoneDigits(String value) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  for (var i = 0; i < 10; i++) {
    value = value.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
  }
  return value.trim();
}

class EmployeeProfileView extends StatefulWidget {
  const EmployeeProfileView({
    super.key,
    required this.email,
    required this.onPassword,
    required this.onLogout,
  });
  final String email;
  final VoidCallback onPassword;
  final Future<void> Function() onLogout;
  @override
  State<EmployeeProfileView> createState() => _EmployeeProfileViewState();
}

class _EmployeeProfileViewState extends State<EmployeeProfileView> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _loggingOut = false;
  @override
  void initState() {
    super.initState();
    final state = context.read<EmployeeProfileCubit>().state;
    if (state.loaded) _restore(state);
  }

  void _restore(EmployeeProfileState state) {
    _form.currentState?.reset();
    _name.text = state.name;
    _phone.text = state.phone;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await widget.onLogout();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تعذّر تسجيل الخروج؛ حاول مجددًا'
                  : 'Unable to sign out. Try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<EmployeeProfileCubit, EmployeeProfileState>(
    listener: (context, state) {
      if (state.loaded &&
          !state.saving &&
          state.saveError == null &&
          state.error == null) {
        _restore(state);
      }
      if (state.saveVersion > 0 && !state.saving && state.saveError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تم حفظ بيانات الحساب'
                  : 'Account details saved',
            ),
          ),
        );
      }
    },
    listenWhen: (previous, current) =>
        (!previous.loaded && current.loaded) ||
        previous.saveVersion != current.saveVersion,
    builder: (context, state) {
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      final t = AppLocalizations.of(context)!;
      final cs = Theme.of(context).colorScheme;
      final busy = state.saving || _loggingOut;
      Widget title(String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '$text${required ? ' *' : ''}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      );
      InputDecoration field({IconData? icon, bool readOnly = false}) =>
          InputDecoration(
            prefixIcon: icon == null ? null : Icon(icon, size: 20),
            filled: true,
            fillColor: readOnly
                ? (Theme.of(context).brightness == Brightness.dark
                      ? cs.surfaceContainerLow
                      : const Color(0xFFF3F5F8))
                : cs.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: cs.outlineVariant.withValues(alpha: .5),
              ),
            ),
          );
      final banner = Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.primary.withValues(alpha: .2)),
        ),
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: cs.primary,
              child: profileInitials(state.name).isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 36)
                  : Text(
                      profileInitials(state.name),
                      style: const TextStyle(color: Colors.white, fontSize: 26),
                    ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: ar
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    state.name.isEmpty
                        ? (ar ? 'بيانات حسابك' : 'Your account')
                        : state.name,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ar ? 'موظف' : 'Employee',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 17),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      final name = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title(ar ? 'الاسم' : 'Name', required: true),
          TextFormField(
            key: const ValueKey('employee-profile-name'),
            controller: _name,
            enabled: state.loaded && !busy,
            textCapitalization: TextCapitalization.words,
            decoration: field(),
            validator: (value) => (value ?? '').trim().isEmpty
                ? (ar ? 'اكتب الاسم' : 'Enter your name')
                : null,
          ),
        ],
      );
      final phone = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title(ar ? 'رقم الجوال' : 'Mobile number', required: true),
          TextFormField(
            key: const ValueKey('employee-profile-phone'),
            controller: _phone,
            enabled: state.loaded && !busy,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.phone,
            decoration: field(icon: Icons.phone_outlined),
            validator: (value) {
              final v = profilePhoneDigits(value ?? '');
              final digits = v.replaceAll(RegExp(r'\D'), '');
              return !RegExp(r'^\+?[0-9 ()-]+$').hasMatch(v) ||
                      digits.length < 7 ||
                      digits.length > 15
                  ? (ar
                        ? 'اكتب رقم جوال صحيحًا'
                        : 'Enter a valid mobile number')
                  : null;
            },
          ),
        ],
      );
      final email = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title(ar ? 'البريد الإلكتروني' : 'Email'),
          TextFormField(
            key: const ValueKey('employee-profile-email'),
            initialValue: widget.email,
            readOnly: true,
            textDirection: TextDirection.ltr,
            decoration: field(icon: Icons.email_outlined, readOnly: true),
          ),
        ],
      );
      final form = _ProfilePanel(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ar ? 'بيانات الحساب' : 'Account details',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ar
                    ? 'يمكنك تحديث بعض بيانات حسابك الشخصية'
                    : 'Update your personal account details',
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 26),
              name,
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) =>
                    constraints.maxWidth >=
                        650 * (MediaQuery.textScalerOf(context).scale(14) / 14)
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: email),
                          const SizedBox(width: 20),
                          Expanded(child: phone),
                        ],
                      )
                    : Column(
                        children: [email, const SizedBox(height: 20), phone],
                      ),
              ),
              const SizedBox(height: 24),
              title(ar ? 'الدور' : 'Role'),
              TextFormField(
                key: const ValueKey('employee-profile-role'),
                initialValue: ar ? 'موظف' : 'Employee',
                readOnly: true,
                decoration: field(readOnly: true),
              ),
              if (state.saveError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    t.saveFailed(state.saveError!),
                    style: TextStyle(color: cs.error),
                  ),
                ),
              if (state.saving)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 26),
              const Divider(),
              const SizedBox(height: 18),
              Wrap(
                textDirection: TextDirection.ltr,
                alignment: WrapAlignment.start,
                spacing: 12,
                runSpacing: 10,
                children: [
                  FilledButton(
                    key: const ValueKey('employee-profile-save'),
                    onPressed: state.loaded && !busy
                        ? () {
                            if (_form.currentState!.validate()) {
                              context.read<EmployeeProfileCubit>().save(
                                name: _name.text,
                                phone: profilePhoneDigits(_phone.text),
                              );
                            }
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      state.saving
                          ? t.saving
                          : (ar ? 'حفظ التغييرات' : 'Save changes'),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  OutlinedButton(
                    key: const ValueKey('employee-profile-cancel'),
                    onPressed: state.loaded && !busy
                        ? () => _restore(state)
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 16,
                      ),
                      side: BorderSide(color: cs.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(t.cancel),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      final info = _ProfilePanel(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: cs.primary, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ar ? 'معلومات' : 'Information',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                ar
                    ? 'يمكنك تحديث الاسم ورقم الجوال. لتعديل البيانات الوظيفية تواصل مع الموارد البشرية.'
                    : 'You can update your name and mobile number. Contact HR to change employment details.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
      final security = _ProfilePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ar ? 'أمان الحساب' : 'Account security',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              ar
                  ? 'يمكنك تغيير كلمة المرور الخاصة بحسابك من هنا'
                  : 'Manage your account password here',
              style: TextStyle(
                fontSize: 15,
                height: 1.7,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              key: const ValueKey('employee-profile-password'),
              onPressed: busy ? null : widget.onPassword,
              icon: const Icon(Icons.lock_outline),
              label: Text(t.changePassword),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                side: BorderSide(color: cs.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
      return ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              key: const ValueKey('employee-profile-logout'),
              onPressed: busy ? null : _logout,
              icon: const Icon(Icons.logout),
              label: Text(t.logout),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            ar ? 'الملف الشخصي' : 'Personal profile',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            ar
                ? 'إدارة بيانات حسابك الشخصي في نظام DIMAH ERP'
                : 'Manage your personal DIMAH ERP account',
            style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 26),
          if (state.loading)
            const Padding(padding: EdgeInsets.all(30), child: AppLoadingState())
          else if (state.error != null && !state.loaded)
            _ProfilePanel(
              child: AppFailureState(
                error: state.error,
                onRetry: context.read<EmployeeProfileCubit>().load,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final primary = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [banner, const SizedBox(height: 20), form],
                );
                final secondary = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [info, const SizedBox(height: 20), security],
                );
                return constraints.maxWidth >=
                        1050 * (MediaQuery.textScalerOf(context).scale(14) / 14)
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: secondary),
                          const SizedBox(width: 20),
                          Expanded(flex: 2, child: primary),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          primary,
                          const SizedBox(height: 20),
                          secondary,
                        ],
                      );
              },
            ),
        ],
      );
    },
  );
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surface
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: .4),
      ),
    ),
    child: child,
  );
}
