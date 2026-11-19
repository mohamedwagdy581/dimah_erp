import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../attendance/domain/models/attendance_record.dart';
import '../cubit/employee_attendance_cubit.dart';

class EmployeeAttendanceCorrectionDialog extends StatefulWidget {
  const EmployeeAttendanceCorrectionDialog({super.key, required this.record});
  final AttendanceRecord record;
  @override
  State<EmployeeAttendanceCorrectionDialog> createState() => _CorrectionState();
}

class _CorrectionState extends State<EmployeeAttendanceCorrectionDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  DateTime? _in, _out;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _in = widget.record.checkIn?.toLocal();
    _out = widget.record.checkOut?.toLocal();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pick(bool arrival) async {
    final value = arrival ? _in : _out;
    final day = await showDatePicker(
      context: context,
      initialDate: value ?? widget.record.date,
      firstDate: DateTime(widget.record.date.year - 1),
      lastDate: DateTime(widget.record.date.year + 1, 12, 31),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: value == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(value),
    );
    if (time == null || !mounted) return;
    setState(() {
      final date = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      );
      if (arrival) {
        _in = date;
      } else {
        _out = date;
      }
    });
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    if (_in == null || _out == null || !_out!.isAfter(_in!)) {
      setState(
        () => _error = ar
            ? 'حدد تاريخ ووقت الحضور والانصراف؛ الانصراف يجب أن يكون بعد الحضور.'
            : 'Choose arrival and departure dates and times. Departure must follow arrival.',
      );
      return;
    }
    if (widget.record.checkIn?.isAtSameMomentAs(_in!) == true &&
        widget.record.checkOut?.isAtSameMomentAs(_out!) == true) {
      setState(
        () => _error = ar
            ? 'غيّر أحد المواعيد المسجلة أولًا.'
            : 'Change at least one recorded time first.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<EmployeeAttendanceCubit>().requestCorrection(
        record: widget.record,
        checkIn: _in!,
        checkOut: _out!,
        reason: _reason.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = ar
              ? 'تعذّر إرسال التصحيح. حدّث السجل ثم حاول مجددًا.'
              : 'Unable to submit correction. Refresh the record and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final t = AppLocalizations.of(context)!;
    String time(DateTime? v, String label) => v == null
        ? label
        : '${v.year}/${v.month.toString().padLeft(2, '0')}/${v.day.toString().padLeft(2, '0')}  ${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(ar ? 'طلب تصحيح الحضور' : 'Request attendance correction'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ar
                        ? 'راجع المواعيد بتوقيت جهازك. يُرسل التصحيح للمراجعة ولا يغيّر السجل مباشرة.'
                        : 'Review times in your device timezone. Corrections require approval and do not directly change your record.',
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    key: const ValueKey('correction-in'),
                    onPressed: _saving ? null : () => _pick(true),
                    icon: const Icon(Icons.login),
                    label: Text(
                      time(_in, ar ? 'حدد الحضور' : 'Choose arrival'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('correction-out'),
                    onPressed: _saving ? null : () => _pick(false),
                    icon: const Icon(Icons.logout),
                    label: Text(
                      time(_out, ar ? 'حدد الانصراف' : 'Choose departure'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('attendance-correction-reason'),
                    controller: _reason,
                    enabled: !_saving,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: ar ? 'سبب التصحيح' : 'Correction reason',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? (ar ? 'اكتب سبب التصحيح' : 'Enter a reason')
                        : null,
                  ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (_saving) const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            key: const ValueKey('attendance-correction-submit'),
            onPressed: _saving ? null : _submit,
            child: Text(
              _saving
                  ? t.saving
                  : (ar ? 'إرسال للمراجعة' : 'Submit for review'),
            ),
          ),
        ],
      ),
    );
  }
}
