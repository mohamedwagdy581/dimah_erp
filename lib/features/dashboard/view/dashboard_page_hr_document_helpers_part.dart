part of 'dashboard_page.dart';

extension _HrDashboardDocumentHelpers on _HrDashboardState {
  Future<List<_PendingItem>> _loadPendingItems(SupabaseClient client, String tenantId) async {
    final pendingItemsRes = await client
        .from('approval_requests')
        .select('request_type, created_at, employee:employees(full_name)')
        .eq('tenant_id', tenantId)
        .eq('status', 'pending')
        .eq('current_approver_role', 'hr')
        .order('created_at', ascending: false)
        .limit(10);
    return (pendingItemsRes as List).map((item) {
      final employee = item['employee'];
      return _PendingItem(
        employeeName: employee is Map ? (employee['full_name'] ?? '-').toString() : '-',
        requestType: (item['request_type'] ?? '').toString(),
        createdAt: DateTime.tryParse(item['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();
  }

  Future<({
    List<Map<String, dynamic>> expiringDocuments,
    int expiredDocumentsCount,
    int totalDocumentsWithExpiry,
    int validDocumentsWithExpiry,
    Map<String, int> expiringDocumentTypeCounts,
  })> _loadDocumentInsights(
    SupabaseClient client,
    String tenantId,
    String todayStr,
    String end30Str,
    DateTime today,
  ) async {
    try {
      final allDocumentsRes = await client.from('employee_documents').select('doc_type, expires_at').eq('tenant_id', tenantId).not('expires_at', 'is', null);
      var expiredDocumentsCount = 0;
      var totalDocumentsWithExpiry = 0;
      var validDocumentsWithExpiry = 0;
      final docTypeCounts = <String, int>{};
      for (final row in (allDocumentsRes as List)) {
        final map = row as Map<String, dynamic>;
        final expiry = DateTime.tryParse((map['expires_at'] ?? '').toString());
        if (expiry == null) continue;
        totalDocumentsWithExpiry++;
        if (!expiry.isBefore(DateTime(today.year, today.month, today.day))) {
          validDocumentsWithExpiry++;
        } else {
          expiredDocumentsCount++;
        }
      }
      final expiringDocumentsRes = await client
          .from('employee_documents')
          .select('doc_type, expires_at, employee:employees(full_name)')
          .eq('tenant_id', tenantId)
          .not('expires_at', 'is', null)
          .gte('expires_at', todayStr)
          .lte('expires_at', end30Str)
          .order('expires_at', ascending: true)
          .limit(10);
      final expiringDocuments = (expiringDocumentsRes as List)
          .cast<Map<String, dynamic>>()
          .map<Map<String, dynamic>>((item) {
        final employee = item['employee'];
        final docType = item['doc_type']?.toString() ?? '-';
        docTypeCounts.update(docType, (value) => value + 1, ifAbsent: () => 1);
        return {
          'employee_name': employee is Map ? (employee['full_name'] ?? '-').toString() : '-',
          'doc_type': docType,
          'expires_at': item['expires_at']?.toString() ?? '-',
        };
      }).toList();
      return (
        expiringDocuments: expiringDocuments,
        expiredDocumentsCount: expiredDocumentsCount,
        totalDocumentsWithExpiry: totalDocumentsWithExpiry,
        validDocumentsWithExpiry: validDocumentsWithExpiry,
        expiringDocumentTypeCounts: Map<String, int>.fromEntries(
          docTypeCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
        ),
      );
    } catch (_) {
      return (
        expiringDocuments: const <Map<String, dynamic>>[],
        expiredDocumentsCount: 0,
        totalDocumentsWithExpiry: 0,
        validDocumentsWithExpiry: 0,
        expiringDocumentTypeCounts: const <String, int>{},
      );
    }
  }

  Future<int> _loadLeavesThisMonth(SupabaseClient client, String tenantId, String monthStartStr) async {
    try {
      final res = await client.from('leave_requests').select('id').eq('tenant_id', tenantId).gte('start_date', monthStartStr).eq('status', 'approved');
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<({int totalExpiryAlerts, int urgentExpiryAlerts})> _loadExpiryAlerts() async {
    try {
      final alerts = await AppDI.employeesRepo.fetchExpiryAlerts();
      return (
        totalExpiryAlerts: alerts.length,
        urgentExpiryAlerts: alerts.where((item) => item.daysLeft <= 30).length,
      );
    } catch (_) {
      return (totalExpiryAlerts: 0, urgentExpiryAlerts: 0);
    }
  }
}
