import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/env.dart';
import '../../domain/repos/employee_repo.dart';
import '../../domain/models/employee.dart';
import '../../domain/models/expiry_alert.dart';
import '../../domain/models/employee_lookup.dart';
import '../../domain/models/employee_profile_details.dart';

class EmployeesRepoImpl implements EmployeesRepo {
  EmployeesRepoImpl(this._client);

  final SupabaseClient _client;

  String _toDateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

  Future<String> _tenantId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final me = await _client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();

    final t = me['tenant_id'];
    if (t == null) throw Exception('Missing tenant_id for current user');

    return t.toString();
  }

  String _buildTestPasswordFromEmail(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'Employee@2030';
    final normalized = local.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (normalized.isEmpty) return 'Employee@2030';
    final firstUpper = normalized[0].toUpperCase();
    final restLower = normalized.length > 1
        ? normalized.substring(1).toLowerCase()
        : '';
    return '$firstUpper$restLower@2030';
  }

  Future<String?> _signUpAuthUserForTesting({
    required String email,
    required String password,
  }) async {
    final client = HttpClient();
    try {
      final req = await client.postUrl(
        Uri.parse('${Env.supabaseUrl}/auth/v1/signup'),
      );
      req.headers.set('apikey', Env.supabaseAnonKey);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.write(
        jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final res = await req.close();
      final body = await utf8.decoder.bind(res).join();
      final map = body.trim().isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(body) as Map<String, dynamic>);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final user = map['user'];
        if (user is Map && user['id'] != null) {
          return user['id'].toString();
        }
        return null;
      }

      final message =
          map['msg']?.toString() ??
          map['message']?.toString() ??
          map['error_description']?.toString() ??
          map['error']?.toString() ??
          'Auth signup failed with status ${res.statusCode}';

      if (message.toLowerCase().contains('already registered')) {
        return null;
      }
      throw Exception(message);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _upsertAppUserLink({
    required String tenantId,
    required String employeeId,
    required String fullName,
    required String email,
    String? authUserId,
  }) async {
    if (authUserId != null && authUserId.trim().isNotEmpty) {
      await _client.from('users').upsert({
        'id': authUserId,
        'tenant_id': tenantId,
        'email': email,
        'name': fullName,
        'role': 'employee',
        'employee_id': employeeId,
        'is_active': true,
      });
      return;
    }

    final existing = await _client
        .from('users')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('email', email)
        .maybeSingle();
    if (existing == null) {
      throw Exception(
        'Test login could not be auto-linked: existing auth user was not found in public.users.',
      );
    }

    await _client
        .from('users')
        .update({
          'name': fullName,
          'role': 'employee',
          'employee_id': employeeId,
          'is_active': true,
        })
        .eq('tenant_id', tenantId)
        .eq('id', existing['id'].toString());
  }

  Future<void> _createAndLinkTestLogin({
    required String tenantId,
    required String employeeId,
    required String fullName,
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) return;

    final generatedPassword = _buildTestPasswordFromEmail(normalizedEmail);
    final authUserId = await _signUpAuthUserForTesting(
      email: normalizedEmail,
      password: generatedPassword,
    );
    await _upsertAppUserLink(
      tenantId: tenantId,
      employeeId: employeeId,
      fullName: fullName.trim(),
      email: normalizedEmail,
      authUserId: authUserId,
    );
  }

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

  @override
  Future<({List<Employee> items, int total})> fetchEmployees({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    String? actorRole,
    String? actorEmployeeId,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    final tenantId = await _tenantId();
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final s = search?.trim();

    dynamic listQ = _client
        .from('employees')
        .select(
          'id, tenant_id, full_name, email, phone, status, hire_date, created_at, '
          'department_id, job_title_id, '
          'department:departments!employees_department_id_fkey(name), '
          'job_title:job_titles(name)',
        )
        .eq('tenant_id', tenantId);

    if (actorRole == 'manager' &&
        actorEmployeeId != null &&
        actorEmployeeId.trim().isNotEmpty) {
      final scopedIds = await _managerScopedEmployeeIds(
        tenantId: tenantId,
        managerEmployeeId: actorEmployeeId,
      );
      if (scopedIds.isEmpty) {
        return (items: const <Employee>[], total: 0);
      }
      listQ = listQ.inFilter('id', scopedIds);
    }

    if (status != null && status.trim().isNotEmpty) {
      listQ = listQ.eq('status', status);
    }

    if (s != null && s.isNotEmpty) {
      final escaped = s.replaceAll('%', r'\%').replaceAll('_', r'\_');
      listQ = listQ.or(
        'full_name.ilike.%$escaped%,email.ilike.%$escaped%,phone.ilike.%$escaped%',
      );
    }

    listQ = listQ.order(sortBy, ascending: ascending).range(from, to);

    final listRes = await listQ;
    final items = (listRes as List)
        .map((e) => Employee.fromMap(e as Map<String, dynamic>))
        .toList();

    dynamic countQ = _client
        .from('employees')
        .select('id')
        .eq('tenant_id', tenantId);

    if (actorRole == 'manager' &&
        actorEmployeeId != null &&
        actorEmployeeId.trim().isNotEmpty) {
      final scopedIds = await _managerScopedEmployeeIds(
        tenantId: tenantId,
        managerEmployeeId: actorEmployeeId,
      );
      if (scopedIds.isEmpty) {
        return (items: items, total: 0);
      }
      countQ = countQ.inFilter('id', scopedIds);
    }

    if (status != null && status.trim().isNotEmpty) {
      countQ = countQ.eq('status', status);
    }

    if (s != null && s.isNotEmpty) {
      final escaped = s.replaceAll('%', r'\%').replaceAll('_', r'\_');
      countQ = countQ.or(
        'full_name.ilike.%$escaped%,email.ilike.%$escaped%,phone.ilike.%$escaped%',
      );
    }

    final countRes = await countQ;
    final total = (countRes as List).length;

    return (items: items, total: total);
  }

  Future<List<String>> _managerScopedEmployeeIds({
    required String tenantId,
    required String managerEmployeeId,
  }) async {
    final managedDepartmentsRes = await _client
        .from('departments')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('manager_id', managerEmployeeId);
    final managedDepartmentIds = (managedDepartmentsRes as List)
        .map((e) => e['id'].toString())
        .toList();

    final directReportsRes = await _client
        .from('employees')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('manager_id', managerEmployeeId);
    final directReportIds = (directReportsRes as List)
        .map((e) => e['id'].toString())
        .toList();

    final deptEmployeesIds = <String>[];
    if (managedDepartmentIds.isNotEmpty) {
      final deptEmployeesRes = await _client
          .from('employees')
          .select('id')
          .eq('tenant_id', tenantId)
          .inFilter('department_id', managedDepartmentIds);
      deptEmployeesIds.addAll(
        (deptEmployeesRes as List).map((e) => e['id'].toString()),
      );
    }

    final unique = {...directReportIds, ...deptEmployeesIds};
    unique.remove(managerEmployeeId);
    return unique.toList();
  }

  @override
  Future<String> createEmployee({
    required String fullName,
    required String email,
    required String phone,
    String? photoUrl,
    required String nationalId,

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

    required String departmentId,
    required String jobTitleId,
    required DateTime hireDate,
    required String employmentType,
    required String contractType,
    required DateTime contractStart,
    DateTime? contractEnd,
    int? probationMonths,
    String? contractFileUrl,

    required double basicSalary,
    required double housingAllowance,
    required double transportAllowance,
    required double otherAllowance,
    String? bankName,
    String? iban,
    String? accountNumber,
    String? paymentMethod,
  }) async {
    final tenantId = await _tenantId();
    final effectivePhotoUrl =
        (photoUrl == null || photoUrl.trim().isEmpty || !photoUrl.startsWith('http'))
        ? null
        : photoUrl.trim();
    String? effectiveManagerId = managerId;
    if (effectiveManagerId == null || effectiveManagerId.trim().isEmpty) {
      try {
        final dept = await _client
            .from('departments')
            .select('manager_id')
            .eq('tenant_id', tenantId)
            .eq('id', departmentId)
            .maybeSingle();
        effectiveManagerId = dept?['manager_id']?.toString();
      } catch (_) {
        effectiveManagerId = null;
      }
    }

    try {
      final res = await _client.rpc(
        'create_employee_with_comp',
        params: {
          'p_tenant_id': tenantId,
          'p_full_name': fullName.trim(),
          'p_email': email.trim(),
          'p_phone': phone.trim(),
          'p_photo_url': effectivePhotoUrl,
          'p_national_id': nationalId.trim(),
          'p_date_of_birth':
              dateOfBirth == null ? null : _toDateOnly(dateOfBirth),
          'p_gender':
              (gender == null || gender.trim().isEmpty) ? null : gender.trim(),
          'p_nationality': (nationality == null || nationality.trim().isEmpty)
              ? null
              : nationality.trim(),
          'p_education': (education == null || education.trim().isEmpty)
              ? null
              : education.trim(),
          'p_national_id_expiry': nationalIdExpiry == null
              ? null
              : _toDateOnly(nationalIdExpiry),
          'p_notes':
              (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
          'p_manager_id': effectiveManagerId,
          'p_marital_status':
              (maritalStatus == null || maritalStatus.trim().isEmpty)
              ? null
              : maritalStatus.trim(),
          'p_address':
              (address == null || address.trim().isEmpty) ? null : address.trim(),
          'p_city': (city == null || city.trim().isEmpty) ? null : city.trim(),
          'p_country':
              (country == null || country.trim().isEmpty) ? null : country.trim(),
          'p_passport_no':
              (passportNo == null || passportNo.trim().isEmpty)
              ? null
              : passportNo.trim(),
          'p_passport_expiry': passportExpiry == null
              ? null
              : _toDateOnly(passportExpiry),
          'p_residency_issue_date': residencyIssueDate == null
              ? null
              : _toDateOnly(residencyIssueDate),
          'p_residency_expiry_date': residencyExpiryDate == null
              ? null
              : _toDateOnly(residencyExpiryDate),
          'p_insurance_start_date': insuranceStartDate == null
              ? null
              : _toDateOnly(insuranceStartDate),
          'p_insurance_expiry_date': insuranceExpiryDate == null
              ? null
              : _toDateOnly(insuranceExpiryDate),
          'p_insurance_provider':
              (insuranceProvider == null || insuranceProvider.trim().isEmpty)
              ? null
              : insuranceProvider.trim(),
          'p_insurance_policy_no':
              (insurancePolicyNo == null || insurancePolicyNo.trim().isEmpty)
              ? null
              : insurancePolicyNo.trim(),
          'p_education_level':
              (educationLevel == null || educationLevel.trim().isEmpty)
              ? null
              : educationLevel.trim(),
          'p_major':
              (major == null || major.trim().isEmpty) ? null : major.trim(),
          'p_university':
              (university == null || university.trim().isEmpty)
              ? null
              : university.trim(),
          'p_department_id': departmentId,
          'p_job_title_id': jobTitleId,
          'p_hire_date': _toDateOnly(hireDate),
          'p_employment_type': employmentType,
          'p_contract_type': contractType,
          'p_contract_start': _toDateOnly(contractStart),
          'p_contract_end': contractEnd == null
              ? null
              : _toDateOnly(contractEnd),
          'p_probation_months': probationMonths,
          'p_contract_file_url': (contractFileUrl == null ||
                  contractFileUrl.trim().isEmpty)
              ? null
              : contractFileUrl.trim(),
          'p_basic_salary': basicSalary,
          'p_housing_allowance': housingAllowance,
          'p_transport_allowance': transportAllowance,
          'p_other_allowance': otherAllowance,
          'p_bank_name':
              (bankName == null || bankName.trim().isEmpty) ? null : bankName.trim(),
          'p_iban': (iban == null || iban.trim().isEmpty) ? null : iban.trim(),
          'p_account_number': (accountNumber == null ||
                  accountNumber.trim().isEmpty)
              ? null
              : accountNumber.trim(),
          'p_payment_method': (paymentMethod == null ||
                  paymentMethod.trim().isEmpty)
              ? null
              : paymentMethod.trim(),
        },
      );

      if (res is String) return res;
      if (res is Map && res['employee_id'] != null) {
        final empId = res['employee_id'].toString();
        await _createAndLinkTestLogin(
          tenantId: tenantId,
          employeeId: empId,
          fullName: fullName,
          email: email,
        );
        return empId;
      }

      throw Exception('Invalid RPC response');
    } catch (_) {
      final emp = await _client
          .from('employees')
          .insert({
            'tenant_id': tenantId,
            'full_name': fullName.trim(),
            'email': email.trim(),
            'phone': phone.trim(),
            'photo_url': effectivePhotoUrl,
            'national_id': nationalId.trim(),
            'date_of_birth':
                dateOfBirth == null ? null : _toDateOnly(dateOfBirth),
            'gender':
                (gender == null || gender.trim().isEmpty) ? null : gender.trim(),
            'nationality':
                (nationality == null || nationality.trim().isEmpty)
                ? null
                : nationality.trim(),
            'education':
                (education == null || education.trim().isEmpty)
                ? null
                : education.trim(),
            'national_id_expiry': nationalIdExpiry == null
                ? null
                : _toDateOnly(nationalIdExpiry),
            'manager_id': effectiveManagerId,
            'notes':
                (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
            'department_id': departmentId,
            'job_title_id': jobTitleId,
            'hire_date': _toDateOnly(hireDate),
            'employment_type': employmentType,
            'status': 'active',
          })
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

      await _client.from('employee_personal').upsert({
        'employee_id': empId,
        'tenant_id': tenantId,
        'nationality': (nationality == null || nationality.trim().isEmpty)
            ? null
            : nationality.trim(),
        'marital_status': (maritalStatus == null || maritalStatus.trim().isEmpty)
            ? null
            : maritalStatus.trim(),
        'address': (address == null || address.trim().isEmpty)
            ? null
            : address.trim(),
        'city': (city == null || city.trim().isEmpty) ? null : city.trim(),
        'country': (country == null || country.trim().isEmpty)
            ? null
            : country.trim(),
        'passport_no': (passportNo == null || passportNo.trim().isEmpty)
            ? null
            : passportNo.trim(),
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
        'insurance_provider':
            (insuranceProvider == null || insuranceProvider.trim().isEmpty)
            ? null
            : insuranceProvider.trim(),
        'insurance_policy_no':
            (insurancePolicyNo == null || insurancePolicyNo.trim().isEmpty)
            ? null
            : insurancePolicyNo.trim(),
        'education_level':
            (educationLevel == null || educationLevel.trim().isEmpty)
                ? null
                : educationLevel.trim(),
        'major': (major == null || major.trim().isEmpty) ? null : major.trim(),
        'university': (university == null || university.trim().isEmpty)
            ? null
            : university.trim(),
      });

      await _client.from('employee_financial').upsert({
        'employee_id': empId,
        'tenant_id': tenantId,
        'bank_name':
            (bankName == null || bankName.trim().isEmpty) ? null : bankName.trim(),
        'iban': (iban == null || iban.trim().isEmpty) ? null : iban.trim(),
        'account_number':
            (accountNumber == null || accountNumber.trim().isEmpty)
            ? null
            : accountNumber.trim(),
        'payment_method':
            (paymentMethod == null || paymentMethod.trim().isEmpty)
            ? 'bank'
            : paymentMethod.trim(),
      });

      await _client.from('employee_contracts').insert({
        'tenant_id': tenantId,
        'employee_id': empId,
        'contract_type': contractType,
        'start_date': _toDateOnly(contractStart),
        'end_date': contractEnd == null ? null : _toDateOnly(contractEnd),
        'probation_months': probationMonths,
        'file_url': (contractFileUrl == null || contractFileUrl.trim().isEmpty)
            ? null
            : contractFileUrl.trim(),
      });

      await _createAndLinkTestLogin(
        tenantId: tenantId,
        employeeId: empId,
        fullName: fullName,
        email: email,
      );
      return empId;
    }
  }

  @override
  Future<List<EmployeeLookup>> fetchEmployeeLookup({
    String? search,
    int limit = 200,
  }) async {
    final tenantId = await _tenantId();
    final s = search?.trim();

    dynamic q = _client
        .from('employees')
        .select('id, full_name')
        .eq('tenant_id', tenantId)
        .order('full_name', ascending: true)
        .limit(limit);

    if (s != null && s.isNotEmpty) {
      final escaped = s.replaceAll('%', r'\%').replaceAll('_', r'\_');
      q = q.or('full_name.ilike.%$escaped%');
    }

    final res = await q;
    return (res as List)
        .map((e) => EmployeeLookup.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<EmployeeProfileDetails> fetchEmployeeProfile({
    required String employeeId,
  }) async {
    final tenantId = await _tenantId();

    final employee = await _client
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

    if (employee == null) {
      throw Exception('Employee not found');
    }

    final personal = await _client
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
    final personalFallback = personal == null
        ? await _client
              .from('employee_personal')
              .select(
                'nationality, marital_status, address, city, country, '
                'passport_no, passport_expiry, residency_issue_date, residency_expiry_date, '
                'insurance_start_date, insurance_expiry_date, insurance_provider, insurance_policy_no, '
                'education_level, major, university',
              )
              .eq('employee_id', employeeId)
              .maybeSingle()
        : null;

    final compensation = await _client
        .from('employee_compensation')
        .select(
          'basic_salary, housing_allowance, transport_allowance, other_allowance',
        )
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .maybeSingle();

    List<Map<String, dynamic>> compensationHistory = const [];
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
      compensationHistory = const [];
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

    final financial = await _client
        .from('employee_financial')
        .select('bank_name, iban, account_number, payment_method')
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .maybeSingle();
    final financialFallback = financial == null
        ? await _client
              .from('employee_financial')
              .select('bank_name, iban, account_number, payment_method')
              .eq('employee_id', employeeId)
              .maybeSingle()
        : null;
    final legacyFinancial =
        (financial == null && financialFallback == null)
        ? await _legacyFinancialFromEmployees(
            tenantId: tenantId,
            employeeId: employeeId,
          )
        : null;

    final contractsRes = await _client
        .from('employee_contracts')
        .select(
          'id, contract_type, start_date, end_date, probation_months, file_url, created_at',
        )
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false)
        .limit(1);
    final List<dynamic> contractsFallbackRes = (contractsRes as List).isEmpty
        ? await _client
              .from('employee_contracts')
              .select(
                'id, contract_type, start_date, end_date, probation_months, file_url, created_at',
              )
              .eq('employee_id', employeeId)
              .order('created_at', ascending: false)
              .limit(1)
        : const [];

    final contractsHistoryRes = await _client
        .from('employee_contracts')
        .select(
          'id, contract_type, start_date, end_date, probation_months, file_url, created_at',
        )
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false)
        .limit(20);

    final List<dynamic> contractsHistoryFallbackRes =
        (contractsHistoryRes as List).isEmpty
        ? await _client
              .from('employee_contracts')
              .select(
                'id, contract_type, start_date, end_date, probation_months, file_url, created_at',
              )
              .eq('employee_id', employeeId)
              .order('created_at', ascending: false)
              .limit(20)
        : const [];

    final contract = (contractsRes).isNotEmpty
        ? contractsRes.first
        : (contractsFallbackRes.isNotEmpty
              ? contractsFallbackRes.first
              : <String, dynamic>{
                  'contract_type': employee['employment_type'],
                  'start_date': employee['hire_date'],
                });

    final docsRes = await _client
        .from('employee_documents')
        .select('id, doc_type, file_url, issued_at, expires_at, created_at')
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false)
        .limit(30);

    final docs = (docsRes as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    return EmployeeProfileDetails.fromMaps(
      employee: employee,
      personal: personal ?? personalFallback,
      compensation: compensation,
      compensationHistory: compensationHistory,
      financial: financial ?? financialFallback ?? legacyFinancial,
      contract: contract,
      contractHistory: (contractsHistoryRes).isNotEmpty
          ? contractsHistoryRes
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
          : contractsHistoryFallbackRes
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList(),
      documents: docs,
    );
  }

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
    final effectivePhotoUrl =
        (photoUrl == null || photoUrl.trim().isEmpty || !photoUrl.startsWith('http'))
        ? null
        : photoUrl.trim();

    await _client
        .from('employees')
        .update({
          'full_name': fullName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'photo_url': effectivePhotoUrl,
          'status': status.trim(),
          'nationality': (nationality == null || nationality.trim().isEmpty)
              ? null
              : nationality.trim(),
        })
        .eq('tenant_id', tenantId)
        .eq('id', employeeId);

    await _client.from('employee_personal').upsert({
      'employee_id': employeeId,
      'tenant_id': tenantId,
      'nationality': (nationality == null || nationality.trim().isEmpty)
          ? null
          : nationality.trim(),
      'marital_status': (maritalStatus == null || maritalStatus.trim().isEmpty)
          ? null
          : maritalStatus.trim(),
      'address': (address == null || address.trim().isEmpty)
          ? null
          : address.trim(),
      'city': (city == null || city.trim().isEmpty) ? null : city.trim(),
      'country': (country == null || country.trim().isEmpty)
          ? null
          : country.trim(),
      'passport_no': (passportNo == null || passportNo.trim().isEmpty)
          ? null
          : passportNo.trim(),
      'passport_expiry':
          passportExpiry == null ? null : _toDateOnly(passportExpiry),
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
      'insurance_provider':
          (insuranceProvider == null || insuranceProvider.trim().isEmpty)
          ? null
          : insuranceProvider.trim(),
      'insurance_policy_no':
          (insurancePolicyNo == null || insurancePolicyNo.trim().isEmpty)
          ? null
          : insurancePolicyNo.trim(),
      'education_level':
          (educationLevel == null || educationLevel.trim().isEmpty)
              ? null
              : educationLevel.trim(),
      'major': (major == null || major.trim().isEmpty) ? null : major.trim(),
      'university': (university == null || university.trim().isEmpty)
          ? null
          : university.trim(),
    });

    await _client.from('employee_financial').upsert({
      'employee_id': employeeId,
      'tenant_id': tenantId,
      'bank_name': (bankName == null || bankName.trim().isEmpty)
          ? null
          : bankName.trim(),
      'iban': (iban == null || iban.trim().isEmpty) ? null : iban.trim(),
      'account_number': (accountNumber == null || accountNumber.trim().isEmpty)
          ? null
          : accountNumber.trim(),
      'payment_method':
          (paymentMethod == null || paymentMethod.trim().isEmpty)
              ? 'bank'
              : paymentMethod.trim(),
    });

    final latestContract = await _client
        .from('employee_contracts')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final Map<String, dynamic> contractPayload = {
      'tenant_id': tenantId,
      'employee_id': employeeId,
      'contract_type':
          (contractType == null || contractType.trim().isEmpty)
              ? 'full_time'
              : contractType.trim(),
      'end_date': contractEnd == null ? null : _toDateOnly(contractEnd),
      'probation_months': probationMonths,
      'file_url': (contractFileUrl == null || contractFileUrl.trim().isEmpty)
          ? null
          : contractFileUrl.trim(),
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

  @override
  Future<ExpiryAlertSettings> fetchExpiryAlertSettings() async {
    final tenantId = await _tenantId();
    final row = await _client
        .from('expiry_alert_settings')
        .select(
          'contract_alert_days, residency_alert_days, insurance_alert_days',
        )
        .eq('tenant_id', tenantId)
        .maybeSingle();

    if (row == null) {
      return const ExpiryAlertSettings(
        contractAlertDays: 90,
        residencyAlertDays: 90,
        insuranceAlertDays: 90,
      );
    }

    int asInt(dynamic v, int fallback) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;

    return ExpiryAlertSettings(
      contractAlertDays: asInt(row['contract_alert_days'], 90),
      residencyAlertDays: asInt(row['residency_alert_days'], 90),
      insuranceAlertDays: asInt(row['insurance_alert_days'], 90),
    );
  }

  @override
  Future<void> upsertExpiryAlertSettings(ExpiryAlertSettings settings) async {
    final tenantId = await _tenantId();
    try {
      await _client.rpc(
        'upsert_expiry_alert_settings',
        params: {
          'p_tenant_id': tenantId,
          'p_contract_alert_days': settings.contractAlertDays,
          'p_residency_alert_days': settings.residencyAlertDays,
          'p_insurance_alert_days': settings.insuranceAlertDays,
        },
      );
    } catch (_) {
      await _client.from('expiry_alert_settings').upsert({
        'tenant_id': tenantId,
        'contract_alert_days': settings.contractAlertDays,
        'residency_alert_days': settings.residencyAlertDays,
        'insurance_alert_days': settings.insuranceAlertDays,
      });
    }
  }

  @override
  Future<List<ExpiryAlertItem>> fetchExpiryAlerts() async {
    final tenantId = await _tenantId();
    final today = DateTime.now();

    final settings = await fetchExpiryAlertSettings();
    final maxDays = [
      settings.contractAlertDays,
      settings.residencyAlertDays,
      settings.insuranceAlertDays,
      120,
    ].reduce((a, b) => a > b ? a : b);
    final threshold = DateTime(
      today.year,
      today.month,
      today.day,
    ).add(Duration(days: maxDays + 1));

    final employeesRes = await _client
        .from('employees')
        .select('id, full_name')
        .eq('tenant_id', tenantId)
        .order('full_name', ascending: true);
    final employeeNameById = <String, String>{};
    for (final row in (employeesRes as List)) {
      final m = row as Map<String, dynamic>;
      employeeNameById[m['id'].toString()] = (m['full_name'] ?? '').toString();
    }

    final personalRes = await _client
        .from('employee_personal')
        .select(
          'employee_id, residency_expiry_date, insurance_expiry_date',
        )
        .eq('tenant_id', tenantId);

    final contractsRes = await _client
        .from('employee_contracts')
        .select('employee_id, end_date, created_at')
        .eq('tenant_id', tenantId)
        .not('end_date', 'is', null)
        .order('created_at', ascending: false);

    final latestContractEndByEmployee = <String, DateTime>{};
    for (final row in (contractsRes as List)) {
      final m = row as Map<String, dynamic>;
      final eid = m['employee_id']?.toString();
      if (eid == null || eid.isEmpty || latestContractEndByEmployee.containsKey(eid)) {
        continue;
      }
      final endDate = DateTime.tryParse((m['end_date'] ?? '').toString());
      if (endDate != null) {
        latestContractEndByEmployee[eid] = endDate;
      }
    }

    final items = <ExpiryAlertItem>[];
    int daysLeft(DateTime expiry) {
      final e = DateTime(expiry.year, expiry.month, expiry.day);
      final t = DateTime(today.year, today.month, today.day);
      return e.difference(t).inDays;
    }

    void maybeAdd({
      required String employeeId,
      required String type,
      required DateTime expiryDate,
      required int alertDays,
    }) {
      final left = daysLeft(expiryDate);
      if (left > alertDays) return;
      if (left > maxDays) return;
      if (expiryDate.isAfter(threshold)) return;
      items.add(
        ExpiryAlertItem(
          employeeId: employeeId,
          employeeName: employeeNameById[employeeId] ?? '-',
          type: type,
          expiryDate: expiryDate,
          daysLeft: left,
        ),
      );
    }

    for (final e in latestContractEndByEmployee.entries) {
      maybeAdd(
        employeeId: e.key,
        type: 'contract',
        expiryDate: e.value,
        alertDays: settings.contractAlertDays,
      );
    }

    for (final row in (personalRes as List)) {
      final m = row as Map<String, dynamic>;
      final employeeId = m['employee_id']?.toString();
      if (employeeId == null || employeeId.isEmpty) continue;

      final residencyExpiry = DateTime.tryParse(
        (m['residency_expiry_date'] ?? '').toString(),
      );
      if (residencyExpiry != null) {
        maybeAdd(
          employeeId: employeeId,
          type: 'residency',
          expiryDate: residencyExpiry,
          alertDays: settings.residencyAlertDays,
        );
      }

      final insuranceExpiry = DateTime.tryParse(
        (m['insurance_expiry_date'] ?? '').toString(),
      );
      if (insuranceExpiry != null) {
        maybeAdd(
          employeeId: employeeId,
          type: 'insurance',
          expiryDate: insuranceExpiry,
          alertDays: settings.insuranceAlertDays,
        );
      }
    }

    items.sort((a, b) {
      final d = a.daysLeft.compareTo(b.daysLeft);
      if (d != 0) return d;
      return a.employeeName.compareTo(b.employeeName);
    });
    return items;
  }

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
      'file_url':
          (fileUrl == null || fileUrl.trim().isEmpty) ? null : fileUrl.trim(),
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
        'note': (note == null || note.trim().isEmpty) ? null : note.trim(),
      });
    } catch (_) {
      // Keep current compensation update working even if history table is not deployed yet.
    }
  }
}
