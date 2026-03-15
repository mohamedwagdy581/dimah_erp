import 'package:flutter/material.dart';

import '../../../../../core/di/app_di.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_profile_details.dart';
import 'edit_dialog/employee_profile_dialog_actions.dart';
import 'version_dialogs/add_contract_version_form.dart';

class AddContractVersionDialog extends StatefulWidget {
  const AddContractVersionDialog({super.key, required this.profile});

  final EmployeeProfileDetails profile;

  @override
  State<AddContractVersionDialog> createState() =>
      _AddContractVersionDialogState();
}

class _AddContractVersionDialogState extends State<AddContractVersionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _contractType;
  late final TextEditingController _probationMonths;
  late final TextEditingController _fileUrl;
  DateTime? _startDate = DateTime.now();
  DateTime? _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _contractType = TextEditingController(text: 'full_time');
    _probationMonths = TextEditingController();
    _fileUrl = TextEditingController();
  }

  @override
  void dispose() {
    _contractType.dispose();
    _probationMonths.dispose();
    _fileUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.addContractVersion),
      content: SizedBox(
        width: 520,
        child: AddContractVersionForm(
          formKey: _formKey,
          contractType: _contractType,
          probationMonths: _probationMonths,
          fileUrl: _fileUrl,
          startDate: _startDate,
          endDate: _endDate,
          onPickStartDate: _pickStartDate,
          onPickEndDate: _pickEndDate,
        ),
      ),
      actions: [EmployeeProfileDialogActions(saving: _saving, onSave: _save)],
    );
  }

  Future<void> _pickStartDate() => _pickDate(
        initialDate: _startDate,
        onSelected: (value) => setState(() => _startDate = value),
      );

  Future<void> _pickEndDate() => _pickDate(
        initialDate: _endDate ?? _startDate,
        onSelected: (value) => setState(() => _endDate = value),
      );

  Future<void> _pickDate({
    required DateTime? initialDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 20, 1, 1),
      lastDate: DateTime(now.year + 20, 12, 31),
    );
    if (picked != null) onSelected(picked);
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.startDateRequired)));
      return;
    }
    setState(() => _saving = true);
    try {
      await AppDI.employeesRepo.addEmployeeContractVersion(
        employeeId: widget.profile.id,
        contractType: _contractType.text.trim(),
        startDate: _startDate!,
        endDate: _endDate,
        probationMonths: int.tryParse(_probationMonths.text.trim()),
        fileUrl: _fileUrl.text.trim(),
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
