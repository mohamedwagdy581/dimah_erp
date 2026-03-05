import '../models/employee.dart';
import '../models/expiry_alert.dart';
import '../models/employee_profile_details.dart';
import '../models/employee_lookup.dart';

abstract class EmployeesRepo {
  Future<({List<Employee> items, int total})> fetchEmployees({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    String? actorRole,
    String? actorEmployeeId,
    String sortBy,
    bool ascending,
  });

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
    String? educationLevel,
    String? major,
    String? university,
    DateTime? residencyIssueDate,
    DateTime? residencyExpiryDate,
    DateTime? insuranceStartDate,
    DateTime? insuranceExpiryDate,
    String? insuranceProvider,
    String? insurancePolicyNo,

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
  });

  Future<List<EmployeeLookup>> fetchEmployeeLookup({
    String? search,
    int limit,
  });

  Future<EmployeeProfileDetails> fetchEmployeeProfile({
    required String employeeId,
  });

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
    String? educationLevel,
    String? major,
    String? university,
    DateTime? residencyIssueDate,
    DateTime? residencyExpiryDate,
    DateTime? insuranceStartDate,
    DateTime? insuranceExpiryDate,
    String? insuranceProvider,
    String? insurancePolicyNo,
    String? bankName,
    String? iban,
    String? accountNumber,
    String? paymentMethod,
    String? contractType,
    DateTime? contractStart,
    DateTime? contractEnd,
    int? probationMonths,
    String? contractFileUrl,
  });

  Future<void> addEmployeeContractVersion({
    required String employeeId,
    required String contractType,
    required DateTime startDate,
    DateTime? endDate,
    int? probationMonths,
    String? fileUrl,
  });

  Future<void> addEmployeeCompensationVersion({
    required String employeeId,
    required double basicSalary,
    required double housingAllowance,
    required double transportAllowance,
    required double otherAllowance,
    DateTime? effectiveAt,
    String? note,
  });

  Future<ExpiryAlertSettings> fetchExpiryAlertSettings();

  Future<void> upsertExpiryAlertSettings(ExpiryAlertSettings settings);

  Future<List<ExpiryAlertItem>> fetchExpiryAlerts();
}
