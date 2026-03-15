part of 'employee_repo_impl.dart';

mixin _EmployeesRepoProfileFetchQueriesMixin on _EmployeesRepoProfileFetchHelpersMixin {
  Future<Map<String, dynamic>?> _fetchEmployeeBase({
    required String tenantId,
    required String employeeId,
  }) {
    return _client
        .from('employees')
        .select(
          'id, full_name, email, phone, status, hire_date, '
          'national_id, date_of_birth, gender, nationality, education, employment_type, photo_url, '
          'department:departments!employees_department_id_fkey(name), '
          'job_title:job_titles(name)',
        )
        .eq('tenant_id', tenantId)
        .eq('id', employeeId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> _fetchEmployeePersonal(String tenantId, String employeeId) {
    return _client
        .from('employee_personal')
        .select(
          'nationality, marital_status, address, city, country, '
          'passport_no, passport_expiry, residency_issue_date, residency_expiry_date, '
          'insurance_start_date, insurance_expiry_date, insurance_provider, insurance_policy_no, '
          'education_level, major, university',
        )
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> _fetchEmployeePersonalFallback(String employeeId) {
    return _client
        .from('employee_personal')
        .select(
          'nationality, marital_status, address, city, country, '
          'passport_no, passport_expiry, residency_issue_date, residency_expiry_date, '
          'insurance_start_date, insurance_expiry_date, insurance_provider, insurance_policy_no, '
          'education_level, major, university',
        )
        .eq('employee_id', employeeId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> _fetchEmployeeFinancial(String tenantId, String employeeId) {
    return _client
        .from('employee_financial')
        .select('bank_name, iban, account_number, payment_method')
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> _fetchEmployeeFinancialFallback(String employeeId) {
    return _client
        .from('employee_financial')
        .select('bank_name, iban, account_number, payment_method')
        .eq('employee_id', employeeId)
        .maybeSingle();
  }
}
