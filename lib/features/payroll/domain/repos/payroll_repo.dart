import '../models/payroll_run.dart';
import '../models/payroll_item.dart';

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
}
