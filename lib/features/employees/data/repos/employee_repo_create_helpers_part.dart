part of 'employee_repo_impl.dart';

mixin _EmployeesRepoCreateHelpersMixin on _EmployeesRepoEmployeeLookupMixin {
  Future<String?> _resolveDepartmentManagerId({
    required String tenantId,
    required String departmentId,
    required String? managerId,
  }) async {
    final normalizedManagerId = _normalizeOptionalText(managerId);
    if (normalizedManagerId != null) return normalizedManagerId;

    try {
      final dept = await _client
          .from('departments')
          .select('manager_id')
          .eq('tenant_id', tenantId)
          .eq('id', departmentId)
          .maybeSingle();
      return dept?['manager_id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _createEmployeeRpcParams({
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
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_full_name': fullName.trim(),
      'p_email': email.trim(),
      'p_phone': phone.trim(),
      'p_photo_url': photoUrl,
      'p_national_id': nationalId.trim(),
      'p_date_of_birth': dateOfBirth == null ? null : _toDateOnly(dateOfBirth),
      'p_gender': _normalizeOptionalText(gender),
      'p_nationality': _normalizeOptionalText(nationality),
      'p_education': _normalizeOptionalText(education),
      'p_national_id_expiry': nationalIdExpiry == null ? null : _toDateOnly(nationalIdExpiry),
      'p_notes': _normalizeOptionalText(notes),
      'p_manager_id': managerId,
      'p_marital_status': _normalizeOptionalText(maritalStatus),
      'p_address': _normalizeOptionalText(address),
      'p_city': _normalizeOptionalText(city),
      'p_country': _normalizeOptionalText(country),
      'p_passport_no': _normalizeOptionalText(passportNo),
      'p_passport_expiry': passportExpiry == null ? null : _toDateOnly(passportExpiry),
      'p_residency_issue_date': residencyIssueDate == null ? null : _toDateOnly(residencyIssueDate),
      'p_residency_expiry_date': residencyExpiryDate == null ? null : _toDateOnly(residencyExpiryDate),
      'p_insurance_start_date': insuranceStartDate == null ? null : _toDateOnly(insuranceStartDate),
      'p_insurance_expiry_date': insuranceExpiryDate == null ? null : _toDateOnly(insuranceExpiryDate),
      'p_insurance_provider': _normalizeOptionalText(insuranceProvider),
      'p_insurance_policy_no': _normalizeOptionalText(insurancePolicyNo),
      'p_education_level': _normalizeOptionalText(educationLevel),
      'p_major': _normalizeOptionalText(major),
      'p_university': _normalizeOptionalText(university),
      'p_department_id': departmentId,
      'p_job_title_id': jobTitleId,
      'p_hire_date': _toDateOnly(hireDate),
      'p_employment_type': employmentType,
      'p_contract_type': contractType,
      'p_contract_start': _toDateOnly(contractStart),
      'p_contract_end': contractEnd == null ? null : _toDateOnly(contractEnd),
      'p_probation_months': probationMonths,
      'p_contract_file_url': _normalizeOptionalText(contractFileUrl),
      'p_basic_salary': basicSalary,
      'p_housing_allowance': housingAllowance,
      'p_transport_allowance': transportAllowance,
      'p_other_allowance': otherAllowance,
      'p_bank_name': _normalizeOptionalText(bankName),
      'p_iban': _normalizeOptionalText(iban),
      'p_account_number': _normalizeOptionalText(accountNumber),
      'p_payment_method': _normalizeOptionalText(paymentMethod),
    };
  }
}
