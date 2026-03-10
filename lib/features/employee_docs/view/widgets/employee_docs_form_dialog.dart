import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/utils/safe_file_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../employees/domain/models/employee_lookup.dart';
import '../../domain/models/employee_document.dart';
import '../cubit/employee_docs_cubit.dart';

class EmployeeDocsFormDialog extends StatefulWidget {
  const EmployeeDocsFormDialog({
    super.key,
    this.initialEmployeeId,
    this.initialDocument,
  });

  final String? initialEmployeeId;
  final EmployeeDocument? initialDocument;

  @override
  State<EmployeeDocsFormDialog> createState() => _EmployeeDocsFormDialogState();
}

class _EmployeeDocsFormDialogState extends State<EmployeeDocsFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _search = TextEditingController();
  final _docType = TextEditingController(text: 'id_card');

  List<EmployeeLookup> _employees = const [];
  List<EmployeeLookup> _filtered = const [];
  String? _employeeId;
  DateTime? _issuedAt;
  DateTime? _expiresAt;
  bool _uploading = false;
  bool _saving = false;
  String _uploadedFileUrl = '';

  String get _selectedFileName {
    final raw = _uploadedFileUrl.trim();
    if (raw.isEmpty) return '';
    final uri = Uri.tryParse(raw);
    if (uri == null) return raw;
    final segment = uri.pathSegments.isEmpty ? raw : uri.pathSegments.last;
    return segment.isEmpty ? raw : segment;
  }

  @override
  void initState() {
    super.initState();
    _employeeId = widget.initialEmployeeId ?? widget.initialDocument?.employeeId;
    _docType.text = widget.initialDocument?.docType ?? 'id_card';
    _issuedAt = widget.initialDocument?.issuedAt;
    _expiresAt = widget.initialDocument?.expiresAt;
    _uploadedFileUrl = widget.initialDocument?.fileUrl ?? '';
    _loadEmployees();
  }

  @override
  void dispose() {
    _search.dispose();
    _docType.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees({String? search}) async {
    final items = await AppDI.employeesRepo.fetchEmployeeLookup(
      search: search,
      limit: 200,
    );
    if (!mounted) return;
    setState(() {
      _employees = items;
      _filtered = items;
    });
  }

  void _filter(String v) {
    final q = v.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _employees);
      return;
    }
    setState(() {
      _filtered = _employees
          .where((e) => e.fullName.toLowerCase().contains(q))
          .toList();
    });
  }

  Future<void> _pickIssued() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _issuedAt ?? now,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked != null) setState(() => _issuedAt = picked);
  }

  Future<void> _pickExpires() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? _issuedAt ?? now,
      firstDate: _issuedAt ?? DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 10, 12, 31),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_uploading || _saving) return;
    setState(() => _saving = true);
    try {
      if (widget.initialDocument == null) {
        await context.read<EmployeeDocsCubit>().create(
          employeeId: _employeeId!,
          docType: _docType.text.trim(),
          fileUrl: _uploadedFileUrl.trim(),
          issuedAt: _issuedAt,
          expiresAt: _expiresAt,
        );
      } else {
        await context.read<EmployeeDocsCubit>().update(
          id: widget.initialDocument!.id,
          employeeId: _employeeId!,
          docType: _docType.text.trim(),
          fileUrl: _uploadedFileUrl.trim(),
          issuedAt: _issuedAt,
          expiresAt: _expiresAt,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      print('EMPLOYEE_DOC_SAVE_ERROR: $e');
      print('EMPLOYEE_DOC_SAVE_STACK: ${StackTrace.current}');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.saveFailed(e.toString()))));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isEdit = widget.initialDocument != null;

    final docTypeGroups = [
      (
        title: t.identityDocuments,
        items: [
          (value: 'id_card', label: t.idCard),
          (value: 'passport', label: t.passport),
          (value: 'national_address', label: t.nationalAddress),
          (value: 'residency', label: t.residencyDocument),
          (value: 'driving_license', label: t.drivingLicense),
        ],
      ),
      (
        title: t.educationAndCareerDocuments,
        items: [
          (value: 'cv', label: 'CV'),
          (value: 'graduation_cert', label: t.graduationCert),
          (value: 'offer_letter', label: t.offerLetter),
          (value: 'contract', label: t.contract),
        ],
      ),
      (
        title: t.financialDocuments,
        items: [
          (value: 'bank_iban_certificate', label: t.bankIbanCertificate),
          (value: 'salary_certificate', label: t.salaryCertificate),
          (value: 'salary_definition', label: t.salaryDefinition),
        ],
      ),
      (
        title: t.medicalAndInsuranceDocuments,
        items: [
          (value: 'medical_insurance', label: t.medicalInsurance),
          (value: 'medical_report', label: t.medicalReport),
        ],
      ),
      (
        title: t.otherDocuments,
        items: [
          (value: 'other', label: t.other),
        ],
      ),
    ];

    final docTypeItems = <DropdownMenuItem<String>>[
      for (final group in docTypeGroups) ...[
        DropdownMenuItem<String>(
          enabled: false,
          child: Text(
            group.title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...group.items.map(
          (item) => DropdownMenuItem<String>(
            value: item.value,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 12),
              child: Text(item.label),
            ),
          ),
        ),
      ],
    ];

    return AlertDialog(
      title: Text(isEdit ? t.editDocument : t.addDocument),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.initialEmployeeId == null &&
                    widget.initialDocument == null) ...[
                  TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      labelText: t.searchEmployeeHint,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: _filter,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _employeeId,
                    items: _filtered
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _employeeId = v),
                    decoration: InputDecoration(
                      labelText: t.employee,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return t.employeeRequired;
                      }
                      return null;
                    },
                  ),
                ] else
                  ListTile(
                    title: Text(t.employee),
                    subtitle: Text(
                      _employees
                          .firstWhere(
                            (e) => e.id == _employeeId,
                            orElse: () => EmployeeLookup(id: '', fullName: ''),
                          )
                          .fullName,
                    ),
                    tileColor: Colors.grey[100],
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _docType.text,
                  items: docTypeItems,
                  onChanged: (v) {
                    if (v != null) _docType.text = v;
                  },
                  decoration: InputDecoration(
                    labelText: t.documentType,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FormField<String>(
                  initialValue: _uploadedFileUrl,
                  validator: (_) {
                    if (_uploadedFileUrl.trim().isEmpty) {
                      return t.fileRequired;
                    }
                    return null;
                  },
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: field.hasError
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedFileName.isEmpty
                                      ? t.noFileSelected
                                      : _selectedFileName,
                                  style: TextStyle(
                                    color: _selectedFileName.isEmpty
                                        ? Theme.of(context).hintColor
                                        : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (field.errorText != null) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              field.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_uploading || _saving) ? null : _pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: Text(_uploading ? t.uploading : t.uploadFile),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_uploading || _saving) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _uploading ? t.uploadingDocument : t.savingDocument,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_uploading || _saving) ? null : _pickIssued,
                        icon: const Icon(Icons.event),
                        label: Text(
                          _issuedAt == null
                              ? t.issuedDate
                              : '${_issuedAt!.year}-${_issuedAt!.month.toString().padLeft(2, '0')}-${_issuedAt!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_uploading || _saving)
                            ? null
                            : _pickExpires,
                        icon: const Icon(Icons.event_available),
                        label: Text(
                          _expiresAt == null
                              ? t.expiresDate
                              : '${_expiresAt!.year}-${_expiresAt!.month.toString().padLeft(2, '0')}-${_expiresAt!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: (_uploading || _saving)
              ? null
              : () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          onPressed: (_uploading || _saving) ? null : _submit,
          child: Text(_saving ? t.saving : t.save),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final t = AppLocalizations.of(context)!;
    if (_uploading || _saving) return;
    try {
      final file = await SafeFilePicker.openSingle(
        context: context,
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Documents',
            extensions: ['pdf', 'jpg', 'png', 'jpeg', 'doc', 'docx'],
          ),
        ],
      );
      if (file == null) return;
      setState(() => _uploading = true);

      final bytes = await file.readAsBytes();
      final client = Supabase.instance.client;
      final tenantId = await _fetchTenantId(client);
      final employeeId = _employeeId ?? 'unknown';
      final path =
          '$tenantId/$employeeId/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      await client.storage
          .from('employee_docs')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: _getContentType(file.name)),
          )
          .timeout(const Duration(minutes: 2));

      final url = client.storage.from('employee_docs').getPublicUrl(path);
      setState(() {
        _uploadedFileUrl = url;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.fileUploadedSuccessfully)));
    } catch (e) {
      // Temporary debug logging to inspect storage/upload failures in Windows.
      print('EMPLOYEE_DOC_UPLOAD_ERROR: $e');
      print('EMPLOYEE_DOC_UPLOAD_STACK: ${StackTrace.current}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is StorageException && e.statusCode == '403'
                ? t.employeeDocsStorageUnauthorized
                : t.fileUploadFailed(e.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Future<String> _fetchTenantId(SupabaseClient client) async {
    final t = AppLocalizations.of(context)!;
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw Exception(t.notAuthenticated);
    final me = await client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();
    return me['tenant_id'].toString();
  }
}
