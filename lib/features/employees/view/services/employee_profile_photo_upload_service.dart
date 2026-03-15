import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/di/app_di.dart';

class EmployeeProfilePhotoUploadService {
  Future<String> uploadPhoto({
    required String fileName,
    required Uint8List bytes,
    required String displayName,
    required String employeeId,
  }) async {
    final path = await _buildUploadPath(
      fileName: fileName,
      displayName: displayName,
      employeeId: employeeId,
    );
    await AppDI.supabase.storage.from('employee_photos').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: _contentType(fileName), upsert: true),
    );
    return AppDI.supabase.storage.from('employee_photos').getPublicUrl(path);
  }

  Future<String> _buildUploadPath({
    required String fileName,
    required String displayName,
    required String employeeId,
  }) async {
    final uid = AppDI.supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    final me = await AppDI.supabase.from('users').select('tenant_id').eq('id', uid).single();
    final slug = _slugify(displayName);
    final ext = _extension(fileName);
    return '${me['tenant_id']}/${slug}_${employeeId.substring(0, 8)}/$slug.$ext';
  }

  String _extension(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index < 0 || index == fileName.length - 1) return 'jpg';
    return fileName.substring(index + 1).toLowerCase();
  }

  String _slugify(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'employee' : normalized;
  }

  String _contentType(String fileName) => switch (_extension(fileName)) {
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        'webp' => 'image/webp',
        _ => 'application/octet-stream',
      };
}
