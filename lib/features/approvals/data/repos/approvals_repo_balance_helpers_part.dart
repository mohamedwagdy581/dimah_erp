part of 'approvals_repo_impl.dart';

mixin _ApprovalsRepoBalanceHelpersMixin on _ApprovalsRepoSessionMixin {
  int _leaveDaysInclusive(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays + 1;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  Future<void> _logLeaveBalanceHistory({
    required String tenantId,
    required String employeeId,
    required int leaveYear,
    required String leaveType,
    required int days,
    required String actionType,
    required String requestId,
    String? leaveId,
    String? note,
  }) async {
    final actorUserId = _client.auth.currentUser?.id;
    try {
      await _client.from('employee_leave_balance_history').insert({
        'tenant_id': tenantId,
        'employee_id': employeeId,
        'leave_year': leaveYear,
        'leave_type': leaveType,
        'days': days,
        'action_type': actionType,
        'request_id': requestId,
        'leave_id': leaveId,
        'actor_user_id': actorUserId,
        'note': note,
      });
    } catch (_) {
      // Backward compatible if migration not applied yet.
    }
  }

  Future<void> _applyLeaveBalanceDelta({
    required String tenantId,
    required String employeeId,
    required String leaveType,
    required int leaveYear,
    required int daysDelta,
    required String requestId,
    String? leaveId,
    required String actionType,
  }) async {
    if (daysDelta == 0) return;
    if (leaveType != 'annual' && leaveType != 'sick' && leaveType != 'other') return;

    final row = await _client
        .from('employee_leave_balances')
        .select(
          'id, annual_entitlement, sick_entitlement, other_entitlement, '
          'annual_used, sick_used, other_used',
        )
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .eq('leave_year', leaveYear)
        .maybeSingle();

    if (row == null) {
      if (daysDelta < 0) {
        throw Exception('Cannot rollback leave balance: leave balance record is missing.');
      }
      await _client.from('employee_leave_balances').insert({
        'tenant_id': tenantId,
        'employee_id': employeeId,
        'leave_year': leaveYear,
        'annual_entitlement': 21,
        'sick_entitlement': 10,
        'other_entitlement': 5,
        'annual_used': leaveType == 'annual' ? daysDelta : 0,
        'sick_used': leaveType == 'sick' ? daysDelta : 0,
        'other_used': leaveType == 'other' ? daysDelta : 0,
      });
      return _logLeaveBalanceHistory(
        tenantId: tenantId,
        employeeId: employeeId,
        leaveYear: leaveYear,
        leaveType: leaveType,
        days: daysDelta,
        actionType: actionType,
        requestId: requestId,
        leaveId: leaveId,
      );
    }

    final usedField = leaveType == 'annual'
        ? 'annual_used'
        : leaveType == 'sick'
            ? 'sick_used'
            : 'other_used';
    final entitlementField = leaveType == 'annual'
        ? 'annual_entitlement'
        : leaveType == 'sick'
            ? 'sick_entitlement'
            : 'other_entitlement';
    final next = _toDouble(row[usedField]) + daysDelta;

    if (next < 0) throw Exception('Cannot rollback $leaveType leave: used balance is too low.');
    if (daysDelta > 0 && next > _toDouble(row[entitlementField])) {
      throw Exception('Insufficient $leaveType leave balance for approval.');
    }

    await _client
        .from('employee_leave_balances')
        .update({usedField: next})
        .eq('tenant_id', tenantId)
        .eq('id', row['id'].toString());

    await _logLeaveBalanceHistory(
      tenantId: tenantId,
      employeeId: employeeId,
      leaveYear: leaveYear,
      leaveType: leaveType,
      days: daysDelta,
      actionType: actionType,
      requestId: requestId,
      leaveId: leaveId,
    );
  }
}
