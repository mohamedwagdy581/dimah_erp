import 'package:erp_sys/features/payroll/domain/payroll_approval_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Missing finance employee link explains prerequisite in both languages',
    () {
      expect(
        payrollApprovalError(
          'PAYROLL_FINANCE_REVIEWER_NOT_LINKED',
          isArabic: true,
        ),
        contains('ملف موظف نشط'),
      );
      expect(
        payrollApprovalError(
          'PAYROLL_FINANCE_MANAGER_NOT_LINKED',
          isArabic: false,
        ),
        contains('Payroll was not approved'),
      );
    },
  );
  test(
    'Missing RPC explains the installation; uncertain outcome asks to refresh',
    () {
      expect(
        payrollApprovalError('PGRST202 admin_approve_payroll', isArabic: true),
        contains('install_admin_payroll_approval.sql'),
      );
      expect(
        payrollApprovalError('Connection closed', isArabic: false),
        contains('Refresh'),
      );
      expect(
        payrollApprovalError('Connection closed', isArabic: false),
        isNot(contains('was not approved')),
      );
    },
  );
}
