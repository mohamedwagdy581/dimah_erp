import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';

import '../cubit/payroll_cubit.dart';

class PayrollRunDialog extends StatefulWidget {
  const PayrollRunDialog({super.key});

  @override
  State<PayrollRunDialog> createState() => _PayrollRunDialogState();
}

class _PayrollRunDialogState extends State<PayrollRunDialog> {
  DateTime? _start;
  DateTime? _end;
  String? _error;

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _start ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _end ?? _start ?? now,
      firstDate: _start ?? DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null) setState(() => _end = picked);
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    if (_start == null || _end == null) {
      setState(() => _error = t.startEndDatesRequired);
      return;
    }
    if (_end!.isBefore(_start!)) {
      setState(() => _error = t.endDateAfterStart);
      return;
    }

    await context.read<PayrollCubit>().createRun(
      startDate: _start!,
      endDate: _end!,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.newPayrollRun),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _pickStart,
              icon: const Icon(Icons.event),
              label: Text(
                _start == null
                    ? t.pickStartDate
                    : '${_start!.year.toString().padLeft(4, '0')}-'
                          '${_start!.month.toString().padLeft(2, '0')}-'
                          '${_start!.day.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickEnd,
              icon: const Icon(Icons.event_available),
              label: Text(
                _end == null
                    ? t.pickEndDate
                    : '${_end!.year.toString().padLeft(4, '0')}-'
                          '${_end!.month.toString().padLeft(2, '0')}-'
                          '${_end!.day.toString().padLeft(2, '0')}',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        ElevatedButton(onPressed: _submit, child: Text(t.create)),
      ],
    );
  }
}
