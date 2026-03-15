part of 'employee_repo_impl.dart';

mixin _EmployeesRepoVersionsMixin on _EmployeesRepoExpiryAlertsMixin {
  @override
  Future<void> addEmployeeContractVersion({
    required String employeeId,
    required String contractType,
    required DateTime startDate,
    DateTime? endDate,
    int? probationMonths,
    String? fileUrl,
  }) async {
    final tenantId = await _tenantId();
    await _client.from('employee_contracts').insert({
      'tenant_id': tenantId,
      'employee_id': employeeId,
      'contract_type': contractType.trim().isEmpty
          ? 'full_time'
          : contractType.trim(),
      'start_date': _toDateOnly(startDate),
      'end_date': endDate == null ? null : _toDateOnly(endDate),
      'probation_months': probationMonths,
      'file_url': _normalizeOptionalText(fileUrl),
    });
  }

  @override
  Future<void> addEmployeeCompensationVersion({
    required String employeeId,
    required double basicSalary,
    required double housingAllowance,
    required double transportAllowance,
    required double otherAllowance,
    DateTime? effectiveAt,
    String? note,
  }) async {
    final tenantId = await _tenantId();

    await _client.from('employee_compensation').upsert({
      'tenant_id': tenantId,
      'employee_id': employeeId,
      'basic_salary': basicSalary,
      'housing_allowance': housingAllowance,
      'transport_allowance': transportAllowance,
      'other_allowance': otherAllowance,
    });

    try {
      await _client.from('employee_compensation_history').insert({
        'tenant_id': tenantId,
        'employee_id': employeeId,
        'basic_salary': basicSalary,
        'housing_allowance': housingAllowance,
        'transport_allowance': transportAllowance,
        'other_allowance': otherAllowance,
        'effective_at': effectiveAt == null ? null : _toDateOnly(effectiveAt),
        'note': _normalizeOptionalText(note),
      });
    } catch (_) {
      // Keep current compensation update working even if history table is not deployed yet.
    }
  }
}
