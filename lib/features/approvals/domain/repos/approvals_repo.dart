import '../models/approval_request.dart';

abstract class ApprovalsRepo {
  Future<({List<ApprovalRequest> items, int total})> fetchApprovals({
    required int page,
    required int pageSize,
    String? status,
    String? requestType,
    String? employeeId,
    String sortBy,
    bool ascending,
  });

  Future<int> fetchPendingCount({String? employeeId});
  Future<int> fetchProcessedCount({required String employeeId});

  Future<void> approve(String requestId);
  Future<void> reject(String requestId, {String? reason});
}
