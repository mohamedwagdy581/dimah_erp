part of 'my_tasks_repo.dart';

mixin _MyTasksRepoAttachmentsMixin
    on _MyTasksRepoHelpersMixin, _MyTasksRepoEventsMixin {
  Future<void> addAttachment({
    required String taskId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final auth = await _currentUserTenant();
    if (auth == null) {
      return;
    }
    final uid = auth['user_id'].toString();
    final tenantId = auth['tenant_id'].toString();
    final path = '$tenantId/$taskId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage
        .from('task_attachments')
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mimeType))
        .timeout(const Duration(minutes: 2));
    final url = _client.storage.from('task_attachments').getPublicUrl(path);
    await _client.from('employee_task_attachments').insert({
      'tenant_id': tenantId,
      'task_id': taskId,
      'uploaded_by_user_id': uid,
      'file_name': fileName,
      'file_url': url,
      'mime_type': mimeType,
    });
    await appendTaskEvent(
      taskId: taskId,
      eventType: 'attachment_added',
      note: fileName,
    );
  }
}
