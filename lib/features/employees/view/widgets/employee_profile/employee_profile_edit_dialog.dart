// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_profile_details.dart';
import '../../services/employee_profile_photo_upload_service.dart';
import '../../utils/employee_profile_date_picker.dart';
import 'edit_dialog/employee_profile_dialog_actions.dart';
import 'edit_dialog/employee_profile_edit_controllers.dart';
import 'edit_dialog/employee_profile_edit_dialog_content.dart';
import 'edit_dialog/employee_profile_edit_submit.dart';
import 'edit_dialog/pick_employee_profile_photo.dart';

class EmployeeProfileEditDialog extends StatefulWidget {
  const EmployeeProfileEditDialog({super.key, required this.profile});

  final EmployeeProfileDetails profile;

  @override
  State<EmployeeProfileEditDialog> createState() => _EmployeeProfileEditDialogState();
}

class _EmployeeProfileEditDialogState extends State<EmployeeProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _photoUploadService = EmployeeProfilePhotoUploadService();
  late final Map<String, TextEditingController> _c;
  late String _status;
  late String _paymentMethod;
  DateTime? _passportExpiry;
  DateTime? _residencyIssueDate;
  DateTime? _residencyExpiryDate;
  DateTime? _insuranceStartDate;
  DateTime? _insuranceExpiryDate;
  DateTime? _contractStart;
  DateTime? _contractEnd;
  bool _pickingPhoto = false;
  bool _saving = false;

  TextEditingController get _photoUrl => _c['photoUrl']!;
  String get _displayName =>
      _c['fullName']!.text.trim().isEmpty
          ? widget.profile.fullName
          : _c['fullName']!.text.trim();

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _c = buildEmployeeProfileEditControllers(p);
    _status = p.status.isEmpty ? 'active' : p.status;
    _paymentMethod = (p.paymentMethod ?? 'bank').isEmpty ? 'bank' : p.paymentMethod!;
    _passportExpiry = p.passportExpiry; _residencyIssueDate = p.residencyIssueDate; _residencyExpiryDate = p.residencyExpiryDate;
    _insuranceStartDate = p.insuranceStartDate; _insuranceExpiryDate = p.insuranceExpiryDate; _contractStart = p.contractStart; _contractEnd = p.contractEnd;
  }

  @override
  void dispose() {
    disposeEmployeeProfileEditControllers(_c);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.editEmployeeProfile),
      content: EmployeeProfileEditDialogContent(
        formKey: _formKey,
        controllers: _c,
        status: _status,
        paymentMethod: _paymentMethod,
        passportExpiry: _passportExpiry,
        residencyIssueDate: _residencyIssueDate,
        residencyExpiryDate: _residencyExpiryDate,
        insuranceStartDate: _insuranceStartDate,
        insuranceExpiryDate: _insuranceExpiryDate,
        contractStart: _contractStart,
        contractEnd: _contractEnd,
        saving: _saving,
        pickingPhoto: _pickingPhoto,
        onPickPhoto: _pickPhotoOnly,
        onStatusChanged: (value) => setState(() => _status = value ?? 'active'),
        onPaymentMethodChanged: (value) =>
            setState(() => _paymentMethod = value ?? 'bank'),
        onPickPassportExpiry: () =>
            _pickDate(_passportExpiry, (v) => _passportExpiry = v),
        onPickResidencyIssueDate: () =>
            _pickDate(_residencyIssueDate, (v) => _residencyIssueDate = v),
        onPickResidencyExpiryDate: () => _pickDate(
          _residencyExpiryDate ?? _residencyIssueDate,
          (v) => _residencyExpiryDate = v,
        ),
        onPickInsuranceStartDate: () =>
            _pickDate(_insuranceStartDate, (v) => _insuranceStartDate = v),
        onPickInsuranceExpiryDate: () => _pickDate(
          _insuranceExpiryDate ?? _insuranceStartDate,
          (v) => _insuranceExpiryDate = v,
        ),
        onPickContractStart: () =>
            _pickDate(_contractStart, (v) => _contractStart = v),
        onPickContractEnd: () =>
            _pickDate(_contractEnd ?? _contractStart, (v) => _contractEnd = v),
      ),
      actions: [EmployeeProfileDialogActions(saving: _saving || _pickingPhoto, onSave: _save)],
    );
  }

  Future<void> _pickDate(DateTime? initialDate, ValueChanged<DateTime> onSelected) async {
    final picked = await pickEmployeeProfileDate(context, initialDate: initialDate);
    if (picked != null) setState(() => onSelected(picked));
  }

  Future<void> _pickPhotoOnly() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _pickingPhoto = true);
    try {
      final url = await pickEmployeeProfilePhoto(context: context, uploadService: _photoUploadService, displayName: _displayName, employeeId: widget.profile.id);
      if (url == null) return;
      _photoUrl.text = url;
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.photoUploadedSuccessfully)));
    } catch (error, stackTrace) {
      debugPrint('PHOTO_UPLOAD_ERROR: $error');
      debugPrint('PHOTO_UPLOAD_STACK: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.photoUploadFailed(error.toString()))));
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await submitEmployeeProfileEdits(employeeId: widget.profile.id, controllers: _c, status: _status, paymentMethod: _paymentMethod, passportExpiry: _passportExpiry, residencyIssueDate: _residencyIssueDate, residencyExpiryDate: _residencyExpiryDate, insuranceStartDate: _insuranceStartDate, insuranceExpiryDate: _insuranceExpiryDate, contractStart: _contractStart, contractEnd: _contractEnd);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.saveFailed(error.toString()))));
    }
  }
}
