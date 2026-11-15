import 'package:file_selector/file_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Same bucket, PDF restriction and size limit as the existing leave form.
Future<String> uploadEmployeeLeaveAttachment(
  XFile file,
  String employeeId,
) async {
  if (!file.name.toLowerCase().endsWith('.pdf')) {
    throw ArgumentError('PDF only');
  }
  if (await file.length() > 10 * 1024 * 1024) {
    throw ArgumentError('Maximum file size is 10 MB');
  }
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) throw StateError('Not authenticated');
  final user = await client
      .from('users')
      .select('tenant_id, employee_id')
      .eq('id', uid)
      .single();
  if (user['employee_id'] != employeeId) {
    throw StateError('Employee account mismatch');
  }
  final path =
      '${user['tenant_id']}/$employeeId/${DateTime.now().microsecondsSinceEpoch}_${file.name}';
  await client.storage
      .from('leave_docs')
      .uploadBinary(
        path,
        await file.readAsBytes(),
        fileOptions: const FileOptions(contentType: 'application/pdf'),
      )
      .timeout(const Duration(minutes: 2));
  return client.storage.from('leave_docs').getPublicUrl(path);
}
