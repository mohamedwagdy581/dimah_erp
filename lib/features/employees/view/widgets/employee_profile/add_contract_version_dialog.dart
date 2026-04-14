import 'package:flutter/material.dart';

import '../../../../../core/di/app_di.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_profile_details.dart';
import 'edit_dialog/employee_profile_dialog_actions.dart';
import 'version_dialogs/add_contract_version_form.dart';

class AddContractVersionDialog extends StatefulWidget {
  const AddContractVersionDialog({
    super.key,
    required this.profile,
    this.initialStartDate,
    this.initialEndDate,
    this.initialOldEndDate,
  });

  final EmployeeProfileDetails profile;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final DateTime? initialOldEndDate;

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
    _startDate = widget.initialStartDate ?? DateTime.now();
    _endDate = widget.initialEndDate;
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
    final isRenewFlow =
        widget.initialOldEndDate != null &&
        widget.initialStartDate != null &&
        widget.initialEndDate != null;
    return AlertDialog(
      title: Text(t.addContractVersion),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRenewFlow) ...[
              _buildRenewHint(context),
              const SizedBox(height: 12),
            ],
            AddContractVersionForm(
              formKey: _formKey,
              contractType: _contractType,
              probationMonths: _probationMonths,
              fileUrl: _fileUrl,
              startDate: _startDate,
              endDate: _endDate,
              onPickStartDate: _pickStartDate,
              onPickEndDate: _pickEndDate,
            ),
          ],
        ),
      ),
      actions: [EmployeeProfileDialogActions(saving: _saving, onSave: _save)],
    );
  }

  Widget _buildRenewHint(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    String fmt(DateTime? value) {
      if (value == null) return '-';
      final m = value.month.toString().padLeft(2, '0');
      final d = value.day.toString().padLeft(2, '0');
      return '${value.year}-$m-$d';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'تجديد عقد من تنبيه' : 'Contract renewal from alert',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            isArabic
                ? 'تاريخ نهاية العقد السابق: ${fmt(widget.initialOldEndDate)}'
                : 'Previous contract end date: ${fmt(widget.initialOldEndDate)}',
          ),
          Text(
            isArabic
                ? 'تاريخ البداية الجديد المقترح: ${fmt(widget.initialStartDate)}'
                : 'Suggested new start date: ${fmt(widget.initialStartDate)}',
          ),
          Text(
            isArabic
                ? 'تاريخ النهاية الجديد المقترح: ${fmt(widget.initialEndDate)}'
                : 'Suggested new end date: ${fmt(widget.initialEndDate)}',
          ),
        ],
      ),
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
