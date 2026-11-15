import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/employee.dart';
import '../../domain/models/hr_settlement.dart';

abstract class HrSettlementsRepo {
  Future<HrSettlementsData> load();
  Future<void> save(HrSettlementDraft draft);
  Future<String> attachmentUrl(String path);
}

class SupabaseHrSettlementsRepo implements HrSettlementsRepo {
  SupabaseHrSettlementsRepo(this.client);
  final SupabaseClient client;
  Future<String> _tenant() async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Missing session');
    final actor = await client
        .from('users')
        .select('tenant_id, role, is_active')
        .eq('id', uid)
        .single();
    if (actor['is_active'] != true ||
        !['hr', 'admin'].contains(actor['role']) ||
        actor['tenant_id'] == null) {
      throw StateError('Active HR/admin required');
    }
    return actor['tenant_id'].toString();
  }

  Future<List<Map<String, dynamic>>> _all(dynamic query) async {
    final rows = <Map<String, dynamic>>[];
    for (var page = 0; ; page++) {
      final batch = await query.range(page * 500, page * 500 + 499) as List;
      rows.addAll(batch.map((e) => Map<String, dynamic>.from(e as Map)));
      if (batch.length < 500) return rows;
    }
  }

  @override
  Future<HrSettlementsData> load() async {
    final tenant = await _tenant();
    final results = await Future.wait([
      _all(
        client
            .from('employees')
            .select(
              '*, department:departments!employees_department_id_fkey(name), job_title:job_titles(name)',
            )
            .eq('tenant_id', tenant)
            .order('id'),
      ),
      _all(
        client
            .from('employee_settlements')
            .select(
              '*, employee:employees!employee_settlements_employee_id_fkey(full_name, employee_number)',
            )
            .eq('tenant_id', tenant)
            .order('settlement_date', ascending: false)
            .order('id'),
      ),
    ]);
    return HrSettlementsData(
      employees: results[0].map(Employee.fromMap).toList(),
      settlements: results[1].map(HrSettlement.fromMap).toList(),
    );
  }

  @override
  Future<void> save(HrSettlementDraft draft) async {
    if (!['final', 'partial', 'other'].contains(draft.type) ||
        !draft.gross.isFinite ||
        !draft.deductions.isFinite ||
        draft.gross <= 0 ||
        draft.deductions < 0 ||
        draft.deductions > draft.gross) {
      throw ArgumentError('Invalid settlement amounts/type');
    }
    final tenant = await _tenant();
    final attachment = draft.attachment;
    String? path;
    if (attachment != null) {
      if (!attachment.isValid) {
        throw ArgumentError('PDF/JPG/PNG up to 5 MB required');
      }
      path = '$tenant/${draft.employeeId}/${draft.id}.${attachment.extension}';
      await client.storage
          .from('employee_settlement_files')
          .uploadBinary(
            path,
            attachment.bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: switch (attachment.extension) {
                'pdf' => 'application/pdf',
                'png' => 'image/png',
                _ => 'image/jpeg',
              },
            ),
          );
    }
    String date(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await client.rpc(
      'hr_save_employee_settlement',
      params: {
        'p_id': draft.id,
        'p_employee_id': draft.employeeId,
        'p_settlement_date': date(draft.date),
        'p_final_working_date': date(draft.finalWorkingDate),
        'p_settlement_type': draft.type,
        'p_gross_amount': draft.gross,
        'p_deductions_amount': draft.deductions,
        'p_notes': draft.notes.trim(),
        'p_attachment_path': path,
        'p_attachment_name': attachment?.name,
      },
    );
  }

  @override
  Future<String> attachmentUrl(String path) async {
    final tenant = await _tenant();
    if (!path.startsWith('$tenant/')) {
      throw StateError('Attachment outside tenant');
    }
    return client.storage
        .from('employee_settlement_files')
        .createSignedUrl(path, 300);
  }
}
