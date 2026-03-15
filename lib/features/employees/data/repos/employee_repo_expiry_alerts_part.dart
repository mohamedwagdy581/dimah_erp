part of 'employee_repo_impl.dart';

mixin _EmployeesRepoExpiryAlertsMixin on _EmployeesRepoExpiryAlertsHelpersMixin {
  @override
  Future<List<ExpiryAlertItem>> fetchExpiryAlerts() async {
    final tenantId = await _tenantId();
    final today = DateTime.now();
    final settings = await fetchExpiryAlertSettings();
    final maxDays = [
      settings.contractAlertDays,
      settings.residencyAlertDays,
      settings.insuranceAlertDays,
      settings.documentsAlertDays,
      120,
    ].reduce((a, b) => a > b ? a : b);
    final threshold = DateTime(today.year, today.month, today.day)
        .add(Duration(days: maxDays + 1));

    final employeesRes = await _client
        .from('employees')
        .select('id, full_name')
        .eq('tenant_id', tenantId)
        .order('full_name', ascending: true);
    final employeeNameById = <String, String>{
      for (final row in (employeesRes as List))
        (row as Map<String, dynamic>)['id'].toString():
            ((row)['full_name'] ?? '').toString(),
    };

    final personalRes = await _client
        .from('employee_personal')
        .select('employee_id, residency_expiry_date, insurance_expiry_date')
        .eq('tenant_id', tenantId);
    final contractsRes = await _client
        .from('employee_contracts')
        .select('employee_id, end_date, created_at')
        .eq('tenant_id', tenantId)
        .not('end_date', 'is', null)
        .order('created_at', ascending: false);
    final documentsRes = await _client
        .from('employee_documents')
        .select('employee_id, doc_type, expires_at, file_url')
        .eq('tenant_id', tenantId)
        .not('expires_at', 'is', null);

    final latestContractEndByEmployee = <String, DateTime>{};
    for (final row in (contractsRes as List)) {
      final map = row as Map<String, dynamic>;
      final employeeId = map['employee_id']?.toString();
      if (employeeId == null || employeeId.isEmpty || latestContractEndByEmployee.containsKey(employeeId)) {
        continue;
      }
      final endDate = DateTime.tryParse((map['end_date'] ?? '').toString());
      if (endDate != null) latestContractEndByEmployee[employeeId] = endDate;
    }

    final items = <ExpiryAlertItem>[];
    void maybeAdd({
      required String employeeId,
      required String type,
      required DateTime expiryDate,
      required int alertDays,
      String? fileUrl,
    }) {
      final left = _daysLeftFrom(today, expiryDate);
      if (left > alertDays || left > maxDays || expiryDate.isAfter(threshold)) return;
      items.add(
        ExpiryAlertItem(
          employeeId: employeeId,
          employeeName: employeeNameById[employeeId] ?? '-',
          type: type,
          expiryDate: expiryDate,
          daysLeft: left,
          fileUrl: fileUrl,
        ),
      );
    }

    for (final entry in latestContractEndByEmployee.entries) {
      maybeAdd(
        employeeId: entry.key,
        type: 'contract',
        expiryDate: entry.value,
        alertDays: settings.contractAlertDays,
      );
    }

    for (final row in (personalRes as List)) {
      final map = row as Map<String, dynamic>;
      final employeeId = map['employee_id']?.toString();
      if (employeeId == null || employeeId.isEmpty) continue;

      final residencyExpiry = DateTime.tryParse((map['residency_expiry_date'] ?? '').toString());
      if (residencyExpiry != null) {
        maybeAdd(employeeId: employeeId, type: 'residency', expiryDate: residencyExpiry, alertDays: settings.residencyAlertDays);
      }

      final insuranceExpiry = DateTime.tryParse((map['insurance_expiry_date'] ?? '').toString());
      if (insuranceExpiry != null) {
        maybeAdd(employeeId: employeeId, type: 'insurance', expiryDate: insuranceExpiry, alertDays: settings.insuranceAlertDays);
      }
    }

    for (final row in (documentsRes as List)) {
      final map = row as Map<String, dynamic>;
      final employeeId = map['employee_id']?.toString();
      final expiry = DateTime.tryParse((map['expires_at'] ?? '').toString());
      if (employeeId == null || employeeId.isEmpty || expiry == null) continue;
      maybeAdd(
        employeeId: employeeId,
        type: 'document:${(map['doc_type'] ?? 'other').toString()}',
        expiryDate: expiry,
        alertDays: settings.documentsAlertDays,
        fileUrl: (map['file_url'] ?? '').toString(),
      );
    }

    items.sort((a, b) {
      final daysCompare = a.daysLeft.compareTo(b.daysLeft);
      if (daysCompare != 0) return daysCompare;
      return a.employeeName.compareTo(b.employeeName);
    });
    return items;
  }
}
