import 'package:supabase_flutter/supabase_flutter.dart';
import '../attendance/domain/models/attendance_record.dart';
import '../manager_team/data/manager_team_repo.dart';
import '../manager_team/domain/manager_team_data.dart';

class ManagerAttendanceData {
  const ManagerAttendanceData({
    this.members = const [],
    this.records = const [],
  });
  final List<TeamMember> members;
  final List<AttendanceRecord> records;
}

Duration? managerAttendanceDuration(AttendanceRecord r) {
  if (r.checkIn == null ||
      r.checkOut == null ||
      r.checkOut!.isBefore(r.checkIn!)) {
    return null;
  }
  return r.checkOut!.difference(r.checkIn!);
}

abstract class ManagerAttendanceRepo {
  Future<ManagerAttendanceData> load(DateTime month);
}

class SupabaseManagerAttendanceRepo implements ManagerAttendanceRepo {
  SupabaseManagerAttendanceRepo(this.client);
  final SupabaseClient client;
  @override
  Future<ManagerAttendanceData> load(DateTime month) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Missing session');
    final actor = await client
        .from('users')
        .select('tenant_id, role, is_active, employee_id')
        .eq('id', uid)
        .single();
    if (!['manager', 'direct_manager'].contains(actor['role']) ||
        actor['is_active'] != true ||
        actor['employee_id'] == null ||
        actor['tenant_id'] == null) {
      throw StateError('Active linked manager required');
    }
    final team = await SupabaseManagerTeamRepo(client).load();
    final records = <AttendanceRecord>[];
    String date(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    for (var start = 0; start < team.members.length; start += 100) {
      final members = team.members.skip(start).take(100).toList();
      for (var page = 0; ; page++) {
        final rows = await client
            .from('attendance_records')
            .select('*')
            .eq('tenant_id', actor['tenant_id'])
            .inFilter('employee_id', members.map((m) => m.id).toList())
            .gte('date', date(DateTime(month.year, month.month)))
            .lt('date', date(DateTime(month.year, month.month + 1)))
            .order('date', ascending: false)
            .order('id')
            .range(page * 500, page * 500 + 499);
        for (final row in rows) {
          final member = members.firstWhere((m) => m.id == row['employee_id']);
          records.add(
            AttendanceRecord.fromMap({
              ...row,
              'employee': {'full_name': member.name},
            }),
          );
        }
        if (rows.length < 500) break;
      }
    }
    records.sort((a, b) => b.date.compareTo(a.date));
    return ManagerAttendanceData(members: team.members, records: records);
  }
}
