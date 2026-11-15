import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the created task when a later upload fails, so retry never reassigns it.
class ManagerTaskSubmission {
  String? taskId;
  Future<void> submit({
    required Future<String> Function() create,
    required Future<void> Function(String) attach,
  }) async {
    taskId ??= await create();
    await attach(taskId!);
  }

  void clear() => taskId = null;
}

class ManagerTaskAttachment {
  ManagerTaskAttachment({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });
  static const maxBytes = 10 * 1024 * 1024;
  static const extensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'doc',
    'docx',
    'xlsx',
    'xls',
    'zip',
    'txt',
  ];
  final String name, mimeType;
  final Uint8List bytes;
  String? _path;

  static bool accepts(String name, int size) =>
      size > 0 &&
      size <= maxBytes &&
      extensions.contains(name.split('.').last.toLowerCase());

  /// Stable storage path and metadata lookup also handle a lost server response.
  Future<bool> upload(
    SupabaseClient client, {
    required String tenantId,
    required String taskId,
    required String userId,
  }) async {
    _path ??=
        '$tenantId/$taskId/${DateTime.now().microsecondsSinceEpoch}_${name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
    final bucket = client.storage.from('task_attachments');
    final url = bucket.getPublicUrl(_path!);
    final existing = await client
        .from('employee_task_attachments')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('task_id', taskId)
        .eq('file_url', url)
        .limit(1);
    if (existing.isNotEmpty) return false;
    try {
      await bucket
          .uploadBinary(
            _path!,
            bytes,
            fileOptions: FileOptions(contentType: mimeType),
          )
          .timeout(const Duration(minutes: 2));
    } on StorageException catch (e) {
      final duplicate =
          e.statusCode == '409' ||
          (e.statusCode == '400' &&
              e.message.toLowerCase().contains('already exists'));
      if (!duplicate) {
        rethrow;
      }
    }
    await client.from('employee_task_attachments').insert({
      'tenant_id': tenantId,
      'task_id': taskId,
      'uploaded_by_user_id': userId,
      'file_name': name,
      'file_url': url,
      'mime_type': mimeType,
    });
    return true;
  }
}
