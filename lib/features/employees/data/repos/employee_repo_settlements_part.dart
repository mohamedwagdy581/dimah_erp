part of 'employee_repo_impl.dart';

mixin _EmployeesRepoSettlementsMixin on _EmployeesRepoSessionMixin {
  Future<({List<EmployeeSettlementSummary> items, int total})> fetchSettlements({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    final tenantId = await _tenantId();
    final trimmedSearch = search?.trim().toLowerCase();

    final inactiveRes = await _client
        .from('employees')
        .select(
          'id, employee_number, full_name, photo_url, status, hire_date, '
          'job_title:job_titles(name)',
        )
        .eq('tenant_id', tenantId)
        .neq('status', 'active')
        .order('created_at', ascending: false)
        .limit(500);

    List settlementsRes = const [];
    try {
      settlementsRes = await _client
          .from('employee_settlements')
          .select(
            'id, employee_id, settlement_date, net_amount, created_at, '
            'employee:employees!employee_settlements_employee_id_fkey('
            'id, employee_number, full_name, photo_url, status, hire_date, '
            'job_title:job_titles(name))',
          )
          .eq('tenant_id', tenantId)
          .order('settlement_date', ascending: false)
          .order('created_at', ascending: false)
          .limit(500);
    } catch (_) {
      settlementsRes = const [];
    }

    final settlementsByEmployee = <String, List<Map<String, dynamic>>>{};
    for (final raw in settlementsRes) {
      final row = Map<String, dynamic>.from(raw as Map);
      final employeeId = row['employee_id']?.toString();
      if (employeeId == null || employeeId.isEmpty) continue;
      settlementsByEmployee.putIfAbsent(employeeId, () => []).add(row);
    }

    final summaries = <String, EmployeeSettlementSummary>{};

    for (final raw in (inactiveRes as List)) {
      final employee = Map<String, dynamic>.from(raw as Map);
      final employeeId = employee['id'].toString();
      summaries[employeeId] = _buildSettlementSummary(
        employeeId: employeeId,
        employee: employee,
        settlements: settlementsByEmployee[employeeId] ?? const [],
      );
    }

    for (final entry in settlementsByEmployee.entries) {
      if (summaries.containsKey(entry.key)) continue;
      final first = entry.value.isEmpty ? null : entry.value.first;
      final employee = first?['employee'];
      if (employee is! Map) continue;
      summaries[entry.key] = _buildSettlementSummary(
        employeeId: entry.key,
        employee: Map<String, dynamic>.from(employee),
        settlements: entry.value,
      );
    }

    final filtered = summaries.values.where((item) {
      if (trimmedSearch == null || trimmedSearch.isEmpty) return true;
      final haystacks = [
        item.fullName,
        item.employeeNumber ?? '',
        item.jobTitleName ?? '',
        item.status,
      ];
      for (final value in haystacks) {
        if (value.toLowerCase().contains(trimmedSearch)) return true;
      }
      return false;
    }).toList()
      ..sort((a, b) {
        final aDate = a.latestSettlementDate ?? a.hireDate ?? DateTime(1970);
        final bDate = b.latestSettlementDate ?? b.hireDate ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

    final total = filtered.length;
    final from = page * pageSize;
    if (from >= total) {
      return (items: const <EmployeeSettlementSummary>[], total: total);
    }
    final toExclusive = (from + pageSize) > total ? total : (from + pageSize);
    return (items: filtered.sublist(from, toExclusive), total: total);
  }

  EmployeeSettlementSummary _buildSettlementSummary({
    required String employeeId,
    required Map<String, dynamic> employee,
    required List<Map<String, dynamic>> settlements,
  }) {
    final latest = settlements.isEmpty ? null : settlements.first;
    final jobTitle = employee['job_title'];

    double? latestNetAmount;
    if (latest?['net_amount'] != null) {
      final rawAmount = latest!['net_amount'];
      if (rawAmount is num) {
        latestNetAmount = rawAmount.toDouble();
      } else {
        latestNetAmount = double.tryParse(rawAmount.toString());
      }
    }

    return EmployeeSettlementSummary(
      employeeId: employeeId,
      employeeNumber: employee['employee_number']?.toString(),
      fullName: (employee['full_name'] ?? '').toString(),
      photoUrl: employee['photo_url']?.toString(),
      status: (employee['status'] ?? 'inactive').toString(),
      jobTitleName: jobTitle is Map ? jobTitle['name']?.toString() : null,
      hireDate: employee['hire_date'] == null
          ? null
          : DateTime.tryParse(employee['hire_date'].toString()),
      latestSettlementDate: latest?['settlement_date'] == null
          ? null
          : DateTime.tryParse(latest!['settlement_date'].toString()),
      settlementsCount: settlements.length,
      latestNetAmount: latestNetAmount,
    );
  }

  Future<void> addEmployeeSettlement({
    required String employeeId,
    required DateTime finalWorkingDate,
    required DateTime settlementDate,
    required double grossAmount,
    required double deductionsAmount,
    String? notes,
  }) async {
    final tenantId = await _tenantId();
    await _client.from('employee_settlements').insert({
      'tenant_id': tenantId,
      'employee_id': employeeId,
      'final_working_date': _toDateOnly(finalWorkingDate),
      'settlement_date': _toDateOnly(settlementDate),
      'gross_amount': grossAmount,
      'deductions_amount': deductionsAmount,
      'net_amount': grossAmount - deductionsAmount,
      'notes': _normalizeOptionalText(notes),
    });

    await _client
        .from('employees')
        .update({'status': 'inactive'})
        .eq('tenant_id', tenantId)
        .eq('id', employeeId);
  }
}
