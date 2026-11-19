import 'package:material_ui/material_ui.dart';
import '../../../attendance/domain/repos/attendance_identity_repo.dart';

class AttendanceNumberField extends StatelessWidget {
  const AttendanceNumberField({
    super.key,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.enabled = true,
  });
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return TextFormField(
      initialValue: controller == null ? initialValue : null,
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: ar
            ? 'رقم الموظف في جهاز البصمة (اختياري)'
            : 'Attendance device employee number (optional)',
        helperText: ar
            ? 'نفس رقم الشخص في iVMS؛ ليس رقم الموظف في ERP. احتفظ بالأصفار في بداية الرقم.'
            : 'Use the Person ID in iVMS, separate from the ERP employee number. Keep leading zeros.',
        helperMaxLines: 3,
        prefixIcon: const Icon(Icons.fingerprint),
        border: const OutlineInputBorder(),
      ),
      validator: (value) => isValidAttendanceNumber(value ?? '')
          ? null
          : (ar
                ? 'حتى 32 خانة: أرقام أو حروف إنجليزية أو _ أو -'
                : 'Up to 32 characters: letters, digits, _ or -'),
    );
  }
}
