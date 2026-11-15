import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeStatusRepo {
  EmployeeStatusRepo(this.client);
  final SupabaseClient client;

  Future<void> setStatus(String employeeId, String status) async {
    if (!['active', 'inactive'].contains(status)) {
      throw ArgumentError.value(status, 'status');
    }
    await client.rpc(
      'hr_set_employee_status',
      params: {'p_employee_id': employeeId, 'p_status': status},
    );
  }
}
