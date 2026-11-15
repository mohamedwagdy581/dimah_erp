import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

String hrDraftFingerprint(Map<String, dynamic> data) {
  Object? canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: canonical(value[key])};
    }
    if (value is List) return value.map(canonical).toList();
    return value;
  }

  return jsonEncode(canonical(data));
}

class HrSavedDraft {
  const HrSavedDraft({
    required this.id,
    required this.templateId,
    required this.data,
    required this.version,
    required this.updatedAt,
    this.employeeId,
    this.employeeName,
    this.status = 'draft',
    this.approvalId,
    this.approverRole,
    this.reference,
    this.rejectReason,
  });
  final String id, templateId;
  final String? employeeId, employeeName;
  final String status;
  final String? approvalId, approverRole, reference, rejectReason;
  final Map<String, dynamic> data;
  final int version;
  final DateTime updatedAt;
  factory HrSavedDraft.fromJson(Map<String, dynamic> row) => HrSavedDraft(
    id: row['id'] as String,
    templateId: row['template_id'] as String,
    employeeId: row['employee_id'] as String?,
    employeeName: row['employee_name'] as String?,
    data: Map<String, dynamic>.from(row['data'] as Map),
    version: row['version'] as int,
    updatedAt: DateTime.parse(row['updated_at'] as String),
    status: row['status'] as String? ?? 'draft',
    approvalId: row['approval_id'] as String?,
    approverRole: row['current_approver_role'] as String?,
    reference: row['reference'] as String?,
    rejectReason: row['reject_reason'] as String?,
  );
}

abstract class HrFormDraftsRepo {
  Future<HrSavedDraft> submit(HrSavedDraft draft);
  Future<HrSavedDraft> save({
    required String templateId,
    required Map<String, dynamic> data,
    String? employeeId,
    HrSavedDraft? previous,
  });
  Future<List<HrSavedDraft>> list();
  Future<List<Map<String, dynamic>>> events(String id);
}

class SupabaseHrFormDraftsRepo implements HrFormDraftsRepo {
  SupabaseHrFormDraftsRepo(this.client);
  final SupabaseClient client;
  @override
  Future<HrSavedDraft> submit(HrSavedDraft draft) async {
    final result = await client.rpc(
      'hr_submit_form_draft',
      params: {'p_id': draft.id, 'p_expected_version': draft.version},
    );
    return HrSavedDraft.fromJson(
      Map<String, dynamic>.from(
        (result is List ? result.single : result) as Map,
      ),
    );
  }

  @override
  Future<HrSavedDraft> save({
    required String templateId,
    required Map<String, dynamic> data,
    String? employeeId,
    HrSavedDraft? previous,
  }) async {
    final result = await client.rpc(
      'hr_save_form_draft',
      params: {
        'p_template_id': templateId,
        'p_employee_id': employeeId,
        'p_data': data,
        'p_id': previous?.id,
        'p_expected_version': previous?.version,
      },
    );
    final row = result is List ? result.single : result;
    return HrSavedDraft.fromJson(Map<String, dynamic>.from(row as Map));
  }

  @override
  Future<List<HrSavedDraft>> list() async {
    final rows = <HrSavedDraft>[];
    for (var offset = 0; ; offset += 200) {
      final batch = await client
          .from('hr_form_drafts')
          .select()
          .order('updated_at', ascending: false)
          .order('id')
          .range(offset, offset + 199);
      rows.addAll(batch.map(HrSavedDraft.fromJson));
      if (batch.length < 200) return rows;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> events(String id) async => await client
      .from('hr_form_draft_events')
      .select()
      .eq('draft_id', id)
      .order('version', ascending: false)
      .limit(100);
}
