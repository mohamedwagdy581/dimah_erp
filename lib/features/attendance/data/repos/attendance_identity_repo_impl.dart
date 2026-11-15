import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repos/attendance_identity_repo.dart';

class AttendanceIdentityRepoImpl implements AttendanceIdentityRepo {
  AttendanceIdentityRepoImpl(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Map<String, String>>> fetchAll() => _request(() async {
    final result = await _client.rpc('list_employee_attendance_identities');
    return (result as List)
        .map(
          (row) => {
            'id': row['employee_id'] as String,
            'full_name': row['full_name'] as String,
            'device_employee_number': row['device_employee_number'] as String,
          },
        )
        .toList();
  });

  Future<T> _request<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST202' || error.code == '42883') {
        throw StateError(
          'ثبّت ملفات ربط البصمة والاستيراد أولًا: install_attendance_identity.sql وinstall_attendance_identity_import.sql / Install attendance identity SQL files first.',
        );
      }
      if (error.code == '23505') {
        throw StateError(
          'رقم البصمة مرتبط بموظف آخر / This device number belongs to another employee.',
        );
      }
      rethrow;
    }
  }

  String _number(String value) {
    if (!isValidAttendanceNumber(value)) {
      throw ArgumentError('Invalid device employee number');
    }
    return normalizeAttendanceNumber(value);
  }

  @override
  Future<String?> fetch(String employeeId) => _request(() async {
    final result = await _client.rpc(
      'get_employee_attendance_identity',
      params: {'p_employee_id': employeeId},
    );
    return result?.toString();
  });

  @override
  Future<void> check(String number, {String? employeeId}) => _request(() async {
    await _client.rpc(
      'check_employee_attendance_identity',
      params: {'p_number': _number(number), 'p_employee_id': employeeId},
    );
  });

  @override
  Future<void> save(String employeeId, String number) => _request(() async {
    await _client.rpc(
      'set_employee_attendance_identity',
      params: {'p_employee_id': employeeId, 'p_number': _number(number)},
    );
  });
}
