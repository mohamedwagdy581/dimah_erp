part of 'employee_repo_impl.dart';

mixin _EmployeesRepoProfileFetchMixin on _EmployeesRepoProfileFetchQueriesMixin {
  @override
  Future<EmployeeProfileDetails> fetchEmployeeProfile({
    required String employeeId,
  }) async {
    final tenantId = await _tenantId();

    final employee = await _fetchEmployeeBase(
      tenantId: tenantId,
      employeeId: employeeId,
    );
    if (employee == null) throw Exception('Employee not found');

    final personal = await _fetchEmployeePersonal(tenantId, employeeId);
    final personalFallback = personal == null
        ? await _fetchEmployeePersonalFallback(employeeId)
        : null;

    final compensation = await _client
        .from('employee_compensation')
        .select('basic_salary, housing_allowance, transport_allowance, other_allowance')
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .maybeSingle();

    var compensationHistory = <Map<String, dynamic>>[];
    try {
      final compensationHistoryRes = await _client
          .from('employee_compensation_history')
          .select(
            'id, basic_salary, housing_allowance, transport_allowance, '
            'other_allowance, effective_at, note, created_at',
          )
          .eq('tenant_id', tenantId)
          .eq('employee_id', employeeId)
          .order('effective_at', ascending: false)
          .order('created_at', ascending: false)
          .limit(30);
      compensationHistory = (compensationHistoryRes as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (_) {
      compensationHistory = [];
    }

    if (compensationHistory.isEmpty && compensation != null) {
      compensationHistory = [
        {
          'id': 'current',
          'basic_salary': compensation['basic_salary'],
          'housing_allowance': compensation['housing_allowance'],
          'transport_allowance': compensation['transport_allowance'],
          'other_allowance': compensation['other_allowance'],
          'effective_at': employee['hire_date'],
          'note': 'Current compensation',
          'created_at': employee['hire_date'],
        },
      ];
    }

    final financial = await _fetchEmployeeFinancial(tenantId, employeeId);
    final financialFallback = financial == null
        ? await _fetchEmployeeFinancialFallback(employeeId)
        : null;

    final contracts = await _client
        .from('employee_contracts')
        .select(
          'id, contract_type, start_date, end_date, probation_months, file_url, created_at',
        )
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false)
        .limit(1) as List;
    final contractHistory = await _client
        .from('employee_contracts')
        .select(
          'id, contract_type, start_date, end_date, probation_months, file_url, created_at',
        )
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false)
        .limit(20) as List;
    final docsRes = await _client
        .from('employee_documents')
        .select('id, doc_type, file_url, issued_at, expires_at, created_at')
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false)
        .limit(30);

    final contractsFallbackRes = contracts.isEmpty
        ? await _client
              .from('employee_contracts')
              .select(
                'id, contract_type, start_date, end_date, probation_months, file_url, created_at',
              )
              .eq('employee_id', employeeId)
              .order('created_at', ascending: false)
              .limit(1)
        : const <dynamic>[];
    final contractHistoryFallback = contractHistory.isEmpty
        ? await _client
              .from('employee_contracts')
              .select(
                'id, contract_type, start_date, end_date, probation_months, file_url, created_at',
              )
              .eq('employee_id', employeeId)
              .order('created_at', ascending: false)
              .limit(20)
        : const <dynamic>[];

    final contract = contracts.isNotEmpty
        ? contracts.first
        : (contractsFallbackRes.isNotEmpty
              ? contractsFallbackRes.first
              : <String, dynamic>{
                  'contract_type': employee['employment_type'],
                  'start_date': employee['hire_date'],
                });

    return EmployeeProfileDetails.fromMaps(
      employee: employee,
      personal: personal ?? personalFallback,
      compensation: compensation,
      compensationHistory: compensationHistory,
      financial: financial ??
          financialFallback ??
          await _legacyFinancialFromEmployees(tenantId: tenantId, employeeId: employeeId),
      contract: contract,
      contractHistory: (contracts.isNotEmpty ? contractHistory : contractHistoryFallback)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      documents: (docsRes as List).map((e) => e as Map<String, dynamic>).toList(),
    );
  }
}
