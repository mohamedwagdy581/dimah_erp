part of 'employee_repo_impl.dart';

mixin _EmployeesRepoCreatePayloadMixin on _EmployeesRepoCreateHelpersMixin {
  Map<String, dynamic> _employeeInsertPayload({
    required String tenantId,
    required String fullName,
    required String email,
    required String phone,
    required String nationalId,
    required String departmentId,
    required String jobTitleId,
    required DateTime hireDate,
    required String employmentType,
    String? photoUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? nationality,
    String? education,
    DateTime? nationalIdExpiry,
    String? notes,
    String? managerId,
  }) {
    return {
      'tenant_id': tenantId,
      'full_name': fullName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'photo_url': photoUrl,
      'national_id': nationalId.trim(),
      'date_of_birth': dateOfBirth == null ? null : _toDateOnly(dateOfBirth),
      'gender': _normalizeOptionalText(gender),
      'nationality': _normalizeOptionalText(nationality),
      'education': _normalizeOptionalText(education),
      'national_id_expiry':
          nationalIdExpiry == null ? null : _toDateOnly(nationalIdExpiry),
      'manager_id': managerId,
      'notes': _normalizeOptionalText(notes),
      'department_id': departmentId,
      'job_title_id': jobTitleId,
      'hire_date': _toDateOnly(hireDate),
      'employment_type': employmentType,
      'status': 'active',
    };
  }

  Map<String, dynamic> _employeePersonalPayload({
    required String tenantId,
    required String employeeId,
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
  }) {
    return {
      'employee_id': employeeId,
      'tenant_id': tenantId,
      'nationality': _normalizeOptionalText(nationality),
      'marital_status': _normalizeOptionalText(maritalStatus),
      'address': _normalizeOptionalText(address),
      'city': _normalizeOptionalText(city),
      'country': _normalizeOptionalText(country),
      'passport_no': _normalizeOptionalText(passportNo),
      'passport_expiry': passportExpiry == null ? null : _toDateOnly(passportExpiry),
      'residency_issue_date':
          residencyIssueDate == null ? null : _toDateOnly(residencyIssueDate),
      'residency_expiry_date':
          residencyExpiryDate == null ? null : _toDateOnly(residencyExpiryDate),
      'insurance_start_date':
          insuranceStartDate == null ? null : _toDateOnly(insuranceStartDate),
      'insurance_expiry_date':
          insuranceExpiryDate == null ? null : _toDateOnly(insuranceExpiryDate),
      'insurance_provider': _normalizeOptionalText(insuranceProvider),
      'insurance_policy_no': _normalizeOptionalText(insurancePolicyNo),
      'education_level': _normalizeOptionalText(educationLevel),
      'major': _normalizeOptionalText(major),
      'university': _normalizeOptionalText(university),
    };
  }

  Map<String, dynamic> _employeeFinancialPayload({
    required String tenantId,
    required String employeeId,
    String? bankName,
    String? iban,
    String? accountNumber,
    String? paymentMethod,
  }) {
    return {
      'employee_id': employeeId,
      'tenant_id': tenantId,
      'bank_name': _normalizeOptionalText(bankName),
      'iban': _normalizeOptionalText(iban),
      'account_number': _normalizeOptionalText(accountNumber),
      'payment_method': _normalizeOptionalText(paymentMethod) ?? 'bank',
    };
  }

  Map<String, dynamic> _employeeContractPayload({
    required String tenantId,
    required String employeeId,
    required String contractType,
    required DateTime contractStart,
    DateTime? contractEnd,
    int? probationMonths,
    String? contractFileUrl,
  }) {
    return {
      'tenant_id': tenantId,
      'employee_id': employeeId,
      'contract_type': contractType,
      'start_date': _toDateOnly(contractStart),
      'end_date': contractEnd == null ? null : _toDateOnly(contractEnd),
      'probation_months': probationMonths,
      'file_url': _normalizeOptionalText(contractFileUrl),
    };
  }
}
