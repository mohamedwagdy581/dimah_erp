import '../models/payroll_run.dart';
import '../models/payroll_item.dart';
import '../models/payroll_assignee_option.dart';

abstract class PayrollRepo {
  Future<({List<PayrollRun> items, int total})> fetchRuns({
    required int page,
    required int pageSize,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String sortBy,
    bool ascending,
  });

  Future<String> createRun({
    required DateTime periodStart,
    required DateTime periodEnd,
  });

  Future<List<PayrollItem>> fetchRunItems({
    required String runId,
  });

  Future<void> finalizeRun({required String runId});

  // --- New Multi-Stage Workflow ---
  
  /// HR submits to Finance Manager
  Future<void> submitToFinanceManager({required String runId});
  
  /// Finance Manager approves and sends to Admin
  Future<void> financeManagerApprove({required String runId});
  
  /// Admin gives final approval and creates task for Finance Manager
  Future<void> adminApprove({required String runId});
  
  /// Rejection logic with reason
  Future<void> rejectRun({
    required String runId, 
    required String reason,
    required String rejectedByRole,
  });

  Future<List<PayrollAssigneeOption>> fetchAssignableAccountants();

  Future<void> assignDisbursementToAccountant({
    required String runId,
    required String accountantEmployeeId,
  });

  Future<void> markPaymentInProgress({required String runId});

  Future<void> markPaid({required String runId});
}
