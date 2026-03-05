import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/attendance_record.dart';
import '../cubit/attendance_cubit.dart';

class AttendanceCorrectionDialog extends StatefulWidget {
  const AttendanceCorrectionDialog({super.key, required this.record});

  final AttendanceRecord record;

  @override
  State<AttendanceCorrectionDialog> createState() =>
      _AttendanceCorrectionDialogState();
}

class _AttendanceCorrectionDialogState
    extends State<AttendanceCorrectionDialog> {
  final _reason = TextEditingController();
  TimeOfDay? _checkIn;
  TimeOfDay? _checkOut;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isCheckIn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  DateTime? _merge(TimeOfDay? t) {
    if (t == null) return null;
    final d = widget.record.date;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _submit() async {
    final ci = _merge(_checkIn);
    final co = _merge(_checkOut);
    if (ci != null && co != null && co.isBefore(ci)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-out must be after check-in')),
      );
      return;
    }

    await context.read<AttendanceCubit>().requestCorrection(
      recordId: widget.record.id,
      employeeId: widget.record.employeeId,
      date: widget.record.date,
      proposedCheckIn: ci,
      proposedCheckOut: co,
      reason: _reason.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Correction'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(true),
                    child: Text(
                      _checkIn == null
                          ? 'Check In'
                          : _checkIn!.format(context),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(false),
                    child: Text(
                      _checkOut == null
                          ? 'Check Out'
                          : _checkOut!.format(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Submit')),
      ],
    );
  }
}
