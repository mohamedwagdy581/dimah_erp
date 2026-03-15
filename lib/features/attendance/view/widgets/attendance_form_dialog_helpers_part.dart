part of 'attendance_form_dialog.dart';

extension _AttendanceFormDialogHelpers on _AttendanceFormDialogState {
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateError = null;
      });
    }
  }

  Future<void> _pickTime(bool isCheckIn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
      } else {
        _checkOut = picked;
      }
    });
  }

  DateTime? _merge(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pick date';
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
