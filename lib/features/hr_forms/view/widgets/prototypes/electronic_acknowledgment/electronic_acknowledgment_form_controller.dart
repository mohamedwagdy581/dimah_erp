import 'package:flutter/material.dart';

import '../../../../../../core/di/app_di.dart';
import '../../../../../employees/domain/models/employee_lookup.dart';
import '../../../../../employees/domain/models/employee_profile_details.dart';

class ElectronicAcknowledgmentFormController extends ChangeNotifier {
  final employeeName = TextEditingController();
  final employeeId = TextEditingController();
  final mobile = TextEditingController();
  final role = TextEditingController();
  final department = TextEditingController();
  final signature = TextEditingController();

  List<EmployeeLookup> employeeOptions = const [];
  String? selectedEmployeeId;
  bool loadingEmployees = true;
  bool fillingEmployee = false;
  bool _disposed = false;

  List<TextEditingController> get _allControllers => [
    employeeName,
    employeeId,
    mobile,
    role,
    department,
    signature,
  ];

  void initialize() {
    _loadEmployees();
  }

  void clear() {
    for (final controller in _allControllers) {
      controller.clear();
    }
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
      employeeOptions = await AppDI.employeesRepo.fetchEmployeeLookup(limit: 200);
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
    mobile.text = profile.phone;
    role.text = profile.jobTitleName ?? '';
    department.text = profile.departmentName ?? '';
  }

  void _notifySafely() {
    if (_disposed) return;
    notifyListeners();
  }
}
