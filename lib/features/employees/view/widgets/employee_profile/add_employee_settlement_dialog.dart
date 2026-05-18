import 'package:flutter/material.dart';

import '../../../../../core/di/app_di.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_profile_details.dart';
import 'edit_dialog/employee_profile_dialog_actions.dart';

class AddEmployeeSettlementDialog extends StatefulWidget {
  const AddEmployeeSettlementDialog({
    super.key,
    required this.profile,
  });

  final EmployeeProfileDetails profile;

  @override
  State<AddEmployeeSettlementDialog> createState() =>
      _AddEmployeeSettlementDialogState();
}

class _AddEmployeeSettlementDialogState
    extends State<AddEmployeeSettlementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _grossAmount = TextEditingController();
  final _deductionsAmount = TextEditingController(text: '0');
  final _notes = TextEditingController();
  late DateTime? _finalWorkingDate;
  DateTime? _settlementDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _finalWorkingDate = widget.profile.contractEnd ?? DateTime.now();
    _settlementDate = DateTime.now();
  }

  @override
  void dispose() {
    _grossAmount.dispose();
    _deductionsAmount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.addSettlement),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DateField(
                  label: t.finalWorkingDate,
                  value: _finalWorkingDate,
                  onTap: () => _pickDate(
                    initial: _finalWorkingDate,
                    onSelected: (value) =>
                        setState(() => _finalWorkingDate = value),
                  ),
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: t.settlementDate,
                  value: _settlementDate,
                  onTap: () => _pickDate(
                    initial: _settlementDate,
                    onSelected: (value) =>
                        setState(() => _settlementDate = value),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _grossAmount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: t.grossAmount,
                    border: const OutlineInputBorder(),
                  ),
                  validator: _requiredAmount,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deductionsAmount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: t.deductionsAmount,
                    border: const OutlineInputBorder(),
                  ),
                  validator: _requiredAmount,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: t.notes,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [EmployeeProfileDialogActions(saving: _saving, onSave: _save)],
    );
  }

  String? _requiredAmount(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null) {
      return AppLocalizations.of(context)!.requiredField;
    }
    return null;
  }

  Future<void> _pickDate({
    required DateTime? initial,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 20, 1, 1),
      lastDate: DateTime(now.year + 20, 12, 31),
    );
    if (picked != null) onSelected(picked);
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_finalWorkingDate == null || _settlementDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.dateRequired)));
      return;
    }

    setState(() => _saving = true);
    try {
      await AppDI.employeesRepo.addEmployeeSettlement(
        employeeId: widget.profile.id,
        finalWorkingDate: _finalWorkingDate!,
        settlementDate: _settlementDate!,
        grossAmount: double.parse(_grossAmount.text.trim()),
        deductionsAmount: double.parse(_deductionsAmount.text.trim()),
        notes: _notes.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.saveFailed(error.toString()))),
      );
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final text = value == null
        ? t.selectDate
        : '${value!.year.toString().padLeft(4, '0')}-'
            '${value!.month.toString().padLeft(2, '0')}-'
            '${value!.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(text),
      ),
    );
  }
}
