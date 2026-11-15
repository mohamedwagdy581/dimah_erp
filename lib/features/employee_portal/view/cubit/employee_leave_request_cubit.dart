import 'package:file_selector/file_selector.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_error.dart';
import '../../../leaves/domain/models/leave_balance.dart';
import '../../../leaves/domain/repos/leaves_repo.dart';

typedef LeaveAttachmentUploader =
    Future<String> Function(XFile file, String employeeId);

class EmployeeLeaveRequestState {
  const EmployeeLeaveRequestState({
    this.balances = const [],
    this.loading = false,
    this.saving = false,
    this.submitted = false,
    this.balanceError,
    this.submitError,
  });
  final List<LeaveBalance> balances;
  final bool loading;
  final bool saving;
  final bool submitted;
  final String? balanceError;
  final String? submitError;
}

class EmployeeLeaveRequestCubit extends Cubit<EmployeeLeaveRequestState> {
  EmployeeLeaveRequestCubit(
    this.repo, {
    required this.employeeId,
    required this.uploadAttachment,
  }) : super(const EmployeeLeaveRequestState());
  final LeavesRepo repo;
  final String employeeId;
  final LeaveAttachmentUploader uploadAttachment;
  XFile? _uploadedFile;
  String? _uploadedUrl;
  int _balanceLoad = 0;
  int balanceYear = DateTime.now().year;

  Future<void> loadBalance({int? year}) async {
    if (isClosed) return;
    balanceYear = year ?? DateTime.now().year;
    final request = ++_balanceLoad;
    emit(
      EmployeeLeaveRequestState(
        balances: state.balances,
        loading: true,
        saving: state.saving,
        submitted: state.submitted,
        submitError: state.submitError,
      ),
    );
    try {
      final balances = await repo.fetchLeaveBalances(
        employeeId: employeeId,
        year: balanceYear,
      );
      if (isClosed || request != _balanceLoad) return;
      emit(
        EmployeeLeaveRequestState(
          balances: balances,
          saving: state.saving,
          submitted: state.submitted,
          submitError: state.submitError,
        ),
      );
    } catch (error) {
      if (isClosed || request != _balanceLoad) return;
      emit(
        EmployeeLeaveRequestState(
          saving: state.saving,
          submitted: state.submitted,
          submitError: state.submitError,
          balanceError: AppError.message(error),
        ),
      );
    }
  }

  Future<void> submit({
    required String type,
    required DateTime start,
    required DateTime end,
    required String notes,
    XFile? attachment,
  }) async {
    if (state.saving || state.submitted) return;
    emit(
      EmployeeLeaveRequestState(
        balances: state.balances,
        loading: state.loading,
        saving: true,
        balanceError: state.balanceError,
      ),
    );
    try {
      if (end.isBefore(start)) {
        throw ArgumentError('End date must follow start date');
      }
      String? fileUrl;
      if (attachment != null) {
        if (identical(attachment, _uploadedFile)) {
          fileUrl = _uploadedUrl;
        } else {
          fileUrl = await uploadAttachment(attachment, employeeId);
          _uploadedFile = attachment;
          _uploadedUrl = fileUrl;
        }
      }
      await repo.createLeave(
        employeeId: employeeId,
        type: type,
        startDate: start,
        endDate: end,
        notes: notes.trim(),
        fileUrl: fileUrl,
      );
      if (isClosed) return;
      emit(
        EmployeeLeaveRequestState(
          balances: state.balances,
          loading: state.loading,
          balanceError: state.balanceError,
          submitted: true,
        ),
      );
      // A balance refresh failure must never turn a saved request into a retry.
      await loadBalance(year: start.year);
    } catch (error) {
      if (isClosed) return;
      emit(
        EmployeeLeaveRequestState(
          balances: state.balances,
          loading: state.loading,
          balanceError: state.balanceError,
          submitError: AppError.message(error),
        ),
      );
    }
  }

  void newRequest() {
    if (state.saving) return;
    _uploadedFile = null;
    _uploadedUrl = null;
    emit(
      EmployeeLeaveRequestState(
        balances: state.balances,
        loading: state.loading,
        balanceError: state.balanceError,
      ),
    );
  }
}
