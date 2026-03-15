part of 'employee_repo_impl.dart';

mixin _EmployeesRepoCreateFallbackMixin on _EmployeesRepoCreatePayloadMixin {
  Future<String> _createEmployeeFallback({
    required String tenantId,
    required String fullName,
    required String email,
    required String phone,
    required String nationalId,
    required String departmentId,
    required String jobTitleId,
    required DateTime hireDate,
    required String employmentType,
    required String contractType,
    required DateTime contractStart,
    required double basicSalary,
    required double housingAllowance,
    required double transportAllowance,
    required double otherAllowance,
    String? photoUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? nationality,
    String? education,
    DateTime? nationalIdExpiry,
    String? notes,
    String? managerId,
    String? maritalStatus,
    String? address,
    String? city,
    String? country,
    String? passportNo,
    DateTime? passportExpiry,
    DateTime? residencyIssueDate,
    DateTime? residencyExpiryDate,
    DateTime? insuranceStartDate,
    DateTime? insuranceExpiryDate,
    String? insuranceProvider,
    String? insurancePolicyNo,
    String? educationLevel,
    String? major,
    String? university,
    DateTime? contractEnd,
    int? probationMonths,
    String? contractFileUrl,
    String? bankName,
    String? iban,
    String? accountNumber,
    String? paymentMethod,
  }) async {
    final emp = await _client
        .from('employees')
        .insert(
          _employeeInsertPayload(
            tenantId: tenantId,
            fullName: fullName,
            email: email,
            phone: phone,
            nationalId: nationalId,
            departmentId: departmentId,
            jobTitleId: jobTitleId,
            hireDate: hireDate,
            employmentType: employmentType,
            photoUrl: photoUrl,
            dateOfBirth: dateOfBirth,
            gender: gender,
            nationality: nationality,
            education: education,
            nationalIdExpiry: nationalIdExpiry,
            notes: notes,
            managerId: managerId,
          ),
        )
        .select('id')
        .single();

    final empId = emp['id'] as String;

    await _client.from('employee_compensation').insert({
      'tenant_id': tenantId,
      'employee_id': empId,
      'basic_salary': basicSalary,
      'housing_allowance': housingAllowance,
      'transport_allowance': transportAllowance,
      'other_allowance': otherAllowance,
    });

    await _client.from('employee_personal').upsert(
      _employeePersonalPayload(
        tenantId: tenantId,
        employeeId: empId,
        nationality: nationality,
        maritalStatus: maritalStatus,
        address: address,
        city: city,
        country: country,
        passportNo: passportNo,
        passportExpiry: passportExpiry,
        residencyIssueDate: residencyIssueDate,
        residencyExpiryDate: residencyExpiryDate,
        insuranceStartDate: insuranceStartDate,
        insuranceExpiryDate: insuranceExpiryDate,
        insuranceProvider: insuranceProvider,
        insurancePolicyNo: insurancePolicyNo,
        educationLevel: educationLevel,
        major: major,
        university: university,
      ),
    );

    await _client.from('employee_financial').upsert(
      _employeeFinancialPayload(
        tenantId: tenantId,
        employeeId: empId,
        bankName: bankName,
        iban: iban,
        accountNumber: accountNumber,
        paymentMethod: paymentMethod,
      ),
    );

    await _client.from('employee_contracts').insert(
      _employeeContractPayload(
        tenantId: tenantId,
        employeeId: empId,
        contractType: contractType,
        contractStart: contractStart,
        contractEnd: contractEnd,
        probationMonths: probationMonths,
        contractFileUrl: contractFileUrl,
      ),
    );

    await _createAndLinkTestLogin(
      tenantId: tenantId,
      employeeId: empId,
      fullName: fullName,
      email: email,
    );
    return empId;
  }
}
