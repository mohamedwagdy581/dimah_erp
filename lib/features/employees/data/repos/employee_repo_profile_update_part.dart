part of 'employee_repo_impl.dart';

mixin _EmployeesRepoProfileUpdateMixin on _EmployeesRepoProfileFetchMixin {
  @override
  Future<void> updateEmployeeProfile({
    required String employeeId,
    required String fullName,
    required String email,
    required String phone,
    String? photoUrl,
    required String status,
    String? nationality,
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
    String? bankName,
    String? iban,
    String? accountNumber,
    String? paymentMethod,
    String? contractType,
    DateTime? contractStart,
    DateTime? contractEnd,
    int? probationMonths,
    String? contractFileUrl,
  }) async {
    final tenantId = await _tenantId();

    await _client
        .from('employees')
        .update({
          'full_name': fullName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'photo_url': _normalizePhotoUrl(photoUrl),
          'status': status.trim(),
          'nationality': _normalizeOptionalText(nationality),
        })
        .eq('tenant_id', tenantId)
        .eq('id', employeeId);

    await _client.from('employee_personal').upsert({
      'employee_id': employeeId,
      'tenant_id': tenantId,
      'nationality': _normalizeOptionalText(nationality),
      'marital_status': _normalizeOptionalText(maritalStatus),
      'address': _normalizeOptionalText(address),
      'city': _normalizeOptionalText(city),
      'country': _normalizeOptionalText(country),
      'passport_no': _normalizeOptionalText(passportNo),
      'passport_expiry': passportExpiry == null ? null : _toDateOnly(passportExpiry),
      'residency_issue_date': residencyIssueDate == null
          ? null
          : _toDateOnly(residencyIssueDate),
      'residency_expiry_date': residencyExpiryDate == null
          ? null
          : _toDateOnly(residencyExpiryDate),
      'insurance_start_date': insuranceStartDate == null
          ? null
          : _toDateOnly(insuranceStartDate),
      'insurance_expiry_date': insuranceExpiryDate == null
          ? null
          : _toDateOnly(insuranceExpiryDate),
      'insurance_provider': _normalizeOptionalText(insuranceProvider),
      'insurance_policy_no': _normalizeOptionalText(insurancePolicyNo),
      'education_level': _normalizeOptionalText(educationLevel),
      'major': _normalizeOptionalText(major),
      'university': _normalizeOptionalText(university),
    });

    await _client.from('employee_financial').upsert({
      'employee_id': employeeId,
      'tenant_id': tenantId,
      'bank_name': _normalizeOptionalText(bankName),
      'iban': _normalizeOptionalText(iban),
      'account_number': _normalizeOptionalText(accountNumber),
      'payment_method': _normalizeOptionalText(paymentMethod) ?? 'bank',
    });

    final latestContract = await _client
        .from('employee_contracts')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final contractPayload = <String, dynamic>{
      'tenant_id': tenantId,
      'employee_id': employeeId,
      'contract_type': _normalizeOptionalText(contractType) ?? 'full_time',
      'end_date': contractEnd == null ? null : _toDateOnly(contractEnd),
      'probation_months': probationMonths,
      'file_url': _normalizeOptionalText(contractFileUrl),
    };
    if (contractStart != null) {
      contractPayload['start_date'] = _toDateOnly(contractStart);
    }

    if (latestContract != null) {
      await _client
          .from('employee_contracts')
          .update(contractPayload)
          .eq('tenant_id', tenantId)
          .eq('id', latestContract['id'].toString());
    } else if (contractStart != null) {
      await _client.from('employee_contracts').insert(contractPayload);
    }
  }
}
