import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_error.dart';
import '../../domain/repos/employee_repo.dart';
import 'employee_wizard_state.dart';

class EmployeeWizardCubit extends Cubit<EmployeeWizardState> {
  EmployeeWizardCubit(this._repo) : super(const EmployeeWizardState());

  final EmployeesRepo _repo;

  // =======================
  // Personal setters
  // =======================

  void setEmployeeNumber(String v) => emit(state.copyWith(employeeNumber: v));

  void setFullName(String v) => emit(state.copyWith(fullName: v));

  void setEmail(String v) => emit(state.copyWith(email: v));

  void setPhone(String v) => emit(state.copyWith(phone: v));
  void setPhotoUrl(String v) => emit(state.copyWith(photoUrl: v));

  void setNationalId(String v) => emit(state.copyWith(nationalId: v));

  void setGender(String? v) => emit(state.copyWith(gender: v));

  void setDateOfBirth(DateTime? v) => emit(state.copyWith(dateOfBirth: v));
  void setNationality(String? v) => emit(state.copyWith(nationality: v));

  // =======================
  // Job setters
  // =======================

  void setDepartmentId(String? v) => emit(state.copyWith(departmentId: v));
  void setManagerId(String? v) => emit(state.copyWith(managerId: v));

  void setJobTitleId(String? v) => emit(state.copyWith(jobTitleId: v));

  void setHireDate(DateTime? v) => emit(state.copyWith(hireDate: v));

  void setEmploymentType(String v) => emit(state.copyWith(employmentType: v));
  void setContractType(String v) => emit(state.copyWith(contractType: v));
  void setContractStart(DateTime? v) => emit(state.copyWith(contractStart: v));
  void setContractEnd(DateTime? v) => emit(state.copyWith(contractEnd: v));
  void setProbationMonths(int? v) => emit(state.copyWith(probationMonths: v));
  void setContractFileUrl(String v) => emit(state.copyWith(contractFileUrl: v));

  void setMaritalStatus(String? v) => emit(state.copyWith(maritalStatus: v));
  void setAddress(String v) => emit(state.copyWith(address: v));
  void setCity(String v) => emit(state.copyWith(city: v));
  void setCountry(String v) => emit(state.copyWith(country: v));
  void setPassportNo(String v) => emit(state.copyWith(passportNo: v));
  void setPassportExpiry(DateTime? v) =>
      emit(state.copyWith(passportExpiry: v));
  void setEducationLevel(String? v) =>
      emit(state.copyWith(educationLevel: v));
  void setMajor(String v) => emit(state.copyWith(major: v));
  void setUniversity(String v) => emit(state.copyWith(university: v));

  // =======================
  // Compensation setters
  // =======================

  void setBasicSalary(num? v) => emit(state.copyWith(basicSalary: v ?? 0));

  void setHousingAllowance(num? v) =>
      emit(state.copyWith(housingAllowance: v ?? 0));

  void setTransportAllowance(num? v) =>
      emit(state.copyWith(transportAllowance: v ?? 0));

  void setOtherAllowance(num? v) =>
      emit(state.copyWith(otherAllowance: v ?? 0));
  void setBankName(String v) => emit(state.copyWith(bankName: v));
  void setIban(String v) => emit(state.copyWith(iban: v));
  void setAccountNumber(String v) => emit(state.copyWith(accountNumber: v));
  void setPaymentMethod(String v) => emit(state.copyWith(paymentMethod: v));

  // =======================
  // Submit Employee
  // =======================

  Future<void> submit() async {
    try {
      if (state.fullName.trim().isEmpty) {
        emit(state.copyWith(error: 'Full name is required'));
        return;
      }

      if (state.email.trim().isEmpty) {
        emit(state.copyWith(error: 'Email is required'));

        return;
      }

      if (state.phone.trim().isEmpty) {
        emit(state.copyWith(error: 'Phone number is required'));
        return;
      }

      if (state.departmentId == null) {
        emit(state.copyWith(error: 'Department is required'));
        return;
      }

      if (state.jobTitleId == null) {
        emit(state.copyWith(error: 'Job title is required'));
        return;
      }

      if (state.hireDate == null) {
        emit(state.copyWith(error: 'Hire date is required'));
        return;
      }

      emit(state.copyWith(loading: true, error: null));

      final empNo = await _repo.createEmployee(
        fullName: state.fullName,
        email: state.email,
        phone: state.phone,
        photoUrl: state.photoUrl,
        departmentId: state.departmentId!,
        managerId: state.managerId,
        jobTitleId: state.jobTitleId!,
        hireDate: state.hireDate!,
        employmentType: state.employmentType,
        contractType: state.contractType,
        contractStart: state.contractStart ?? state.hireDate!,
        contractEnd: state.contractEnd,
        probationMonths: state.probationMonths,
        contractFileUrl: state.contractFileUrl,
        basicSalary: state.basicSalary.toDouble(),
        housingAllowance: state.housingAllowance.toDouble(),
        transportAllowance: state.transportAllowance.toDouble(),
        otherAllowance: state.otherAllowance.toDouble(),
        nationalId: state.nationalId,
        dateOfBirth: state.dateOfBirth,
        gender: state.gender,
        maritalStatus: state.maritalStatus,
        address: state.address,
        city: state.city,
        country: state.country,
        passportNo: state.passportNo,
        passportExpiry: state.passportExpiry,
        educationLevel: state.educationLevel,
        major: state.major,
        university: state.university,
        bankName: state.bankName,
        iban: state.iban,
        accountNumber: state.accountNumber,
        paymentMethod: state.paymentMethod,
      );
      if (isClosed) return;
      emit(
        state.copyWith(loading: false, success: true, employeeNumber: empNo),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: AppError.message(e)));
    }
  }
}
