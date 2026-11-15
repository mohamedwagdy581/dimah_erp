import 'package:flutter/material.dart';
import '../../../domain/models/employee_login_result.dart';
import '../../../domain/repos/employee_repo.dart';

/// Completes Auth provisioning for an existing employee, without recreating it.
class EmployeeLoginDialog extends StatefulWidget {
  const EmployeeLoginDialog({
    super.key,
    required this.repo,
    required this.employeeId,
    required this.email,
  });
  final EmployeesRepo repo;
  final String employeeId, email;
  @override
  State<EmployeeLoginDialog> createState() => _EmployeeLoginDialogState();
}

class _EmployeeLoginDialogState extends State<EmployeeLoginDialog> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  String _role = 'employee';
  bool _busy = false, _obscure = true;
  String? _error;
  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  String tr(String ar, String en) =>
      Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
  Future<void> _save() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repo.checkEmployeeCreationReady();
      final result = await widget.repo.provisionEmployeeLogin(
        employeeId: widget.employeeId,
        role: _role,
        initialPassword: _password.text,
      );
      if (!mounted) return;
      _password.clear();
      Navigator.pop(context, result);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(tr('تجهيز حساب دخول الموظف', 'Set up employee login')),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.email, textDirection: TextDirection.ltr),
                const SizedBox(height: 10),
                Text(
                  tr(
                    'سيتم إنشاء الحساب وربطه بهذا الموظف. إذا كان الحساب موجودًا، سيحتفظ بكلمة مروره الحالية.',
                    'Create and link a login for this employee. Existing accounts keep their current password.',
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: tr('صلاحية الحساب', 'Account role'),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'employee',
                      child: Text(tr('موظف', 'Employee')),
                    ),
                    DropdownMenuItem(
                      value: 'manager',
                      child: Text(tr('مدير مباشر', 'Direct manager')),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                          _role = value!;
                        }),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('employee-login-password'),
                  controller: _password,
                  enabled: !_busy,
                  obscureText: _obscure,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: tr(
                      'كلمة مرور أولية للحساب الجديد',
                      'Initial password for a new account',
                    ),
                    suffixIcon: IconButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _obscure = !_obscure;
                            }),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) =>
                      isValidEmployeeLoginPassword(value ?? '')
                      ? null
                      : tr(
                          '12 حرفًا على الأقل مع حروف كبيرة وصغيرة ورقم ورمز',
                          'At least 12 characters, with upper/lowercase, a number and a symbol',
                        ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(tr('إلغاء', 'Cancel')),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(tr('تجهيز الحساب', 'Set up login')),
        ),
      ],
    ),
  );
}
