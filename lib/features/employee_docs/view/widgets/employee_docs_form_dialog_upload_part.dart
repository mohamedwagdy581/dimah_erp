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
      _setUploading(true);

      final bytes = await file.readAsBytes();
      final client = Supabase.instance.client;
      final tenantId = await _fetchTenantId(client);
      final employeeId = _employeeId ?? 'unknown';

      // Sanitize filename to avoid "Invalid Key" error (spaces and Arabic chars can be problematic)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // We keep it simple: timestamp + extension, or a cleaned version of the name
      final safeName = file.name
          .replaceAll(RegExp(r'[^\x00-\x7F]+'), 'doc') // Replace non-ascii with 'doc'
          .replaceAll(' ', '_');
      
      final path = '$tenantId/$employeeId/${timestamp}_$safeName';

      await client.storage
          .from('employee_docs')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: _getContentType(file.name)),
          )
          .timeout(const Duration(minutes: 2));

      final url = client.storage.from('employee_docs').getPublicUrl(path);
      _setUploadedFileUrl(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.fileUploadedSuccessfully)),
      );
    } catch (e) {
      debugPrint('EMPLOYEE_DOC_UPLOAD_ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is StorageException && e.statusCode == '403'
                ? (t.employeeDocsStorageUnauthorized ?? 'Storage Unauthorized')
                : t.fileUploadFailed(e.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) _setUploading(false);
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
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    final me = await client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();
    return me['tenant_id'].toString();
  }
}
