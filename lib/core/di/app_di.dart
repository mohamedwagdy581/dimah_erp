import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/domain/repos/auth_repo.dart';
import '../../features/auth/data/repos/auth_repo_impl.dart';
import '../../features/departments/data/repos/departments_repo_impl.dart';
import '../../features/departments/domain/repos/departments_repo.dart';
import '../../features/employees/data/repos/employee_repo_impl.dart';
import '../../features/employees/domain/repos/employee_repo.dart';
import '../session/session_repo.dart';
import '../session/session_repo_impl.dart';
import '../../features/profile/domain/repos/profile_repo.dart';
import '../../features/profile/data/repos/profile_repo_impl.dart';
import '../../features/job_titles/domain/repos/job_titles_repo.dart';
import '../../features/job_titles/data/repos/job_titles_repo_impl.dart';
import '../../features/attendance/domain/repos/attendance_repo.dart';
import '../../features/attendance/data/repos/attendance_repo_impl.dart';
import '../../features/leaves/domain/repos/leaves_repo.dart';
import '../../features/leaves/data/repos/leaves_repo_impl.dart';
import '../../features/payroll/domain/repos/payroll_repo.dart';
import '../../features/payroll/data/repos/payroll_repo_impl.dart';
import '../../features/employee_docs/domain/repos/employee_docs_repo.dart';
import '../../features/employee_docs/data/repos/employee_docs_repo_impl.dart';
import '../../features/approvals/domain/repos/approvals_repo.dart';
import '../../features/approvals/data/repos/approvals_repo_impl.dart';
import '../../features/accounting/accounts/domain/repos/accounts_repo.dart';
import '../../features/accounting/accounts/data/repos/accounts_repo_impl.dart';
import '../../features/accounting/journal/domain/repos/journal_repo.dart';
import '../../features/accounting/journal/data/repos/journal_repo_impl.dart';

class AppDI {
  static late final SupabaseClient supabase;
  static late final AuthRepo authRepo;
  static late final SessionRepo sessionRepo;
  static late final ProfileRepo profileRepo;
  static late final DepartmentsRepo departmentsRepo;
  static late final JobTitlesRepo jobTitlesRepo;
  static late final EmployeesRepo employeesRepo;
  static late final AttendanceRepo attendanceRepo;
  static late final LeavesRepo leavesRepo;
  static late final PayrollRepo payrollRepo;
  static late final EmployeeDocsRepo employeeDocsRepo;
  static late final ApprovalsRepo approvalsRepo;
  static late final AccountsRepo accountsRepo;
  static late final JournalRepo journalRepo;

  static void init() {
    supabase = Supabase.instance.client;

    authRepo = AuthRepoImpl(supabase);
    sessionRepo = SessionRepoImpl(supabase);
    profileRepo = ProfileRepoImpl(supabase);
    departmentsRepo = DepartmentsRepoImpl(supabase);
    jobTitlesRepo = JobTitlesRepoImpl(supabase);
    employeesRepo = EmployeesRepoImpl(supabase);
    attendanceRepo = AttendanceRepoImpl(supabase);
    leavesRepo = LeavesRepoImpl(supabase);
    payrollRepo = PayrollRepoImpl(supabase);
    employeeDocsRepo = EmployeeDocsRepoImpl(supabase);
    approvalsRepo = ApprovalsRepoImpl(supabase);
    accountsRepo = AccountsRepoImpl(supabase);
    journalRepo = JournalRepoImpl(supabase);
  }
}
