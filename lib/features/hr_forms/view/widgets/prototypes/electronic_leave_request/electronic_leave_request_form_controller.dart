import 'package:flutter/material.dart';

import '../../../../../../core/di/app_di.dart';
import '../../../../../employees/domain/models/employee_lookup.dart';
import '../../../../../employees/domain/models/employee_profile_details.dart';

class ElectronicLeaveRequestFormController extends ChangeNotifier {
  final employeeName = TextEditingController();
  final employeeId = TextEditingController();
  final position = TextEditingController();
  final applicationDate = TextEditingController();
  final leaveType = TextEditingController();
  final fromDate = TextEditingController();
  final toDate = TextEditingController();
  final days = TextEditingController();
  final addressDuringLeave = TextEditingController();
  final applicantSignature = TextEditingController();
  final replacement = TextEditingController();
  final contactDuringLeave = TextEditingController();
  final replacementSignature = TextEditingController();
  final lineManagerSignature = TextEditingController();
  final notes = TextEditingController();
  final joiningDate = TextEditingController();
  final previousBalance = TextEditingController(text: '0');
  final newBalance = TextEditingController(text: '0');
  final hrDepartment = TextEditingController();
  final hrManagerSignature = TextEditingController();
  final departmentManagerSignature = TextEditingController();

  List<EmployeeLookup> employeeOptions = const [];
  String? selectedEmployeeId;
  bool loadingEmployees = true;
  bool fillingEmployee = false;
  bool _disposed = false;

  List<TextEditingController> get _allControllers => [
    employeeName,
    employeeId,
    position,
    applicationDate,
    leaveType,
    fromDate,
    toDate,
    days,
    addressDuringLeave,
    applicantSignature,
    replacement,
    contactDuringLeave,
    replacementSignature,
    lineManagerSignature,
    notes,
    joiningDate,
    previousBalance,
    newBalance,
    hrDepartment,
    hrManagerSignature,
    departmentManagerSignature,
  ];

  void initialize() {
    applicationDate.text = formatDate(DateTime.now());
    _loadEmployees();
  }

  void clear() {
    for (final controller in _allControllers) {
      controller.clear();
    }
    applicationDate.text = formatDate(DateTime.now());
    previousBalance.text = '0';
    newBalance.text = '0';
    selectedEmployeeId = null;
    _notifySafely();
  }

  void clearFilledEmployee() {
    selectedEmployeeId = null;
    _notifySafely();
  }

  Future<bool> fillFromEmployee(String employeeId) async {
    selectedEmployeeId = employeeId;
    fillingEmployee = true;
    _notifySafely();
    try {
      final profile = await AppDI.employeesRepo.fetchEmployeeProfile(
        employeeId: employeeId,
      );
      _applyEmployeeProfile(profile);
      fillingEmployee = false;
      _notifySafely();
      return true;
    } catch (_) {
      fillingEmployee = false;
      _notifySafely();
      return false;
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _disposed = true;
    for (final controller in _allControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      employeeOptions = await AppDI.employeesRepo.fetchEmployeeLookup(
        limit: 200,
      );
    } catch (_) {
      employeeOptions = const [];
    } finally {
      loadingEmployees = false;
      _notifySafely();
    }
  }

  void _applyEmployeeProfile(EmployeeProfileDetails profile) {
    employeeName.text = profile.fullName;
    employeeId.text = profile.nationalId ?? '';
    position.text = profile.jobTitleName ?? '';
    applicationDate.text = formatDate(DateTime.now());
    joiningDate.text = formatDate(profile.hireDate);
    hrDepartment.text = profile.departmentName ?? '';
  }

  void _notifySafely() {
    if (_disposed) return;
    notifyListeners();
  }
}
