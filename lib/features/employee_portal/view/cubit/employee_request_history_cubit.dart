import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_error.dart';
import '../../../approvals/domain/models/approval_request.dart';
import '../../../approvals/domain/repos/approvals_repo.dart';

class EmployeeRequestHistoryState {
  const EmployeeRequestHistoryState({
    this.items = const [],
    this.loading = false,
    this.error,
  });
  final List<ApprovalRequest> items;
  final bool loading;
  final String? error;
}

class EmployeeRequestHistoryCubit extends Cubit<EmployeeRequestHistoryState> {
  EmployeeRequestHistoryCubit(this.repo, {required this.employeeId})
    : super(const EmployeeRequestHistoryState());
  final ApprovalsRepo repo;
  final String employeeId;
  Future<void> load() async {
    if (isClosed || state.loading) return;
    emit(EmployeeRequestHistoryState(items: state.items, loading: true));
    try {
      final items = <ApprovalRequest>[];
      const pageSize = 100;
      for (var page = 0; ; page++) {
        final result = await repo.fetchApprovals(
          page: page,
          pageSize: pageSize,
          employeeId: employeeId,
          sortBy: 'created_at',
          ascending: false,
        );
        if (isClosed) return;
        items.addAll(result.items);
        // Existing repo total is only the page length, so do not use it to truncate history.
        if (result.items.length < pageSize) break;
      }
      final unique = {for (final item in items) item.id: item};
      emit(EmployeeRequestHistoryState(items: unique.values.toList()));
    } catch (error) {
      if (!isClosed) {
        emit(
          EmployeeRequestHistoryState(
            items: state.items,
            error: AppError.message(error),
          ),
        );
      }
    }
  }
}
