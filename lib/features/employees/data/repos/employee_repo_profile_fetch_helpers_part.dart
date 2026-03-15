part of 'employee_repo_impl.dart';

mixin _EmployeesRepoProfileFetchHelpersMixin on _EmployeesRepoEmployeeCreateMixin {
  Future<Map<String, dynamic>?> _legacyFinancialFromEmployees({
    required String tenantId,
    required String employeeId,
  }) async {
    try {
      return await _client
          .from('employees')
          .select('bank_name, iban, account_number, payment_method')
          .eq('tenant_id', tenantId)
          .eq('id', employeeId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }
}
