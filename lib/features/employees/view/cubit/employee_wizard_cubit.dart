import '../../domain/models/employee_login_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/request_id.dart';
import '../../domain/repos/employee_repo.dart';
import 'employee_wizard_state.dart';
import '../../../attendance/domain/repos/attendance_identity_repo.dart';

class EmployeeWizardCubit extends Cubit<EmployeeWizardState> {
  EmployeeWizardCubit(
    this._repo, {
    AttendanceIdentityRepo? attendanceIdentityRepo,
  }) : _attendanceIdentityRepo = attendanceIdentityRepo,
       super(const EmployeeWizardState());

  final EmployeesRepo _repo;
  final AttendanceIdentityRepo? _attendanceIdentityRepo;
  bool _attendanceSaved = false;
  final String _creationRequestId = newRequestId();
  bool get attendanceLinked => _attendanceSaved;
  void setAttendanceNumber(String value) {
    if (state.loading || _attendanceSaved) return;
    emit(state.copyWith(attendanceNumber: value));
  }

  String _initialPassword = '';
  void setLoginRole(String role) {
    if (['employee', 'manager'].contains(role) && !state.loading) {
      emit(state.copyWith(loginRole: role));
    }
  }

  void setInitialPassword(String value) {
    if (!state.loading) _initialPassword = value;
  }

  @override
  Future<void> close() {
    _initialPassword = '';
    return super.close();
  }

  void _emitPersonal(EmployeeWizardState Function() next) => emit(next());
  void _emitJob(EmployeeWizardState Function() next) => emit(next());
  void _emitCompensation(EmployeeWizardState Function() next) => emit(next());
  void _emitAdditional(EmployeeWizardState Function() next) => emit(next());

  void setEmployeeNumber(String v) => _emitPersonal(
    () => state.copyWith(personal: state.personal.copyWith(employeeNumber: v)),
  );
  void setFullName(String v) => _emitPersonal(
    () => state.copyWith(personal: state.personal.copyWith(fullName: v)),
  );
  void setEmail(String v) => _emitPersonal(
    () => state.copyWith(personal: state.personal.copyWith(email: v)),
  );
  void setPhone(String v) => _emitPersonal(
    () => state.copyWith(personal: state.personal.copyWith(phone: v)),
  );
  void setPhotoUrl(String v) => _emitPersonal(
    () => state.copyWith(personal: state.personal.copyWith(photoUrl: v)),
  );
  void setNationalId(String v) => _emitPersonal(
    () => state.copyWith(personal: state.personal.copyWith(nationalId: v)),
  );
  void setGender(String? v) => _emitPersonal(
    () => state.copyWith(personal: state.personal.copyWith(gender: v)),
  );
  void setDateOfBirth(DateTime? v) => _emitPersonal(
    () => state.copyWith(personal: state.personal.copyWith(dateOfBirth: v)),
  );
  void setNationality(String? v) => _emitPersonal(
    () => state.copyWith(personal: state.personal.copyWith(nationality: v)),
  );

  void setDepartmentId(String? v) =>
      _emitJob(() => state.copyWith(job: state.job.copyWith(departmentId: v)));
  void setManagerId(String? v) =>
      _emitJob(() => state.copyWith(job: state.job.copyWith(managerId: v)));
  void setJobTitleId(String? v) =>
      _emitJob(() => state.copyWith(job: state.job.copyWith(jobTitleId: v)));
  void setHireDate(DateTime? v) =>
      _emitJob(() => state.copyWith(job: state.job.copyWith(hireDate: v)));
  void setEmploymentType(String v) => _emitJob(
    () => state.copyWith(job: state.job.copyWith(employmentType: v)),
  );
  void setContractType(String v) =>
      _emitJob(() => state.copyWith(job: state.job.copyWith(contractType: v)));
  void setContractStart(DateTime? v) =>
      _emitJob(() => state.copyWith(job: state.job.copyWith(contractStart: v)));
  void setContractEnd(DateTime? v) =>
      _emitJob(() => state.copyWith(job: state.job.copyWith(contractEnd: v)));
  void setProbationMonths(int? v) => _emitJob(
    () => state.copyWith(job: state.job.copyWith(probationMonths: v)),
  );
  void setContractFileUrl(String v) => _emitJob(
    () => state.copyWith(job: state.job.copyWith(contractFileUrl: v)),
  );

  void setMaritalStatus(String? v) => _emitAdditional(
    () =>
        state.copyWith(additional: state.additional.copyWith(maritalStatus: v)),
  );
  void setAddress(String v) => _emitAdditional(
    () => state.copyWith(additional: state.additional.copyWith(address: v)),
  );
  void setCity(String v) => _emitAdditional(
    () => state.copyWith(additional: state.additional.copyWith(city: v)),
  );
  void setCountry(String v) => _emitAdditional(
    () => state.copyWith(additional: state.additional.copyWith(country: v)),
  );
  void setPassportNo(String v) => _emitAdditional(
    () => state.copyWith(additional: state.additional.copyWith(passportNo: v)),
  );
  void setPassportExpiry(DateTime? v) => _emitAdditional(
    () => state.copyWith(
      additional: state.additional.copyWith(passportExpiry: v),
    ),
  );
  void setEducationLevel(String? v) => _emitAdditional(
    () => state.copyWith(
      additional: state.additional.copyWith(educationLevel: v),
    ),
  );
  void setMajor(String v) => _emitAdditional(
    () => state.copyWith(additional: state.additional.copyWith(major: v)),
  );
  void setUniversity(String v) => _emitAdditional(
    () => state.copyWith(additional: state.additional.copyWith(university: v)),
  );

  void setBasicSalary(num? v) => _emitCompensation(
    () => state.copyWith(
      compensation: state.compensation.copyWith(basicSalary: v ?? 0),
    ),
  );
  void setHousingAllowance(num? v) => _emitCompensation(
    () => state.copyWith(
      compensation: state.compensation.copyWith(housingAllowance: v ?? 0),
    ),
  );
  void setTransportAllowance(num? v) => _emitCompensation(
    () => state.copyWith(
      compensation: state.compensation.copyWith(transportAllowance: v ?? 0),
    ),
  );
  void setOtherAllowance(num? v) => _emitCompensation(
    () => state.copyWith(
      compensation: state.compensation.copyWith(otherAllowance: v ?? 0),
    ),
  );
  void setBankName(String v) => _emitCompensation(
    () =>
        state.copyWith(compensation: state.compensation.copyWith(bankName: v)),
  );
  void setIban(String v) => _emitCompensation(
    () => state.copyWith(compensation: state.compensation.copyWith(iban: v)),
  );
  void setAccountNumber(String v) => _emitCompensation(
    () => state.copyWith(
      compensation: state.compensation.copyWith(accountNumber: v),
    ),
  );
  void setPaymentMethod(String v) => _emitCompensation(
    () => state.copyWith(
      compensation: state.compensation.copyWith(paymentMethod: v),
    ),
  );

  Future<void> submit() async {
    if (state.loading || state.success) return;
    if (!isValidEmployeeLoginPassword(_initialPassword)) {
      emit(
        state.copyWith(
          error:
              'كلمة المرور تحتاج 12 حرفًا على الأقل، وحروفًا كبيرة وصغيرة ورقمًا ورمزًا',
        ),
      );
      return;
    }
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
      // Check the deployed Auth service and atomic save before writing any rows.
      await _repo.checkEmployeeCreationReady();

      final attendanceNumber = normalizeAttendanceNumber(
        state.attendanceNumber,
      );
      if (!isValidAttendanceNumber(attendanceNumber)) {
        throw ArgumentError(
          'رقم الموظف في جهاز البصمة غير صالح / Invalid device employee number',
        );
      }
      if (attendanceNumber.isNotEmpty && !_attendanceSaved) {
        if (_attendanceIdentityRepo == null) {
          throw StateError('Attendance identity repository unavailable');
        }
        // Validate installation and conflicts before creating a new employee.
        await _attendanceIdentityRepo.check(
          attendanceNumber,
          employeeId: state.savedEmployeeId,
        );
      }

      final empNo =
          state.savedEmployeeId ??
          await _repo.createEmployee(
            requestId: _creationRequestId,
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
            nationality: state.nationality,
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
      emit(state.copyWith(savedEmployeeId: empNo));
      if (attendanceNumber.isNotEmpty && !_attendanceSaved) {
        await _attendanceIdentityRepo!.save(empNo, attendanceNumber);
        _attendanceSaved = true;
      }
      final login = await _repo.provisionEmployeeLogin(
        employeeId: empNo,
        role: state.loginRole,
        initialPassword: _initialPassword,
      );
      if (isClosed) return;
      _initialPassword = '';
      emit(
        state.copyWith(
          loading: false,
          success: true,
          loginResult: login,
          personal: state.personal.copyWith(employeeNumber: empNo),
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          error: state.savedEmployeeId == null
              ? AppError.message(e)
              : 'تم حفظ الموظف. تعذّر إكمال ربط البصمة أو حساب الدخول؛ أعد المحاولة لإكمال الخطوات بدون إنشاء موظف جديد. ${AppError.message(e)}',
        ),
      );
    }
  }
}
