import 'package:flutter/material.dart';

import '../../../../../core/di/app_di.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_profile_details.dart';
import 'edit_dialog/employee_profile_dialog_actions.dart';
import 'version_dialogs/add_compensation_version_form.dart';

class AddCompensationVersionDialog extends StatefulWidget {
  const AddCompensationVersionDialog({super.key, required this.profile});

  final EmployeeProfileDetails profile;

  @override
  State<AddCompensationVersionDialog> createState() =>
      _AddCompensationVersionDialogState();
}

class _AddCompensationVersionDialogState
    extends State<AddCompensationVersionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _basic;
  late final TextEditingController _housing;
  late final TextEditingController _transport;
  late final TextEditingController _other;
  late final TextEditingController _note;
  DateTime? _effectiveAt = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _basic = TextEditingController(
      text: (widget.profile.basicSalary ?? 0).toStringAsFixed(2),
    );
    _housing = TextEditingController(
      text: (widget.profile.housingAllowance ?? 0).toStringAsFixed(2),
    );
    _transport = TextEditingController(
      text: (widget.profile.transportAllowance ?? 0).toStringAsFixed(2),
    );
    _other = TextEditingController(
      text: (widget.profile.otherAllowance ?? 0).toStringAsFixed(2),
    );
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _basic.dispose();
    _housing.dispose();
    _transport.dispose();
    _other.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.addCompensationVersion),
      content: SizedBox(
        width: 520,
        child: AddCompensationVersionForm(
          formKey: _formKey,
          basic: _basic,
          housing: _housing,
          transport: _transport,
          other: _other,
          note: _note,
          effectiveAt: _effectiveAt,
          onPickEffectiveDate: _pickEffectiveDate,
        ),
      ),
      actions: [EmployeeProfileDialogActions(saving: _saving, onSave: _save)],
    );
  }

  Future<void> _pickEffectiveDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveAt ?? now,
      firstDate: DateTime(now.year - 20, 1, 1),
      lastDate: DateTime(now.year + 20, 12, 31),
    );
    if (picked != null) setState(() => _effectiveAt = picked);
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await AppDI.employeesRepo.addEmployeeCompensationVersion(
        employeeId: widget.profile.id,
        basicSalary: double.parse(_basic.text.trim()),
        housingAllowance: double.parse(_housing.text.trim()),
        transportAllowance: double.parse(_transport.text.trim()),
        otherAllowance: double.parse(_other.text.trim()),
        effectiveAt: _effectiveAt,
        note: _note.text.trim(),
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
