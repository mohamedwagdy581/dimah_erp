import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeStatusDialog extends StatefulWidget {
  const EmployeeStatusDialog({
    super.key,
    required this.name,
    required this.inactive,
    required this.save,
  });
  final String name;
  final bool inactive;
  final Future<void> Function() save;

  @override
  State<EmployeeStatusDialog> createState() => _EmployeeStatusDialogState();
}

class _EmployeeStatusDialogState extends State<EmployeeStatusDialog> {
  bool busy = false;
  String? error;

  Future<void> submit(bool ar) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.save();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final missing =
          e is PostgrestException && ['PGRST202', '42883'].contains(e.code);
      setState(() {
        busy = false;
        error = missing
            ? (ar
                  ? 'شغّل ملف install_employee_status_management.sql لتفعيل إدارة حالة الموظفين.'
                  : 'Run install_employee_status_management.sql to enable employee status management.')
            : (ar
                  ? 'تعذّر تغيير الحالة. تحقق من الاتصال وصلاحياتك ثم أعد المحاولة. لا يمكن إيقاف حساب إداري مرتبط من هنا.'
                  : 'Could not change status. Check your connection and permissions, then retry. Linked administrative accounts cannot be disabled here.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final label = widget.inactive
        ? (ar ? 'إعادة تفعيل الموظف' : 'Reactivate employee')
        : (ar ? 'إيقاف الموظف' : 'Deactivate employee');
    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        title: Text(label),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                widget.inactive
                    ? (ar
                          ? 'سيعود الموظف إلى قائمة الموظفين الحاليين. حساب الدخول الموقوف يحتاج إعادة تفعيل من إدارة المستخدمين.'
                          : 'The employee will return to the current employee list. A disabled login must be reactivated in user management.')
                    : (ar
                          ? 'سينتقل الموظف إلى قائمة غير النشطين مع الاحتفاظ ببياناته وعقوده ورواتبه ومخالصاته. سيتم إيقاف حساب دخوله المرتبط.'
                          : 'The employee will move to the inactive list. All records and history will be preserved, and the linked login will be disabled.'),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context, false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton.icon(
            onPressed: busy ? null : () => submit(ar),
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    widget.inactive
                        ? Icons.person_add_alt_1
                        : Icons.person_off_outlined,
                  ),
            label: Text(busy ? (ar ? 'جارٍ الحفظ...' : 'Saving...') : label),
          ),
        ],
      ),
    );
  }
}
