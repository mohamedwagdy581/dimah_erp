import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/features/employees/data/repos/employee_repo_impl.dart';
import 'employee_attendance_repo_test.dart' show server;

void main() {
  test(
    'Complete employee save sends bank, personal, job and date fields in one RPC',
    () async {
      final client = await server((request) async {
        if (request.uri.path == '/rest/v1/departments') {
          return {'manager_id': null};
        }
        expect(request.uri.path, '/rest/v1/rpc/hr_create_employee_complete');
        final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
        expect(body['p_request_id'], '10000000-0000-4000-8000-000000000001');
        expect(body['p_nationality'], 'Egyptian');
        expect(body['p_iban'], 'SA1234567890123456789012');
        expect(body['p_passport_no'], 'A123456');
        expect(body['p_passport_expiry'], '2030-01-02');
        expect(body['p_job_title_id'], 'job');
        expect(body['p_date_of_birth'], '1990-01-02');
        expect(body['p_contract_end'], '2027-10-03');
        expect(body['p_bank_name'], 'Bank');
        expect(body['p_account_number'], '12345');
        expect(body['p_housing_allowance'], 1500);
        return 'created';
      }, role: 'hr');
      final id = await EmployeesRepoImpl(client).createEmployee(
        requestId: '10000000-0000-4000-8000-000000000001',
        fullName: 'Employee',
        email: 'new@example.test',
        phone: '0500000000',
        nationalId: '1234567890',
        nationality: 'Egyptian',
        departmentId: 'dept',
        jobTitleId: 'job',
        hireDate: DateTime(2026, 10, 4),
        dateOfBirth: DateTime(1990, 1, 2),
        passportNo: 'A123456',
        passportExpiry: DateTime(2030, 1, 2),
        employmentType: 'full_time',
        contractType: 'full_time',
        contractStart: DateTime(2026, 10, 4),
        contractEnd: DateTime(2027, 10, 3),
        basicSalary: 6000,
        housingAllowance: 1500,
        transportAllowance: 500,
        otherAllowance: 100,
        bankName: 'Bank',
        iban: 'SA1234567890123456789012',
        accountNumber: '12345',
      );
      expect(id, 'created');
    },
  );
  test(
    'Missing atomic RPC never falls back to partial employee inserts',
    () async {
      var writes = 0;
      final client = await server((request) async {
        if (request.uri.path == '/rest/v1/departments') {
          return {'manager_id': null};
        }
        writes++;
        expect(request.uri.path, '/rest/v1/rpc/hr_create_employee_complete');
        request.response.statusCode = 404;
        return {
          'code': 'PGRST202',
          'message': 'Function not found',
          'details': null,
          'hint': null,
        };
      }, role: 'hr');
      await expectLater(
        EmployeesRepoImpl(client).createEmployee(
          fullName: 'Employee',
          email: 'new@example.test',
          phone: '0500000000',
          nationalId: '1234567890',
          departmentId: 'dept',
          jobTitleId: 'job',
          hireDate: DateTime(2026, 10, 4),
          employmentType: 'full_time',
          contractType: 'full_time',
          contractStart: DateTime(2026, 10, 4),
          basicSalary: 6000,
          housingAllowance: 0,
          transportAllowance: 0,
          otherAllowance: 0,
        ),
        throwsStateError,
      );
      expect(writes, 1);
    },
  );
  test(
    'Readiness checks deployed Edge Function before creating a record',
    () async {
      final client = await server((request) async {
        expect(request.uri.path, '/functions/v1/provision-employee-login');
        expect(jsonDecode(await utf8.decoder.bind(request).join()), {
          'action': 'check',
        });
        return {'ready': true, 'version': 2};
      }, role: 'hr');
      await EmployeesRepoImpl(client).checkEmployeeCreationReady();
    },
  );
  test(
    'Employee profile reads the saved IBAN, nationality, profession and passport dates',
    () async {
      final client = await server((request) async {
        expect(request.uri.queryParameters['tenant_id'], 'eq.tenant');
        switch (request.uri.path) {
          case '/rest/v1/employees':
            return {
              'id': 'employee',
              'full_name': 'Employee',
              'email': 'new@example.test',
              'phone': '0500000000',
              'nationality': 'Egyptian',
              'date_of_birth': '1990-01-02',
              'hire_date': '2026-10-04',
              'job_title': {'name': 'Accountant'},
            };
          case '/rest/v1/employee_personal':
            return {
              'nationality': 'Egyptian',
              'passport_no': 'A123456',
              'passport_expiry': '2030-01-02',
            };
          case '/rest/v1/employee_financial':
            return {
              'iban': 'SA1234567890123456789012',
              'bank_name': 'Bank',
              'account_number': '12345',
            };
          case '/rest/v1/employee_compensation':
            return {'basic_salary': 6000, 'housing_allowance': 1500};
          case '/rest/v1/employee_contracts':
            return [
              {
                'id': 'contract',
                'start_date': '2026-10-04',
                'end_date': '2027-10-03',
                'contract_type': 'full_time',
              },
            ];
          default:
            return [];
        }
      }, role: 'hr');
      final profile = await EmployeesRepoImpl(
        client,
      ).fetchEmployeeProfile(employeeId: 'employee');
      expect(profile.iban, 'SA1234567890123456789012');
      expect(profile.nationality, 'Egyptian');
      expect(profile.jobTitleName, 'Accountant');
      expect(profile.passportNo, 'A123456');
      expect(profile.passportExpiry, DateTime(2030, 1, 2));
      expect(profile.contractEnd, DateTime(2027, 10, 3));
      expect(profile.dateOfBirth, DateTime(1990, 1, 2));
    },
  );
}
