part of 'employee_docs_form_dialog.dart';

extension _EmployeeDocsFormDialogUpload on _EmployeeDocsFormDialogState {
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
      final path = '$tenantId/$employeeId/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      await client.storage
          .from('employee_docs')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: _getContentType(file.name)),
          )
          .timeout(const Duration(minutes: 2));

      final url = client.storage.from('employee_docs').getPublicUrl(path);
      setState(() => _uploadedFileUrl = url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.fileUploadedSuccessfully)),
      );
    } catch (e) {
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
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _getContentType(String fileName) {
    switch (fileName.split('.').last.toLowerCase()) {
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
