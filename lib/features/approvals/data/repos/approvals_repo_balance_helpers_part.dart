part of 'approvals_repo_impl.dart';

mixin _ApprovalsRepoBalanceHelpersMixin on _ApprovalsRepoSessionMixin {
  static const double _defaultAnnualEntitlement = 21;
  static const double _defaultSickEntitlement = 10;
  static const double _defaultOtherEntitlement = 5;

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
    if (leaveType != 'annual' && leaveType != 'sick' && leaveType != 'other') {
      return;
    }

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
      final hireDate = await _fetchEmployeeHireDate(
        tenantId: tenantId,
        employeeId: employeeId,
      );
      final annualEntitlement = _policyAnnualEntitlementForYear(
        hireDate: hireDate,
        targetYear: leaveYear,
        now: DateTime.now(),
      );

      if (daysDelta < 0) {
        throw Exception(
          'Cannot rollback leave balance: leave balance record is missing.',
        );
      }
      await _client.from('employee_leave_balances').insert({
        'tenant_id': tenantId,
        'employee_id': employeeId,
        'leave_year': leaveYear,
        'annual_entitlement': annualEntitlement,
        'sick_entitlement': _defaultSickEntitlement,
        'other_entitlement': _defaultOtherEntitlement,
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

    if (next < 0) {
      throw Exception('Cannot rollback $leaveType leave: used balance is too low.');
    }
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

  Future<DateTime?> _fetchEmployeeHireDate({
    required String tenantId,
    required String employeeId,
  }) async {
    final row = await _client
        .from('employees')
        .select('hire_date')
        .eq('tenant_id', tenantId)
        .eq('id', employeeId)
        .maybeSingle();

    final raw = row?['hire_date']?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  double _policyAnnualEntitlementForYear({
    required DateTime? hireDate,
    required int targetYear,
    required DateTime now,
  }) {
    final eligibilityDate = _annualLeaveEligibilityDate(hireDate);
    if (eligibilityDate == null) return 0;
    if (targetYear > now.year) return 0;

    final referenceDate = targetYear < now.year
        ? DateTime(targetYear, 12, 31)
        : DateTime(now.year, now.month, now.day);

    return referenceDate.isBefore(eligibilityDate)
        ? 0
        : _defaultAnnualEntitlement;
  }

  DateTime? _annualLeaveEligibilityDate(DateTime? hireDate) {
    if (hireDate == null) return null;
    return _addMonthsClamped(
      DateTime(hireDate.year, hireDate.month, hireDate.day),
      11,
    );
  }

  DateTime _addMonthsClamped(DateTime value, int monthsToAdd) {
    final monthIndex = value.month - 1 + monthsToAdd;
    final targetYear = value.year + (monthIndex ~/ 12);
    final targetMonth = (monthIndex % 12) + 1;
    final maxDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = value.day <= maxDay ? value.day : maxDay;
    return DateTime(targetYear, targetMonth, targetDay);
  }
}
