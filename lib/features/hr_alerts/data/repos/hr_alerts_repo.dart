import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/app_di.dart';
import '../../../employees/domain/models/expiry_alert.dart';
import '../../domain/models/government_alert_item.dart';
import '../../domain/models/hr_alert_state_info.dart';
import '../../domain/models/hr_alerts_data.dart';

class HrAlertsRepo {
  final SupabaseClient _client = Supabase.instance.client;

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<HrAlertsData> load({bool includeHidden = false}) async {
    final settings = await AppDI.employeesRepo.fetchExpiryAlertSettings();
    final items = await AppDI.employeesRepo.fetchExpiryAlerts();
    final governmentItems = await loadGovernmentAlerts();
    final states = await _loadAlertStates();
    final filteredEmployeeItems = includeHidden
        ? items
        : items
            .where(
              (item) => !_isAlertHidden(
                states,
                scope: 'employee_expiry',
                key: employeeAlertKey(item),
              ),
            )
            .toList();
    final filteredGovernmentItems = includeHidden
        ? governmentItems
        : governmentItems
            .where(
              (item) => !_isAlertHidden(
                states,
                scope: 'government',
                key: item.id,
              ),
            )
            .toList();
    final employeeStates = <String, HrAlertStateInfo>{};
    for (final item in items) {
      final key = employeeAlertKey(item);
      final row = states['employee_expiry::$key'];
      if (row != null) {
        employeeStates[key] = _stateInfoFromRow(row);
      }
    }
    final governmentStates = <String, HrAlertStateInfo>{};
    for (final item in governmentItems) {
      final row = states['government::${item.id}'];
      if (row != null) {
        governmentStates[item.id] = _stateInfoFromRow(row);
      }
    }

    return HrAlertsData(
      settings: settings,
      items: filteredEmployeeItems,
      governmentItems: filteredGovernmentItems,
      employeeStates: employeeStates,
      governmentStates: governmentStates,
    );
  }

  Future<void> saveSettings(ExpiryAlertSettings settings) {
    return AppDI.employeesRepo.upsertExpiryAlertSettings(settings);
  }

  Future<List<GovernmentAlertItem>> loadGovernmentAlerts() async {
    final tenantId = await _tenantId();
    final rows = await _client
        .from('government_alerts')
        .select(
          'id, title, alert_type, description, start_date, end_date, file_name, file_url',
        )
        .eq('tenant_id', tenantId)
        .order('end_date', ascending: true);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return (rows as List).cast<Map<String, dynamic>>().map((row) {
      final endDate = DateTime.tryParse(row['end_date']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final startDate = DateTime.tryParse(row['start_date']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
      return GovernmentAlertItem(
        id: row['id']?.toString() ?? '',
        title: row['title']?.toString() ?? '-',
        alertType: row['alert_type']?.toString() ?? 'other',
        description: row['description']?.toString(),
        startDate: startDate,
        endDate: endDate,
        daysLeft: endOnly.difference(todayOnly).inDays,
        fileName: row['file_name']?.toString(),
        fileUrl: row['file_url']?.toString(),
      );
    }).toList();
  }

  Future<void> createGovernmentAlert({
    required String title,
    required String alertType,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
    String? fileName,
    Uint8List? fileBytes,
    String? mimeType,
  }) async {
    final auth = await _currentAuth();
    final tenantId = auth['tenant_id']!;
    String? fileUrl;
    String? storedFileName;
    if (fileBytes != null && (fileName ?? '').trim().isNotEmpty) {
      final normalizedFileName = fileName!.trim();
      final safeFileName = _safeStorageFileName(normalizedFileName);
      final path = '$tenantId/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';
      await _client.storage.from('government_alerts').uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(contentType: mimeType),
          );
      fileUrl = _client.storage.from('government_alerts').getPublicUrl(path);
      storedFileName = normalizedFileName;
    }

    await _client.from('government_alerts').insert({
      'tenant_id': tenantId,
      'title': title.trim(),
      'alert_type': alertType,
      'description': _trimOrNull(description),
      'start_date': _dateOnly(startDate),
      'end_date': _dateOnly(endDate),
      'file_name': storedFileName,
      'file_url': fileUrl,
    });
  }

  Future<void> updateGovernmentAlert({
    required String alertId,
    required String title,
    required String alertType,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
    String? existingFileUrl,
    String? existingFileName,
    String? fileName,
    Uint8List? fileBytes,
    String? mimeType,
  }) async {
    final auth = await _currentAuth();
    final tenantId = auth['tenant_id']!;
    String? fileUrl = existingFileUrl;
    String? storedFileName = existingFileName;
    if (fileBytes != null && (fileName ?? '').trim().isNotEmpty) {
      final normalizedFileName = fileName!.trim();
      final safeFileName = _safeStorageFileName(normalizedFileName);
      final path = '$tenantId/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';
      await _client.storage.from('government_alerts').uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(contentType: mimeType),
          );
      fileUrl = _client.storage.from('government_alerts').getPublicUrl(path);
      storedFileName = normalizedFileName;
    }

    await _client
        .from('government_alerts')
        .update({
          'title': title.trim(),
          'alert_type': alertType,
          'description': _trimOrNull(description),
          'start_date': _dateOnly(startDate),
          'end_date': _dateOnly(endDate),
          'file_name': storedFileName,
          'file_url': fileUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', alertId)
        .eq('tenant_id', tenantId);
  }

  Future<void> deleteGovernmentAlert(String alertId) async {
    final tenantId = await _tenantId();
    await _client
        .from('government_alerts')
        .delete()
        .eq('id', alertId)
        .eq('tenant_id', tenantId);
  }

  Future<void> markGovernmentAlertHandled(String alertId) {
    return _upsertAlertState(
      scope: 'government',
      key: alertId,
      resolvedAt: DateTime.now(),
      snoozeUntil: null,
    );
  }

  Future<void> snoozeGovernmentAlert(String alertId, {int days = 7}) {
    return _upsertAlertState(
      scope: 'government',
      key: alertId,
      resolvedAt: null,
      snoozeUntil: DateTime.now().add(Duration(days: days)),
    );
  }

  Future<void> restoreGovernmentAlert(String alertId) {
    return _clearAlertState(scope: 'government', key: alertId);
  }

  Future<void> markEmployeeAlertHandled(ExpiryAlertItem item) {
    return _upsertAlertState(
      scope: 'employee_expiry',
      key: employeeAlertKey(item),
      resolvedAt: DateTime.now(),
      snoozeUntil: null,
    );
  }

  Future<void> snoozeEmployeeAlert(ExpiryAlertItem item, {int days = 7}) {
    return _upsertAlertState(
      scope: 'employee_expiry',
      key: employeeAlertKey(item),
      resolvedAt: null,
      snoozeUntil: DateTime.now().add(Duration(days: days)),
    );
  }

  Future<void> restoreEmployeeAlert(ExpiryAlertItem item) {
    return _clearAlertState(scope: 'employee_expiry', key: employeeAlertKey(item));
  }

  Future<void> _upsertAlertState({
    required String scope,
    required String key,
    required DateTime? resolvedAt,
    required DateTime? snoozeUntil,
  }) async {
    final tenantId = await _tenantId();
    await _client.from('hr_alert_states').upsert({
      'tenant_id': tenantId,
      'alert_scope': scope,
      'alert_key': key,
      'resolved_at': resolvedAt?.toIso8601String(),
      'snooze_until': snoozeUntil?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'tenant_id,alert_scope,alert_key');
  }

  Future<void> _clearAlertState({
    required String scope,
    required String key,
  }) async {
    final tenantId = await _tenantId();
    await _client
        .from('hr_alert_states')
        .delete()
        .eq('tenant_id', tenantId)
        .eq('alert_scope', scope)
        .eq('alert_key', key);
  }

  Future<Map<String, Map<String, dynamic>>> _loadAlertStates() async {
    final tenantId = await _tenantId();
    final rows = await _client
        .from('hr_alert_states')
        .select('alert_scope, alert_key, snooze_until, resolved_at')
        .eq('tenant_id', tenantId);
    final map = <String, Map<String, dynamic>>{};
    for (final row in (rows as List).cast<Map<String, dynamic>>()) {
      final scope = row['alert_scope']?.toString() ?? '';
      final key = row['alert_key']?.toString() ?? '';
      if (scope.isEmpty || key.isEmpty) continue;
      map['$scope::$key'] = row;
    }
    return map;
  }

  bool _isAlertHidden(
    Map<String, Map<String, dynamic>> states, {
    required String scope,
    required String key,
  }) {
    final row = states['$scope::$key'];
    if (row == null) return false;
    if (row['resolved_at'] != null) return true;
    final snoozeUntil = DateTime.tryParse(row['snooze_until']?.toString() ?? '');
    return snoozeUntil != null && snoozeUntil.isAfter(DateTime.now());
  }

  HrAlertStateInfo _stateInfoFromRow(Map<String, dynamic> row) {
    return HrAlertStateInfo(
      snoozeUntil: DateTime.tryParse(row['snooze_until']?.toString() ?? ''),
      resolvedAt: DateTime.tryParse(row['resolved_at']?.toString() ?? ''),
    );
  }

  Future<Map<String, String>> _currentAuth() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('Not authenticated');
    }
    final me = await _client.from('users').select('tenant_id').eq('id', uid).single();
    return {
      'user_id': uid,
      'tenant_id': me['tenant_id'].toString(),
    };
  }

  Future<String> _tenantId() async => (await _currentAuth())['tenant_id']!;

  String _safeStorageFileName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    final hasExtension = dotIndex > 0 && dotIndex < fileName.length - 1;
    final baseName = hasExtension ? fileName.substring(0, dotIndex) : fileName;
    final extension = hasExtension ? fileName.substring(dotIndex + 1).toLowerCase() : '';

    final sanitizedBase = baseName
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final fallbackBase = sanitizedBase.isEmpty ? 'file' : sanitizedBase;
    return extension.isEmpty ? fallbackBase : '$fallbackBase.$extension';
  }

  String _dateOnly(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}

String employeeAlertKey(ExpiryAlertItem item) {
  final date = DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day).toIso8601String().split('T').first;
  return '${item.employeeId}|${item.type}|$date';
}
