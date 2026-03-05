import '../models/leave_request.dart';
import '../models/leave_balance.dart';

abstract class LeavesRepo {
  Future<({List<LeaveRequest> items, int total})> fetchLeaves({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String sortBy,
    bool ascending,
  });

  Future<void> createLeave({
    required String employeeId,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String? fileUrl,
    String? notes,
  });

  Future<void> resubmitLeave({
    required String leaveId,
    required String employeeId,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String? fileUrl,
    String? notes,
  });

  Future<List<LeaveBalance>> fetchLeaveBalances({
    required String employeeId,
    int? year,
  });
}
