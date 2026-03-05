import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/utils/safe_file_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../employees/domain/models/employee_lookup.dart';
import '../cubit/employee_docs_cubit.dart';

class EmployeeDocsFormDialog extends StatefulWidget {
  const EmployeeDocsFormDialog({super.key});

  @override
  State<EmployeeDocsFormDialog> createState() => _EmployeeDocsFormDialogState();
}

class _EmployeeDocsFormDialogState extends State<EmployeeDocsFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fileUrl = TextEditingController();
  final _search = TextEditingController();
  final _docType = TextEditingController(text: 'contract');

  List<EmployeeLookup> _employees = const [];
  List<EmployeeLookup> _filtered = const [];
  String? _employeeId;
  DateTime? _issuedAt;
  DateTime? _expiresAt;
  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _fileUrl.dispose();
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
      await context.read<EmployeeDocsCubit>().create(
        employeeId: _employeeId!,
        docType: _docType.text.trim(),
        fileUrl: _fileUrl.text.trim(),
        issuedAt: _issuedAt,
        expiresAt: _expiresAt,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
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
    return AlertDialog(
      title: Text(t.addDocument),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _docType,
                decoration: InputDecoration(
                  labelText: t.documentType,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) {
                    return t.documentTypeRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fileUrl,
                decoration: InputDecoration(
                  labelText: t.fileUrl,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) {
                    return t.fileUrlRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: (_uploading || _saving) ? null : _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(_uploading ? t.uploading : t.uploadPdf),
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
                            : '${_issuedAt!.year.toString().padLeft(4, '0')}-'
                                  '${_issuedAt!.month.toString().padLeft(2, '0')}-'
                                  '${_issuedAt!.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_uploading || _saving) ? null : _pickExpires,
                      icon: const Icon(Icons.event_available),
                      label: Text(
                        _expiresAt == null
                            ? t.expiresDate
                            : '${_expiresAt!.year.toString().padLeft(4, '0')}-'
                                  '${_expiresAt!.month.toString().padLeft(2, '0')}-'
                                  '${_expiresAt!.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
          XTypeGroup(label: 'PDF', extensions: ['pdf']),
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
            fileOptions: const FileOptions(contentType: 'application/pdf'),
          )
          .timeout(const Duration(minutes: 2));

      final url = client.storage.from('employee_docs').getPublicUrl(path);
      _fileUrl.text = url;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.fileUploadedSuccessfully)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.fileUploadFailed(e.toString()))));
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<String> _fetchTenantId(SupabaseClient client) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw Exception(AppLocalizations.of(context)!.notAuthenticated);
    final me = await client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();
    return me['tenant_id'].toString();
  }
}
