import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/utils/safe_file_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../employees/domain/models/employee_lookup.dart';
import '../../domain/models/employee_document.dart';
import '../cubit/employee_docs_cubit.dart';

part 'employee_docs_form_dialog_build_part.dart';
part 'employee_docs_form_dialog_fields_part.dart';
part 'employee_docs_form_dialog_doc_types_part.dart';
part 'employee_docs_form_dialog_upload_part.dart';

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

  void _filter(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filtered = _employees);
      return;
    }
    setState(() {
      _filtered = _employees
          .where((e) => e.fullName.toLowerCase().contains(query))
          .toList();
    });
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
      if (kDebugMode) {
        print('EMPLOYEE_DOC_SAVE_ERROR: $e');
        print('EMPLOYEE_DOC_SAVE_STACK: ${StackTrace.current}');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.saveFailed(e.toString()))),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => buildEmployeeDocsFormDialog(context);
}
