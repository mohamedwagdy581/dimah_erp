import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:material_ui/material_ui.dart';
import '../../../attendance/domain/repos/attendance_identity_repo.dart';
import 'attendance_number_field.dart';

class EmployeeAttendanceIdentityDialog extends StatefulWidget {
  const EmployeeAttendanceIdentityDialog({
    super.key,
    required this.employeeId,
    required this.repo,
  });
  final String employeeId;
  final AttendanceIdentityRepo repo;

  @override
  State<EmployeeAttendanceIdentityDialog> createState() =>
      _EmployeeAttendanceIdentityDialogState();
}

class _EmployeeAttendanceIdentityDialogState
    extends State<EmployeeAttendanceIdentityDialog> {
  final _controller = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loaded = false;
      _error = null;
    });
    try {
      final value = await widget.repo.fetch(widget.employeeId);
      if (!mounted) return;
      _controller.text = value ?? '';
      setState(() {
        _loading = false;
        _loaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _save() async {
    if (!_loaded || _saving || !(_form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repo.save(widget.employeeId, _controller.text);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(
          ar ? 'ربط الموظف بجهاز البصمة' : 'Link employee to attendance device',
        ),
        content: SizedBox(
          width: 460,
          child: _loading
              ? const AppLoadingState()
              : Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AttendanceNumberField(
                        controller: _controller,
                        enabled: _loaded && !_saving,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ar
                            ? 'ترك الخانة فارغة ثم الحفظ يلغي الربط فقط. سجلات الحضور السابقة تظل محفوظة.'
                            : 'Save an empty number to unlink. Existing attendance records remain.',
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        actions: [
          if (_error != null && !_saving)
            TextButton(
              onPressed: _load,
              child: Text(ar ? 'إعادة تحميل' : 'Reload'),
            ),
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: !_loaded || _loading || _saving ? null : _save,
            child: Text(
              _saving
                  ? (ar ? 'جارٍ الحفظ...' : 'Saving...')
                  : (ar ? 'حفظ الربط' : 'Save link'),
            ),
          ),
        ],
      ),
    );
  }
}
