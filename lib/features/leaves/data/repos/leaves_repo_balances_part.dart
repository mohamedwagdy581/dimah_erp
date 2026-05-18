part of 'leaves_repo_impl.dart';

mixin _LeavesRepoBalancesMixin on _LeavesRepoSessionMixin {
  static const double _defaultAnnualEntitlement = 21;
  static const double _defaultSickEntitlement = 10;
  static const double _defaultOtherEntitlement = 5;

  Future<List<LeaveBalance>> fetchLeaveBalances({
    required String employeeId,
    int? year,
  }) async {
    final tenantId = await _tenantId();
    final targetYear = year ?? DateTime.now().year;
    final hireDate = await _fetchEmployeeHireDate(
      tenantId: tenantId,
      employeeId: employeeId,
    );
    final policyAnnualEntitlement = _policyAnnualEntitlementForYear(
      hireDate: hireDate,
      targetYear: targetYear,
      now: DateTime.now(),
    );

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
      return [
        LeaveBalance(
          type: 'annual',
          entitlement: policyAnnualEntitlement,
          used: 0,
        ),
        const LeaveBalance(
          type: 'sick',
          entitlement: _defaultSickEntitlement,
          used: 0,
        ),
        const LeaveBalance(
          type: 'other',
          entitlement: _defaultOtherEntitlement,
          used: 0,
        ),
      ];
    }

    double toNum(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '0') ?? 0;
    }

    return [
      LeaveBalance(
        type: 'annual',
        entitlement: policyAnnualEntitlement > 0
            ? toNum(row['annual_entitlement']) > 0
                  ? toNum(row['annual_entitlement'])
                  : policyAnnualEntitlement
            : 0,
        used: toNum(row['annual_used']),
      ),
      LeaveBalance(
        type: 'sick',
        entitlement: row['sick_entitlement'] == null
            ? _defaultSickEntitlement
            : toNum(row['sick_entitlement']),
        used: toNum(row['sick_used']),
      ),
      LeaveBalance(
        type: 'other',
        entitlement: row['other_entitlement'] == null
            ? _defaultOtherEntitlement
            : toNum(row['other_entitlement']),
        used: toNum(row['other_used']),
      ),
    ];
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

  DateTime? _annualLeaveEligibilityDate(DateTime? hireDate) {
    if (hireDate == null) return null;
    return _addMonthsClamped(DateTime(hireDate.year, hireDate.month, hireDate.day), 11);
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

  DateTime _addMonthsClamped(DateTime value, int monthsToAdd) {
    final monthIndex = value.month - 1 + monthsToAdd;
    final targetYear = value.year + (monthIndex ~/ 12);
    final targetMonth = (monthIndex % 12) + 1;
    final maxDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = value.day <= maxDay ? value.day : maxDay;
    return DateTime(targetYear, targetMonth, targetDay);
  }
}
