part of 'leaves_repo_impl.dart';

mixin _LeavesRepoBalancesMixin on _LeavesRepoSessionMixin {
  @override
  Future<List<LeaveBalance>> fetchLeaveBalances({
    required String employeeId,
    int? year,
  }) async {
    final tenantId = await _tenantId();
    final targetYear = year ?? DateTime.now().year;

    final row = await _client
        .from('employee_leave_balances')
        .select(
          'annual_entitlement, sick_entitlement, other_entitlement, '
          'annual_used, sick_used, other_used',
        )
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .eq('leave_year', targetYear)
        .maybeSingle();

    if (row == null) {
      return const [
        LeaveBalance(type: 'annual', entitlement: 0, used: 0),
        LeaveBalance(type: 'sick', entitlement: 0, used: 0),
        LeaveBalance(type: 'other', entitlement: 0, used: 0),
      ];
    }

    double toNum(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '0') ?? 0;
    }

    return [
      LeaveBalance(
        type: 'annual',
        entitlement: toNum(row['annual_entitlement']),
        used: toNum(row['annual_used']),
      ),
      LeaveBalance(
        type: 'sick',
        entitlement: toNum(row['sick_entitlement']),
        used: toNum(row['sick_used']),
      ),
      LeaveBalance(
        type: 'other',
        entitlement: toNum(row['other_entitlement']),
        used: toNum(row['other_used']),
      ),
    ];
  }
}
