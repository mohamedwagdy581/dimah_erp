part of 'leaves_form_dialog.dart';

extension _LeavesFormDialogUpload on _LeavesFormDialogState {
  Future<void> _pickFile() async {
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

      final length = await file.length();
      if (length > _LeavesFormDialogState._maxFileBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File is too large. Max size is 10 MB.')),
        );
        return;
      }

      final client = Supabase.instance.client;
      final tenantId = await _fetchTenantId(client);
      final employeeId = _employeeId ?? 'unknown';
      final path = '$tenantId/$employeeId/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      await client.storage
          .from('leave_docs')
          .uploadBinary(
            path,
            await file.readAsBytes(),
            fileOptions: const FileOptions(contentType: 'application/pdf'),
          )
          .timeout(const Duration(minutes: 2));

      _fileUrl = client.storage.from('leave_docs').getPublicUrl(path);
      _fileName.value = file.name;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
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
