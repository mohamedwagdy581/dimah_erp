import 'package:supabase_flutter/supabase_flutter.dart';
import '../../approvals/domain/repos/approvals_repo.dart';
import '../../manager_team/data/manager_team_repo.dart';

class ManagerRequestsData {
  const ManagerRequestsData({this.rows = const [], this.role = 'manager'});
  final List<Map<String, dynamic>> rows;
  final String role;
}

abstract class ManagerRequestsRepo {
  Future<ManagerRequestsData> load();
  Future<void> decide(String id, bool approve, String reason);
}

List<Map<String, dynamic>> mergeManagerLeaveAttachments(
  List<Map<String, dynamic>> rows,
  List<Map<String, dynamic>> leaves,
) => [
  for (final row in rows)
    (() {
      final payload = Map<String, dynamic>.from(row['payload'] as Map? ?? {});
      if (row['request_type'] != 'leave' ||
          (payload['file_url']?.toString().trim() ?? '').isNotEmpty ||
          payload['leave_id'] == null) {
        return row;
      }
      final matches = leaves.where(
        (l) =>
            l['id'] == payload['leave_id'] &&
            l['employee_id'] == row['employee_id'] &&
            l['tenant_id'] == row['tenant_id'],
      );
      if (matches.isEmpty) return {...row, 'attachment_unavailable': true};
      final url = matches.first['file_url']?.toString().trim() ?? '';
      return {
        ...row,
        'payload': {...payload, 'file_url': url},
      };
    })(),
];

bool managerCanDecideRequest(Map<String, dynamic> row, String role) =>
    ['manager', 'direct_manager'].contains(role) &&
    row['status'] == 'pending' &&
    ['manager', 'direct_manager'].contains(row['current_approver_role']) &&
    ['leave', 'attendance_correction'].contains(row['request_type']);

class SupabaseManagerRequestsRepo implements ManagerRequestsRepo {
  SupabaseManagerRequestsRepo(this.client, this.approvals);
  final SupabaseClient client;
  final ApprovalsRepo approvals;

  Future<List<Map<String, dynamic>>> _all(dynamic query) async {
    final rows = <Map<String, dynamic>>[];
    for (var page = 0; ; page++) {
      final batch = await query.range(page * 500, page * 500 + 499) as List;
      rows.addAll(batch.map((e) => Map<String, dynamic>.from(e as Map)));
      if (batch.length < 500) return rows;
    }
  }

  @override
  Future<ManagerRequestsData> load() async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Missing session');
    final actor = await client
        .from('users')
        .select('tenant_id, role, is_active, employee_id')
        .eq('id', uid)
        .single();
    if (!['manager', 'direct_manager'].contains(actor['role']) ||
        actor['is_active'] != true ||
        actor['employee_id'] == null) {
      throw StateError('Active linked manager required');
    }
    final tenant = actor['tenant_id'].toString();
    final team = await SupabaseManagerTeamRepo(client).load();
    if (team.members.isEmpty) {
      return ManagerRequestsData(role: actor['role'].toString());
    }
    final jobs = await _all(
      client
          .from('job_titles')
          .select('id, name')
          .eq('tenant_id', tenant)
          .order('id'),
    );
    final jobNames = {for (final j in jobs) j['id'].toString(): j['name']};
    final result = <Map<String, dynamic>>[];
    for (var start = 0; start < team.members.length; start += 100) {
      final members = team.members.skip(start).take(100).toList();
      final ids = members.map((m) => m.id).toList();
      final employees = await _all(
        client
            .from('employees')
            .select('id, job_title_id')
            .eq('tenant_id', tenant)
            .inFilter('id', ids)
            .order('id'),
      );
      final roles = {
        for (final e in employees)
          e['id'].toString(): jobNames[e['job_title_id'].toString()],
      };
      final rows = await _all(
        client
            .from('approval_requests')
            .select('*')
            .eq('tenant_id', tenant)
            .inFilter('employee_id', ids)
            .order('created_at', ascending: false)
            .order('id'),
      );
      final missingAttachmentIds = rows
          .where((r) {
            final p = r['payload'] as Map? ?? {};
            return r['request_type'] == 'leave' &&
                (p['file_url']?.toString().trim() ?? '').isEmpty &&
                p['leave_id'] != null;
          })
          .map((r) => (r['payload'] as Map)['leave_id'].toString())
          .toSet()
          .toList();
      final attachments = <Map<String, dynamic>>[];
      for (
        var offset = 0;
        offset < missingAttachmentIds.length;
        offset += 100
      ) {
        attachments.addAll(
          await _all(
            client
                .from('leave_requests')
                .select('id, tenant_id, employee_id, file_url')
                .eq('tenant_id', tenant)
                .inFilter('employee_id', ids)
                .inFilter(
                  'id',
                  missingAttachmentIds.skip(offset).take(100).toList(),
                )
                .order('id'),
          ),
        );
      }
      for (final row in mergeManagerLeaveAttachments(rows, attachments)) {
        final member = members.firstWhere(
          (m) => m.id == row['employee_id'].toString(),
        );
        result.add({
          ...row,
          'employee': {'full_name': member.name},
          'job_title': roles[member.id],
        });
      }
    }
    result.sort((a, b) => '${b['created_at']}'.compareTo('${a['created_at']}'));
    return ManagerRequestsData(rows: result, role: actor['role'].toString());
  }

  @override
  Future<void> decide(String id, bool approve, String reason) async {
    if (!approve && reason.trim().isEmpty) {
      throw ArgumentError('Rejection reason required');
    }
    // Recheck current company, active team membership and routing before using the existing approval flow.
    final data = await load();
    final matches = data.rows.where((r) => r['id'].toString() == id);
    if (matches.isEmpty || !managerCanDecideRequest(matches.first, data.role)) {
      throw StateError('Request is no longer assigned to this manager');
    }
    if (approve) {
      await approvals.approve(id);
    } else {
      await approvals.reject(id, reason: reason.trim());
    }
  }
}
