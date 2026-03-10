import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/app_di.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/session/session_cubit.dart';
import '../../../l10n/app_localizations.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        if (state is! SessionReady) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = state.user;
        if (user.role == 'hr') {
          return const _HrDashboard();
        }
        if ((user.role == 'manager' || user.role == 'direct_manager') &&
            user.employeeId != null) {
          return _ManagerDashboard(managerEmployeeId: user.employeeId!);
        }
        if (user.role == 'employee' && user.employeeId != null) {
          return _EmployeeDashboard(employeeId: user.employeeId!);
        }
        return _BackOfficeDashboard(title: t.menuDashboard);
      },
    );
  }
}

class _BackOfficeDashboard extends StatelessWidget {
  const _BackOfficeDashboard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(title));
  }
}

class _HrDashboard extends StatefulWidget {
  const _HrDashboard();

  @override
  State<_HrDashboard> createState() => _HrDashboardState();
}

class _HrDashboardState extends State<_HrDashboard> {
  late Future<_HrDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return FutureBuilder<_HrDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.failedToLoadHrDashboard,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: Text(t.retry),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data ?? const _HrDashboardData();
        return LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 1200;
            final kpiWidth = isWide ? (c.maxWidth - 48) / 3 : 280.0;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Text(
                      t.hrDashboard,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: Text(t.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _KpiCard(
                      width: kpiWidth,
                      title: t.activeEmployeesKpi,
                      value: '${data.activeEmployees}',
                      subtitle: t.currentHeadcount,
                      icon: Icons.badge_outlined,
                    ),
                    _KpiCard(
                      width: kpiWidth,
                      title: t.pendingApprovalsKpi,
                      value: '${data.pendingApprovals}',
                      subtitle: t.waitingHrAction,
                      icon: Icons.approval_outlined,
                    ),
                    _KpiCard(
                      width: kpiWidth,
                      title: t.onLeaveTodayKpi,
                      value: '${data.onLeaveToday}',
                      subtitle: t.approvedLeaveToday,
                      icon: Icons.event_busy_outlined,
                    ),
                    _KpiCard(
                      width: kpiWidth,
                      title: t.noCheckInTodayKpi,
                      value: '${data.missingCheckInToday}',
                      subtitle: t.activeStaffNotCheckedIn,
                      icon: Icons.login_outlined,
                    ),
                    _KpiCard(
                      width: kpiWidth,
                      title: t.leavesThisMonthKpi,
                      value: '${data.leavesThisMonth}',
                      subtitle: t.approvedLeaveRequests,
                      icon: Icons.date_range_outlined,
                    ),
                    _KpiCard(
                      width: kpiWidth,
                      title: t.expiryAlertsKpi,
                      value: '${data.totalExpiryAlerts}',
                      subtitle: t.hrAlertsTitle,
                      icon: Icons.notifications_active_outlined,
                    ),
                    _KpiCard(
                      width: kpiWidth,
                      title: t.expiredDocumentsKpi,
                      value: '${data.expiredDocumentsCount}',
                      subtitle: t.documentExpiryNeedsAction,
                      icon: Icons.warning_amber_outlined,
                    ),
                    _KpiCard(
                      width: kpiWidth,
                      title: t.urgentAlertsKpi,
                      value: '${data.urgentExpiryAlerts}',
                      subtitle: t.expiringWithin30Days,
                      icon: Icons.crisis_alert_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _HrWorkflowPanel(data: data),
                const SizedBox(height: 12),
                _QuickActionsPanel(data: data),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricBarCard(
                      width: isWide ? (c.maxWidth - 24) / 2 : c.maxWidth,
                      title: t.checkInCoverage,
                      value: data.checkInCoverage,
                    ),
                    _MetricBarCard(
                      width: isWide ? (c.maxWidth - 24) / 2 : c.maxWidth,
                      title: t.approvalLoad,
                      value: data.approvalLoad,
                      invertColor: true,
                    ),
                    _MetricBarCard(
                      width: isWide ? (c.maxWidth - 24) / 2 : c.maxWidth,
                      title: t.documentCompliance,
                      value: data.documentCompliance,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _InsightPanel(
                      width: isWide ? (c.maxWidth - 24) / 2 : c.maxWidth,
                      title: t.todayAttendanceInsights,
                      count: data.checkedInToday,
                      emptyText: t.noAttendanceInsightsToday,
                      children: [
                        _MiniStatTile(
                          icon: Icons.how_to_reg_outlined,
                          label: t.checkedInTodayLabel,
                          value: '${data.checkedInToday}',
                        ),
                        _MiniStatTile(
                          icon: Icons.schedule_outlined,
                          label: t.attendanceLate,
                          value: '${data.lateToday}',
                          color: Colors.orange,
                        ),
                        _MiniStatTile(
                          icon: Icons.more_time_outlined,
                          label: t.overtime,
                          value: '${data.overtimeToday}',
                          color: Colors.lightBlue,
                        ),
                        _MiniStatTile(
                          icon: Icons.person_off_outlined,
                          label: t.absentTodayLabel,
                          value: '${data.missingCheckInToday}',
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                    _InsightPanel(
                      width: isWide ? (c.maxWidth - 24) / 2 : c.maxWidth,
                      title: t.attendanceAlertsToday,
                      count: data.todayAttentionItems.length,
                      emptyText: t.noAttendanceAlertsToday,
                      children: data.todayAttentionItems
                          .map(
                            (item) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                item.type == 'late'
                                    ? Icons.schedule_outlined
                                    : Icons.more_time_outlined,
                              ),
                              title: Text(item.employeeName),
                              trailing: Text(
                                item.valueLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: item.type == 'late'
                                      ? Colors.orange
                                      : Colors.lightBlue,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _InsightPanel(
                      width: isWide ? (c.maxWidth - 24) / 2 : c.maxWidth,
                      title: t.pendingRequestsTop10,
                      count: data.pendingItems.length,
                      emptyText: t.noPendingRequests,
                      children: data.pendingItems
                          .map(
                            (r) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.pending_actions),
                              title: Text(r.employeeName),
                              subtitle: Text(
                                '${r.requestType} | ${_dateOnly(r.createdAt)}',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    _InsightPanel(
                      width: isWide ? (c.maxWidth - 24) / 2 : c.maxWidth,
                      title: t.expiringDocuments30Days,
                      count: data.expiringDocuments.length,
                      emptyText: t.noDocumentExpiries30Days,
                      children: data.expiringDocuments
                          .map(
                            (d) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.description_outlined),
                              title: Text(d['employee_name']?.toString() ?? '-'),
                              subtitle: Text(
                                '${d['doc_type'] ?? t.documentLabel} | ${t.expires}: ${d['expires_at'] ?? '-'}',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    _InsightPanel(
                      width: isWide ? (c.maxWidth - 24) / 2 : c.maxWidth,
                      title: t.expiringDocumentsByType,
                      count: data.expiringDocumentTypeCounts.length,
                      emptyText: t.noDocumentExpiries30Days,
                      children: data.expiringDocumentTypeCounts.entries
                          .map(
                            (entry) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.label_outline),
                              title: Text(_labelForDocumentType(t, entry.key)),
                              trailing: Text(
                                '${entry.value}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _dateOnly(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  Future<_HrDashboardData> _load() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return const _HrDashboardData();
    final me = await client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();
    final tenantId = me['tenant_id'].toString();

    final today = DateTime.now();
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final end30 = today.add(const Duration(days: 30));
    final end30Str =
        '${end30.year.toString().padLeft(4, '0')}-${end30.month.toString().padLeft(2, '0')}-${end30.day.toString().padLeft(2, '0')}';
    final monthStart = DateTime(today.year, today.month, 1);
    final monthStartStr =
        '${monthStart.year.toString().padLeft(4, '0')}-${monthStart.month.toString().padLeft(2, '0')}-${monthStart.day.toString().padLeft(2, '0')}';

    final activeEmployeesRes = await client
        .from('employees')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('status', 'active');
    final activeEmployees = (activeEmployeesRes as List).length;

    final pendingApprovalsRes = await client
        .from('approval_requests')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('status', 'pending')
        .eq('current_approver_role', 'hr');
    final pendingApprovals = (pendingApprovalsRes as List).length;

    final onLeaveTodayRes = await client
        .from('leave_requests')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('status', 'approved')
        .lte('start_date', todayStr)
        .gte('end_date', todayStr);
    final onLeaveToday = (onLeaveTodayRes as List).length;

    final todayAttendanceRes = await client
        .from('attendance_records')
        .select('employee_id, check_in, check_out, status, employee:employees(full_name)')
        .eq('tenant_id', tenantId)
        .eq('date', todayStr);
    final todayAttendanceRows = (todayAttendanceRes as List);
    final attendedEmployeeIds = todayAttendanceRows
        .where((r) => r['check_in'] != null)
        .map((r) => r['employee_id'].toString())
        .toSet();
    final checkedInToday = attendedEmployeeIds.length;
    final missingCheckInToday = activeEmployees - attendedEmployeeIds.length;
    final lateToday = todayAttendanceRows
        .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'late')
        .length;
    final overtimeToday = todayAttendanceRows
        .where((r) => _overtimeMinutesFromRow(r['check_out']) > 0)
        .length;
    final todayAttentionItems = todayAttendanceRows
        .map((r) {
          final employee = r['employee'];
          final employeeName = employee is Map
              ? (employee['full_name'] ?? '-').toString()
              : '-';
          final lateMinutes = _lateMinutesFromRow(r['check_in']);
          final overtimeMinutes = _overtimeMinutesFromRow(r['check_out']);
          if (lateMinutes > 0) {
            return _AttendanceAttentionItem(
              employeeName: employeeName,
              type: 'late',
              valueLabel: '${lateMinutes}m',
              value: lateMinutes,
            );
          }
          if (overtimeMinutes > 0) {
            return _AttendanceAttentionItem(
              employeeName: employeeName,
              type: 'overtime',
              valueLabel: '${overtimeMinutes}m',
              value: overtimeMinutes,
            );
          }
          return null;
        })
        .whereType<_AttendanceAttentionItem>()
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final pendingItemsRes = await client
        .from('approval_requests')
        .select(
          'request_type, created_at, employee:employees(full_name)',
        )
        .eq('tenant_id', tenantId)
        .eq('status', 'pending')
        .eq('current_approver_role', 'hr')
        .order('created_at', ascending: false)
        .limit(10);
    final pendingItems = (pendingItemsRes as List).map((e) {
      final employee = e['employee'];
      final fullName = employee is Map
          ? (employee['full_name'] ?? '-').toString()
          : '-';
      return _PendingItem(
        employeeName: fullName,
        requestType: (e['request_type'] ?? '').toString(),
        createdAt:
            DateTime.tryParse(e['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();

    List<Map<String, dynamic>> expiringDocuments = const [];
    var expiredDocumentsCount = 0;
    var totalDocumentsWithExpiry = 0;
    var validDocumentsWithExpiry = 0;
    Map<String, int> expiringDocumentTypeCounts = const {};
    try {
      final allDocumentsRes = await client
          .from('employee_documents')
          .select('doc_type, expires_at')
          .eq('tenant_id', tenantId)
          .not('expires_at', 'is', null);
      final docTypeCounts = <String, int>{};
      for (final row in (allDocumentsRes as List)) {
        final m = row as Map<String, dynamic>;
        final expiry = DateTime.tryParse((m['expires_at'] ?? '').toString());
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
          .select(
            'doc_type, expires_at, employee:employees(full_name)',
          )
          .eq('tenant_id', tenantId)
          .not('expires_at', 'is', null)
          .gte('expires_at', todayStr)
          .lte('expires_at', end30Str)
          .order('expires_at', ascending: true)
          .limit(10);
      expiringDocuments = (expiringDocumentsRes as List).map((e) {
        final employee = e['employee'];
        final docType = e['doc_type']?.toString() ?? '-';
        docTypeCounts.update(docType, (v) => v + 1, ifAbsent: () => 1);
        return {
          'employee_name': employee is Map
              ? (employee['full_name'] ?? '-').toString()
              : '-',
          'doc_type': docType,
          'expires_at': e['expires_at']?.toString() ?? '-',
        };
      }).toList();
      expiringDocumentTypeCounts = Map<String, int>.fromEntries(
        docTypeCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      );
    } catch (_) {
      expiringDocuments = const [];
      expiredDocumentsCount = 0;
      totalDocumentsWithExpiry = 0;
      validDocumentsWithExpiry = 0;
      expiringDocumentTypeCounts = const {};
    }

    int leavesThisMonth = 0;
    try {
      final leavesThisMonthRes = await client
          .from('leave_requests')
          .select('id')
          .eq('tenant_id', tenantId)
          .gte('start_date', monthStartStr)
          .eq('status', 'approved');
      leavesThisMonth = (leavesThisMonthRes as List).length;
    } catch (_) {
      leavesThisMonth = 0;
    }

    int totalExpiryAlerts = 0;
    int urgentExpiryAlerts = 0;
    try {
      final alerts = await AppDI.employeesRepo.fetchExpiryAlerts();
      totalExpiryAlerts = alerts.length;
      urgentExpiryAlerts = alerts.where((a) => a.daysLeft <= 30).length;
    } catch (_) {
      totalExpiryAlerts = 0;
      urgentExpiryAlerts = 0;
    }

    return _HrDashboardData(
      activeEmployees: activeEmployees,
      pendingApprovals: pendingApprovals,
      onLeaveToday: onLeaveToday,
      missingCheckInToday: missingCheckInToday < 0 ? 0 : missingCheckInToday,
      leavesThisMonth: leavesThisMonth,
      checkedInToday: checkedInToday,
      lateToday: lateToday,
      overtimeToday: overtimeToday,
      todayAttentionItems: todayAttentionItems.take(8).toList(),
      pendingItems: pendingItems,
      expiringDocuments: expiringDocuments,
      totalExpiryAlerts: totalExpiryAlerts,
      urgentExpiryAlerts: urgentExpiryAlerts,
      expiredDocumentsCount: expiredDocumentsCount,
      totalDocumentsWithExpiry: totalDocumentsWithExpiry,
      validDocumentsWithExpiry: validDocumentsWithExpiry,
      expiringDocumentTypeCounts: expiringDocumentTypeCounts,
    );
  }

  int _lateMinutesFromRow(dynamic value) {
    if (value == null) return 0;
    final checkIn = DateTime.tryParse(value.toString());
    if (checkIn == null) return 0;
    final workStart = DateTime(
      checkIn.year,
      checkIn.month,
      checkIn.day,
      9,
      15,
    );
    if (!checkIn.isAfter(workStart)) return 0;
    return checkIn.difference(workStart).inMinutes;
  }

  int _overtimeMinutesFromRow(dynamic value) {
    if (value == null) return 0;
    final checkOut = DateTime.tryParse(value.toString());
    if (checkOut == null) return 0;
    final workEnd = DateTime(
      checkOut.year,
      checkOut.month,
      checkOut.day,
      17,
      0,
    );
    if (!checkOut.isAfter(workEnd)) return 0;
    return checkOut.difference(workEnd).inMinutes;
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.clamp(260, 420),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingItem {
  const _PendingItem({
    required this.employeeName,
    required this.requestType,
    required this.createdAt,
  });

  final String employeeName;
  final String requestType;
  final DateTime createdAt;
}

class _HrDashboardData {
  const _HrDashboardData({
    this.activeEmployees = 0,
    this.pendingApprovals = 0,
    this.onLeaveToday = 0,
    this.missingCheckInToday = 0,
    this.leavesThisMonth = 0,
    this.checkedInToday = 0,
    this.lateToday = 0,
    this.overtimeToday = 0,
    this.todayAttentionItems = const [],
    this.pendingItems = const [],
    this.expiringDocuments = const [],
    this.totalExpiryAlerts = 0,
    this.urgentExpiryAlerts = 0,
    this.expiredDocumentsCount = 0,
    this.totalDocumentsWithExpiry = 0,
    this.validDocumentsWithExpiry = 0,
    this.expiringDocumentTypeCounts = const {},
  });

  final int activeEmployees;
  final int pendingApprovals;
  final int onLeaveToday;
  final int missingCheckInToday;
  final int leavesThisMonth;
  final int checkedInToday;
  final int lateToday;
  final int overtimeToday;
  final List<_AttendanceAttentionItem> todayAttentionItems;
  final List<_PendingItem> pendingItems;
  final List<Map<String, dynamic>> expiringDocuments;
  final int totalExpiryAlerts;
  final int urgentExpiryAlerts;
  final int expiredDocumentsCount;
  final int totalDocumentsWithExpiry;
  final int validDocumentsWithExpiry;
  final Map<String, int> expiringDocumentTypeCounts;

  double get checkInCoverage {
    if (activeEmployees <= 0) return 0;
    return checkedInToday / activeEmployees;
  }

  double get approvalLoad {
    if (activeEmployees <= 0) return 0;
    return pendingApprovals / activeEmployees;
  }

  double get documentCompliance {
    if (totalDocumentsWithExpiry <= 0) return 0;
    return validDocumentsWithExpiry / totalDocumentsWithExpiry;
  }
}

class _AttendanceAttentionItem {
  const _AttendanceAttentionItem({
    required this.employeeName,
    required this.type,
    required this.valueLabel,
    required this.value,
  });

  final String employeeName;
  final String type;
  final String valueLabel;
  final int value;
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({required this.data});

  final _HrDashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.quickActions,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('${AppRoutes.approvals}?status=pending'),
                  icon: const Icon(Icons.approval_outlined),
                  label: Text('${t.pendingApprovalsKpi} (${data.pendingApprovals})'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('${AppRoutes.hrAlerts}?type=document'),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text('${t.hrAlertsTitle} (${data.totalExpiryAlerts})'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go('${AppRoutes.employeeDocs}?expiry=expired'),
                  icon: const Icon(Icons.description_outlined),
                  label: Text('${t.menuEmployeeDocs} (${data.expiringDocuments.length})'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.employees),
                  icon: const Icon(Icons.people_outline),
                  label: Text(t.activeEmployeesKpi),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HrWorkflowPanel extends StatelessWidget {
  const _HrWorkflowPanel({required this.data});

  final _HrDashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.hrWorkflowBoard,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _WorkflowStepCard(
                  index: 1,
                  title: t.reviewPendingApprovals,
                  subtitle: t.pendingWithValue(data.pendingApprovals),
                  color: Colors.orange,
                  onTap: () => context.go('${AppRoutes.approvals}?status=pending'),
                ),
                _WorkflowStepCard(
                  index: 2,
                  title: t.resolveExpiryAlerts,
                  subtitle: t.pendingWithValue(data.totalExpiryAlerts),
                  color: Colors.redAccent,
                  onTap: () => context.go(AppRoutes.hrAlerts),
                ),
                _WorkflowStepCard(
                  index: 3,
                  title: t.completeEmployeeDocuments,
                  subtitle: t.pendingWithValue(data.expiredDocumentsCount),
                  color: Colors.indigo,
                  onTap: () =>
                      context.go('${AppRoutes.employeeDocs}?expiry=expired'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowStepCard extends StatelessWidget {
  const _WorkflowStepCard({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final int index;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.18),
              foregroundColor: color,
              child: Text('$index'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _labelForDocumentType(AppLocalizations t, String type) {
  switch (type) {
    case 'id_card':
      return t.idCard;
    case 'passport':
      return t.passport;
    case 'cv':
      return 'CV';
    case 'graduation_cert':
      return t.graduationCert;
    case 'national_address':
      return t.nationalAddress;
    case 'bank_iban_certificate':
      return t.bankIbanCertificate;
    case 'salary_certificate':
      return t.salaryCertificate;
    case 'salary_definition':
      return t.salaryDefinition;
    case 'contract':
      return t.contract;
    case 'residency':
      return t.residencyDocument;
    case 'driving_license':
      return t.drivingLicense;
    case 'offer_letter':
      return t.offerLetter;
    case 'medical_insurance':
      return t.medicalInsurance;
    case 'medical_report':
      return t.medicalReport;
    default:
      return t.documentLabel;
  }
}

class _MetricBarCard extends StatelessWidget {
  const _MetricBarCard({
    required this.width,
    required this.title,
    required this.value,
    this.invertColor = false,
  });

  final double width;
  final String title;
  final double value;
  final bool invertColor;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 1).toDouble();
    final color = invertColor
        ? (v <= 0.2
              ? Colors.green
              : v <= 0.5
              ? Colors.orange
              : Colors.red)
        : (v >= 0.8
              ? Colors.green
              : v >= 0.5
              ? Colors.orange
              : Colors.red);
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: v,
                color: color,
                minHeight: 8,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 8),
              Text(
                '${(v * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  const _MiniStatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: effectiveColor),
      title: Text(label),
      trailing: Text(
        value,
        style: TextStyle(
          color: effectiveColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({
    required this.width,
    required this.title,
    required this.count,
    required this.emptyText,
    required this.children,
  });

  final double width;
  final String title;
  final int count;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$count'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (children.isEmpty) Text(emptyText) else ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeDashboard extends StatelessWidget {
  const _EmployeeDashboard({required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return FutureBuilder<_EmployeeDashboardData>(
      future: _loadData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? const _EmployeeDashboardData();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _ProductivityCircle(
                  value: data.productivityPercent,
                  title: t.productivity,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.myTasks,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(t.totalWithValue(data.totalTasks)),
                          Text(t.pendingWithValue(data.pendingTasks)),
                          Text(t.doneWithValue(data.doneTasks)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.recentTasks,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (data.recentTasks.isEmpty)
                      Text(t.noTasksAssignedYet)
                    else
                      ...data.recentTasks.map(
                        (t) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(t['title']?.toString() ?? '-'),
                          subtitle: Text(
                            '${AppLocalizations.of(context)!.status}: ${t['status']} | ${AppLocalizations.of(context)!.progressLabel(((t['progress'] as num?)?.toInt() ?? 0))}',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<_EmployeeDashboardData> _loadData() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return const _EmployeeDashboardData();
    final me = await client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();
    final tenantId = me['tenant_id'].toString();

    final tasks = await client
        .from('employee_tasks')
        .select('title, status, progress, created_at')
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false)
        .limit(10);
    final rows = (tasks as List).cast<Map<String, dynamic>>();
    final total = rows.length;
    final done = rows.where((e) => e['status'] == 'done').length;
    final pending = rows.where((e) => e['status'] != 'done').length;
    final avgProgress = total == 0
        ? 0.0
        : rows.fold<double>(
                0,
                (sum, e) => sum + ((e['progress'] as num?)?.toDouble() ?? 0),
              ) /
              total;
    return _EmployeeDashboardData(
      totalTasks: total,
      doneTasks: done,
      pendingTasks: pending,
      productivityPercent: avgProgress,
      recentTasks: rows,
    );
  }
}

class _ManagerDashboard extends StatefulWidget {
  const _ManagerDashboard({required this.managerEmployeeId});

  final String managerEmployeeId;

  @override
  State<_ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<_ManagerDashboard> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _estimateHours = TextEditingController(text: '8');
  String? _employeeId;
  String _priority = 'medium';
  String _taskType = 'general';
  List<String> _visibleTaskCatalog = const ['general'];
  bool _saving = false;
  DateTime? _dueDate;
  late Future<_ManagerDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _estimateHours.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return FutureBuilder<_ManagerDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? const _ManagerDashboardData();
        final taskCatalog = _taskCatalogForDepartments(data.managedDepartmentNames);
        _visibleTaskCatalog = taskCatalog;
        if (!taskCatalog.contains(_taskType)) {
          _taskType = taskCatalog.first;
        }
        return LayoutBuilder(
          builder: (context, c) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Text(
                      t.teamProductivity,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _future = _loadData();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(t.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SmallStatCard(
                      title: t.teamMembers,
                      value: '${data.members.length}',
                    ),
                    _SmallStatCard(
                      title: t.openTasks,
                      value: '${data.teamPendingTasks}',
                      trendPercent: data.pendingTrendPercent,
                      invertTrend: true,
                    ),
                    _SmallStatCard(
                      title: t.overdueTasks,
                      value: '${data.overdueTasks}',
                    ),
                    _SmallStatCard(
                      title: t.completionRate,
                      value: '${data.completionRate.toStringAsFixed(1)}%',
                      trendPercent: data.completionTrendPercent,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _PerformanceListCard(
                      title: t.topPerformers,
                      emptyText: t.noTeamDataYet,
                      members: data.topPerformers,
                      color: Colors.green,
                    ),
                    _PerformanceListCard(
                      title: t.needsAttention,
                      emptyText: t.noTeamDataYet,
                      members: data.needsAttention,
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: data.members.map((m) {
                    return SizedBox(
                      width: 220,
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showMemberTaskTimeline(
                            employeeId: m.employeeId,
                            employeeName: m.name,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                _ProductivityCircle(
                                  value: m.productivityPercent,
                                  title: m.name,
                                ),
                                const SizedBox(height: 8),
                                Text(t.tasksWithValue(m.totalTasks)),
                                Text(t.doneWithValue(m.doneTasks)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.dueSoonTasks,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (data.dueSoonTasks.isEmpty)
                          Text(t.noDueSoonTasks)
                        else
                          ...data.dueSoonTasks.map(
                            (r) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.schedule),
                              title: Text(r['title']?.toString() ?? '-'),
                              subtitle: Text(
                                '${r['employee_name'] ?? '-'} | ${r['due_date'] ?? '-'}',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.assignTask,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data.primaryManagedDepartmentName == null
                              ? t.taskCatalog
                              : t.taskCatalogForDepartment(
                                  data.primaryManagedDepartmentName!,
                                ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: taskCatalog
                              .map(
                                (type) => Chip(
                                  label: Text(_taskTypeLabel(t, type)),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _employeeId,
                          decoration: InputDecoration(
                            labelText: t.employee,
                            border: const OutlineInputBorder(),
                          ),
                          items: data.members
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m.employeeId,
                                  child: Text(m.name),
                                ),
                              )
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (v) => setState(() => _employeeId = v),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _title,
                          enabled: !_saving,
                          decoration: InputDecoration(
                            labelText: t.taskTitle,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _description,
                          enabled: !_saving,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: t.descriptionOptional,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _estimateHours,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: t.estimateHours,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _priority,
                                decoration: InputDecoration(
                                  labelText: t.priority,
                                  border: const OutlineInputBorder(),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'low',
                                    child: Text(t.priorityLow),
                                  ),
                                  DropdownMenuItem(
                                    value: 'medium',
                                    child: Text(t.priorityMedium),
                                  ),
                                  DropdownMenuItem(
                                    value: 'high',
                                    child: Text(t.priorityHigh),
                                  ),
                                ],
                                onChanged: _saving
                                    ? null
                                    : (v) {
                                        if (v == null) return;
                                        setState(() => _priority = v);
                                      },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _taskType,
                                decoration: InputDecoration(
                                  labelText: t.taskType,
                                  border: const OutlineInputBorder(),
                                ),
                                items: taskCatalog
                                    .map(
                                      (type) => DropdownMenuItem<String>(
                                        value: type,
                                        child: Text(_taskTypeLabel(t, type)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _saving
                                    ? null
                                    : (v) {
                                      if (v == null) return;
                                      setState(() => _taskType = v);
                                    },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickDueDate,
                          icon: const Icon(Icons.event),
                          label: Text(
                            _dueDate == null
                                ? t.dueDateOptional
                                : '${_dueDate!.year.toString().padLeft(4, '0')}-'
                                      '${_dueDate!.month.toString().padLeft(2, '0')}-'
                                      '${_dueDate!.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _saving ? null : _assignTask,
                          icon: const Icon(Icons.send_outlined),
                          label: Text(_saving ? t.assigning : t.assignTask),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _assignTask() async {
    if (_employeeId == null || _employeeId!.isEmpty) return;
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final estimate = double.tryParse(_estimateHours.text.trim());
    if (estimate == null || estimate <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.invalidEstimateHours)));
      return;
    }
    setState(() => _saving = true);
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) throw Exception(AppLocalizations.of(context)!.sessionMissing);
      final me = await client
          .from('users')
          .select('tenant_id')
          .eq('id', uid)
          .single();
      final tenantId = me['tenant_id'].toString();
      final autoWeight = await _resolveAutoWeight(
        tenantId: tenantId,
        employeeId: _employeeId!,
        taskType: _taskType,
      );
      final inserted = await client.from('employee_tasks').insert({
        'tenant_id': tenantId,
        'employee_id': _employeeId,
        'assigned_by_employee_id': widget.managerEmployeeId,
        'title': title,
        'description': _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        'task_type': _taskType,
        'estimate_hours': estimate,
        'priority': _priority,
        'weight': autoWeight,
        'due_date': _dueDate == null
            ? null
            : DateTime(
                _dueDate!.year,
                _dueDate!.month,
                _dueDate!.day,
              ).toIso8601String().split('T').first,
        'status': 'todo',
        'progress': 0,
      }).select('id').single();
      final taskId = inserted['id']?.toString();
      if (taskId != null && taskId.isNotEmpty) {
        await _appendTaskEvent(
          taskId: taskId,
          eventType: 'assigned',
        );
      }
      if (!mounted) return;
      _title.clear();
      _description.clear();
      _estimateHours.text = '8';
      _priority = 'medium';
      _taskType = _visibleTaskCatalog.first;
      _dueDate = null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.taskAssigned)));
      setState(() {
        _saving = false;
        _future = _loadData();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.assignFailed(e.toString()))));
    }
  }

  int _defaultWeightForType(String type) {
    switch (type) {
      case 'development':
        return 4;
      case 'bug_fix':
        return 4;
      case 'testing':
        return 3;
      case 'support':
        return 2;
      case 'transfer':
        return 1;
      case 'report':
        return 3;
      case 'tax':
        return 5;
      case 'payroll':
        return 4;
      case 'reconciliation':
        return 4;
      case 'recruitment':
        return 3;
      case 'onboarding':
        return 3;
      case 'employee_docs':
        return 2;
      default:
        return 3;
    }
  }

  String _taskTypeLabel(AppLocalizations t, String type) {
    switch (type) {
      case 'development':
        return t.taskTypeDevelopment;
      case 'bug_fix':
        return t.taskTypeBugFix;
      case 'testing':
        return t.taskTypeTesting;
      case 'support':
        return t.taskTypeSupport;
      case 'transfer':
        return t.taskTypeTransfer;
      case 'report':
        return t.taskTypeReport;
      case 'tax':
        return t.taskTypeTax;
      case 'payroll':
        return t.taskTypePayroll;
      case 'reconciliation':
        return t.taskTypeReconciliation;
      case 'recruitment':
        return t.taskTypeRecruitment;
      case 'onboarding':
        return t.taskTypeOnboarding;
      case 'employee_docs':
        return t.taskTypeEmployeeDocs;
      default:
        return t.taskTypeGeneral;
    }
  }

  List<String> _taskCatalogForDepartments(List<String> departmentNames) {
    final catalog = <String>{'general'};
    for (final rawName in departmentNames) {
      final name = rawName.toLowerCase();
      if (name.contains('it') ||
          name.contains('tech') ||
          name.contains('develop') ||
          name.contains('برمج') ||
          name.contains('تقني') ||
          name.contains('التطوير')) {
        catalog.addAll([
          'development',
          'bug_fix',
          'testing',
          'support',
          'report',
        ]);
        continue;
      }
      if (name.contains('fin') ||
          name.contains('account') ||
          name.contains('مال') ||
          name.contains('محاسب')) {
        catalog.addAll([
          'transfer',
          'report',
          'tax',
          'payroll',
          'reconciliation',
        ]);
        continue;
      }
      if (name.contains('hr') ||
          name.contains('human') ||
          name.contains('بشر') ||
          name.contains('موارد')) {
        catalog.addAll([
          'recruitment',
          'employee_docs',
          'onboarding',
          'report',
        ]);
        continue;
      }
      catalog.add('report');
    }
    return catalog.toList();
  }

  Future<int> _resolveAutoWeight({
    required String tenantId,
    required String employeeId,
    required String taskType,
  }) async {
    final client = Supabase.instance.client;
    try {
      final emp = await client
          .from('employees')
          .select('department_id')
          .eq('tenant_id', tenantId)
          .eq('id', employeeId)
          .maybeSingle();
      final departmentId = emp?['department_id']?.toString();

      if (departmentId != null && departmentId.isNotEmpty) {
        final deptRow = await client
            .from('task_type_weights')
            .select('weight')
            .eq('tenant_id', tenantId)
            .eq('department_id', departmentId)
            .eq('task_type', taskType)
            .maybeSingle();
        final w = (deptRow?['weight'] as num?)?.toInt();
        if (w != null) return w.clamp(1, 5);
      }

      final globalRow = await client
          .from('task_type_weights')
          .select('weight')
          .eq('tenant_id', tenantId)
          .filter('department_id', 'is', null)
          .eq('task_type', taskType)
          .maybeSingle();
      final globalW = (globalRow?['weight'] as num?)?.toInt();
      if (globalW != null) return globalW.clamp(1, 5);
    } catch (_) {}
    return _defaultWeightForType(taskType);
  }

  Future<_ManagerDashboardData> _loadData() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return const _ManagerDashboardData();
    final me = await client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();
    final tenantId = me['tenant_id'].toString();

    final managedDepartmentsRes = await client
        .from('departments')
        .select('id, name')
        .eq('tenant_id', tenantId)
        .eq('manager_id', widget.managerEmployeeId);
    final managedDepartments = (managedDepartmentsRes as List).cast<Map<String, dynamic>>();
    final managedDepartmentIds = managedDepartments
        .map((e) => e['id'].toString())
        .toList();
    final managedDepartmentNames = managedDepartments
        .map((e) => (e['name'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toList();

    final directReportsRes = await client
        .from('employees')
        .select('id, full_name')
        .eq('tenant_id', tenantId)
        .eq('manager_id', widget.managerEmployeeId)
        .eq('status', 'active');
    final directReports = (directReportsRes as List).cast<Map<String, dynamic>>();

    final deptEmployees = <Map<String, dynamic>>[];
    if (managedDepartmentIds.isNotEmpty) {
      final deptRes = await client
          .from('employees')
          .select('id, full_name')
          .eq('tenant_id', tenantId)
          .inFilter('department_id', managedDepartmentIds)
          .eq('status', 'active');
      deptEmployees.addAll((deptRes as List).cast<Map<String, dynamic>>());
    }

    final byId = <String, Map<String, dynamic>>{};
    for (final e in [...directReports, ...deptEmployees]) {
      final id = e['id'].toString();
      if (id == widget.managerEmployeeId) continue;
      byId[id] = e;
    }
    final members = byId.values.toList()
      ..sort((a, b) => (a['full_name']?.toString() ?? '').compareTo(
            b['full_name']?.toString() ?? '',
          ));
    if (members.isEmpty) return const _ManagerDashboardData();

    final ids = members.map((e) => e['id'].toString()).toList();
    final tasks = await client
        .from('employee_tasks')
        .select(
          'id, employee_id, status, progress, due_date, title, created_at, updated_at, '
          'completed_at, qa_status, weight',
        )
        .eq('tenant_id', tenantId)
        .inFilter('employee_id', ids);
    final taskRows = (tasks as List).cast<Map<String, dynamic>>();
    final memberNameById = <String, String>{
      for (final m in members) m['id'].toString(): m['full_name']?.toString() ?? '-',
    };

    final metrics = members.map((m) {
      final id = m['id'].toString();
      final own = taskRows.where((t) => t['employee_id'].toString() == id);
      final total = own.length;
      final done = own.where((t) => t['status'] == 'done').length;
      final nowDate = DateTime.now();
      double weightedScoreSum = 0;
      int totalWeight = 0;
      for (final t in own) {
        final progressScore =
            (((t['progress'] as num?)?.toDouble() ?? 0).clamp(0, 100)) / 100;
        final weight = ((t['weight'] as num?)?.toInt() ?? 3).clamp(1, 5);
        final dueRaw = t['due_date']?.toString();
        final completedRaw = t['completed_at']?.toString();
        final dueDate = dueRaw == null || dueRaw.isEmpty
            ? null
            : DateTime.tryParse(dueRaw);
        final completedAt = completedRaw == null || completedRaw.isEmpty
            ? null
            : DateTime.tryParse(completedRaw);

        double timeScore = 0.8;
        if (dueDate != null) {
          final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
          final compare = completedAt == null
              ? DateTime(nowDate.year, nowDate.month, nowDate.day)
              : DateTime(completedAt.year, completedAt.month, completedAt.day);
          final diffDays = compare.difference(dueOnly).inDays;
          if (diffDays <= 0) {
            timeScore = 1.0;
          } else if (diffDays <= 2) {
            timeScore = 0.8;
          } else if (diffDays <= 5) {
            timeScore = 0.5;
          } else {
            timeScore = 0.2;
          }
        }

        final qaStatus = (t['qa_status'] ?? 'pending').toString();
        final qualityScore = switch (qaStatus) {
          'accepted' => 1.0,
          'rework' => 0.7,
          'rejected' => 0.3,
          _ => 0.85,
        };
        final taskScore =
            ((0.4 * progressScore) + (0.35 * timeScore) + (0.25 * qualityScore)) *
            100;
        weightedScoreSum += taskScore * weight;
        totalWeight += weight;
      }
      final avg = totalWeight == 0 ? 0.0 : (weightedScoreSum / totalWeight);
      return _MemberProductivity(
        employeeId: id,
        name: m['full_name']?.toString() ?? '-',
        totalTasks: total,
        doneTasks: done,
        productivityPercent: avg,
      );
    }).toList();

    final teamTotalTasks = taskRows.length;
    final teamDoneTasks = taskRows.where((t) => t['status'] == 'done').length;
    final teamPendingTasks = teamTotalTasks - teamDoneTasks;
    final now = DateTime.now();
    final thisWeekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final prevWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final prevWeekEnd = thisWeekStart.subtract(const Duration(days: 1));

    int thisWeekDone = 0;
    int prevWeekDone = 0;
    for (final t in taskRows) {
      if (t['status'] != 'done') continue;
      final updatedAt = DateTime.tryParse(t['updated_at']?.toString() ?? '');
      if (updatedAt == null) continue;
      final d = DateTime(updatedAt.year, updatedAt.month, updatedAt.day);
      if (!d.isBefore(thisWeekStart)) {
        thisWeekDone++;
      } else if (!d.isBefore(prevWeekStart) && !d.isAfter(prevWeekEnd)) {
        prevWeekDone++;
      }
    }

    final thisWeekPending = taskRows.where((t) {
      final status = (t['status'] ?? '').toString();
      if (status == 'done') return false;
      final createdAt = DateTime.tryParse(t['created_at']?.toString() ?? '');
      if (createdAt == null) return false;
      final d = DateTime(createdAt.year, createdAt.month, createdAt.day);
      return !d.isBefore(thisWeekStart);
    }).length;
    final prevWeekPending = taskRows.where((t) {
      final status = (t['status'] ?? '').toString();
      if (status == 'done') return false;
      final createdAt = DateTime.tryParse(t['created_at']?.toString() ?? '');
      if (createdAt == null) return false;
      final d = DateTime(createdAt.year, createdAt.month, createdAt.day);
      return !d.isBefore(prevWeekStart) && !d.isAfter(prevWeekEnd);
    }).length;

    double trendPercent(int current, int previous) {
      if (previous <= 0) return current > 0 ? 100 : 0;
      return ((current - previous) / previous) * 100;
    }
    final today = DateTime.now();
    final dueSoonEnd = today.add(const Duration(days: 7));
    int overdueTasks = 0;
    final dueSoonTasks = <Map<String, dynamic>>[];
    for (final task in taskRows) {
      if (task['status'] == 'done') continue;
      final dueRaw = task['due_date']?.toString();
      if (dueRaw == null || dueRaw.isEmpty) continue;
      final due = DateTime.tryParse(dueRaw);
      if (due == null) continue;
      final dueDate = DateTime(due.year, due.month, due.day);
      final dayStart = DateTime(today.year, today.month, today.day);
      if (dueDate.isBefore(dayStart)) {
        overdueTasks++;
      }
      if (!dueDate.isBefore(dayStart) &&
          !dueDate.isAfter(DateTime(dueSoonEnd.year, dueSoonEnd.month, dueSoonEnd.day))) {
        final employeeId = task['employee_id']?.toString() ?? '';
        dueSoonTasks.add({
          'title': task['title']?.toString() ?? '-',
          'due_date': dueRaw,
          'employee_name': memberNameById[employeeId] ?? '-',
        });
      }
    }
    dueSoonTasks.sort(
      (a, b) =>
          (a['due_date']?.toString() ?? '').compareTo(b['due_date']?.toString() ?? ''),
    );

    final sorted = [...metrics]
      ..sort((a, b) => b.productivityPercent.compareTo(a.productivityPercent));
    final topPerformers = sorted.take(5).toList();
    final needsAttention = [...metrics]
      ..sort((a, b) => a.productivityPercent.compareTo(b.productivityPercent));

    return _ManagerDashboardData(
      members: metrics,
      managedDepartmentNames: managedDepartmentNames,
      teamTotalTasks: teamTotalTasks,
      teamDoneTasks: teamDoneTasks,
      teamPendingTasks: teamPendingTasks,
      overdueTasks: overdueTasks,
      dueSoonTasks: dueSoonTasks.take(8).toList(),
      completionTrendPercent: trendPercent(thisWeekDone, prevWeekDone),
      pendingTrendPercent: trendPercent(thisWeekPending, prevWeekPending),
      topPerformers: topPerformers,
      needsAttention: needsAttention.take(5).toList(),
    );
  }

  Future<void> _appendTaskEvent({
    required String taskId,
    required String eventType,
    String? note,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) return;
      final me = await client
          .from('users')
          .select('tenant_id')
          .eq('id', uid)
          .single();
      await client.from('employee_task_events').insert({
        'tenant_id': me['tenant_id'].toString(),
        'task_id': taskId,
        'event_type': eventType,
        'event_note': note,
        'event_payload': payload ?? const {},
        'created_by_user_id': uid,
      });
    } catch (_) {}
  }

  Future<void> _showMemberTaskTimeline({
    required String employeeId,
    required String employeeName,
  }) async {
    final t = AppLocalizations.of(context)!;
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    final me = await client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();
    final tenantId = me['tenant_id'].toString();

    List<dynamic> tasksRes;
    try {
      tasksRes = await client
          .from('employee_tasks')
          .select(
            'id, title, status, progress, created_at, updated_at, due_date, '
            'assigned_by_employee_id, assignee_received_at, assignee_started_at',
          )
          .eq('tenant_id', tenantId)
          .eq('employee_id', employeeId)
          .order('updated_at', ascending: false)
          .limit(20);
    } catch (_) {
      tasksRes = await client
          .from('employee_tasks')
          .select(
            'id, title, status, progress, created_at, updated_at, due_date, '
            'assigned_by_employee_id',
          )
          .eq('tenant_id', tenantId)
          .eq('employee_id', employeeId)
          .order('updated_at', ascending: false)
          .limit(20);
    }
    final tasks = tasksRes.cast<Map<String, dynamic>>();

    final ids = tasks.map((e) => e['id'].toString()).toList();
    final eventsByTask = <String, List<Map<String, dynamic>>>{};
    if (ids.isNotEmpty) {
      try {
        final eventsRes = await client
            .from('employee_task_events')
            .select('task_id, event_type, event_note, created_at, event_payload')
            .eq('tenant_id', tenantId)
            .inFilter('task_id', ids)
            .order('created_at', ascending: false);
        for (final e in (eventsRes as List).cast<Map<String, dynamic>>()) {
          final taskId = e['task_id']?.toString() ?? '';
          if (taskId.isEmpty) continue;
          eventsByTask.putIfAbsent(taskId, () => []).add(e);
        }
      } catch (_) {}
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${t.taskTimeline}: $employeeName'),
        content: SizedBox(
          width: 780,
          height: 520,
          child: tasks.isEmpty
              ? Center(child: Text(t.noTasksAssignedYet))
              : ListView.separated(
                  itemBuilder: (context, i) {
                    final task = tasks[i];
                    final taskId = task['id']?.toString() ?? '';
                    final events = eventsByTask[taskId] ?? const [];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['title']?.toString() ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('${t.created}: ${_fmtTs(task['created_at'])}'),
                            Text('${t.assignedToEmployeeAt}: ${_fmtTs(task['created_at'])}'),
                            Text('${t.employeeReceivedAt}: ${_fmtTs(task['assignee_received_at'])}'),
                            Text('${t.employeeStartedAt}: ${_fmtTs(task['assignee_started_at'])}'),
                            Text('${t.lastUpdateAt}: ${_fmtTs(task['updated_at'])}'),
                            if (events.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                t.updatesTimeline,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              ...events.take(6).map(
                                (e) => Text(
                                  '- ${_taskEventLabel(t, (e['event_type'] ?? '').toString())} - ${_fmtTs(e['created_at'])}'
                                      '${(e['event_note'] ?? '').toString().trim().isEmpty ? '' : ' (${e['event_note']})'}',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemCount: tasks.length,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.close),
          ),
        ],
      ),
    );
  }

  String _taskEventLabel(AppLocalizations t, String raw) {
    switch (raw) {
      case 'assigned':
        return t.taskEventAssigned;
      case 'status_changed':
        return t.taskEventStatusChanged;
      case 'progress_updated':
        return t.taskEventProgressUpdated;
      default:
        return raw.isEmpty ? '-' : raw;
    }
  }

  String _fmtTs(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '');
    if (d == null) return '-';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }
}

class _ProductivityCircle extends StatelessWidget {
  const _ProductivityCircle({required this.value, required this.title});

  final double value;
  final String title;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 100).toDouble();
    final doneColor = v < 50
        ? const Color(0xFFFF4D4F)
        : v < 80
        ? const Color(0xFFFFC53D)
        : const Color(0xFF22C55E);
    final remainingColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.18);
    final surface = Theme.of(context).colorScheme.surface;

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: v / 100),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, progress, _) => SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        doneColor.withValues(alpha: 0.18),
                        doneColor.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 88,
                  height: 88,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    color: doneColor,
                    backgroundColor: remainingColor,
                  ),
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: surface,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: doneColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 130,
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _EmployeeDashboardData {
  const _EmployeeDashboardData({
    this.totalTasks = 0,
    this.pendingTasks = 0,
    this.doneTasks = 0,
    this.productivityPercent = 0,
    this.recentTasks = const [],
  });

  final int totalTasks;
  final int pendingTasks;
  final int doneTasks;
  final double productivityPercent;
  final List<Map<String, dynamic>> recentTasks;
}

class _ManagerDashboardData {
  const _ManagerDashboardData({
    this.members = const [],
    this.managedDepartmentNames = const [],
    this.teamTotalTasks = 0,
    this.teamDoneTasks = 0,
    this.teamPendingTasks = 0,
    this.overdueTasks = 0,
    this.dueSoonTasks = const [],
    this.completionTrendPercent = 0,
    this.pendingTrendPercent = 0,
    this.topPerformers = const [],
    this.needsAttention = const [],
  });
  final List<_MemberProductivity> members;
  final List<String> managedDepartmentNames;
  final int teamTotalTasks;
  final int teamDoneTasks;
  final int teamPendingTasks;
  final int overdueTasks;
  final List<Map<String, dynamic>> dueSoonTasks;
  final double completionTrendPercent;
  final double pendingTrendPercent;
  final List<_MemberProductivity> topPerformers;
  final List<_MemberProductivity> needsAttention;

  double get completionRate {
    if (teamTotalTasks == 0) return 0;
    return (teamDoneTasks / teamTotalTasks) * 100;
  }

  String? get primaryManagedDepartmentName {
    if (managedDepartmentNames.isEmpty) return null;
    return managedDepartmentNames.first;
  }
}

class _MemberProductivity {
  const _MemberProductivity({
    required this.employeeId,
    required this.name,
    required this.totalTasks,
    required this.doneTasks,
    required this.productivityPercent,
  });

  final String employeeId;
  final String name;
  final int totalTasks;
  final int doneTasks;
  final double productivityPercent;
}

class _SmallStatCard extends StatelessWidget {
  const _SmallStatCard({
    required this.title,
    required this.value,
    this.trendPercent,
    this.invertTrend = false,
  });

  final String title;
  final String value;
  final double? trendPercent;
  final bool invertTrend;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              if (trendPercent != null) ...[
                const SizedBox(height: 6),
                _TrendBadge(percent: trendPercent!, invert: invertTrend),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.percent, required this.invert});

  final double percent;
  final bool invert;

  @override
  Widget build(BuildContext context) {
    final up = percent >= 0;
    final good = invert ? !up : up;
    final color = good ? Colors.green : Colors.red;
    return Row(
      children: [
        Icon(
          up ? Icons.arrow_upward : Icons.arrow_downward,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '${percent.abs().toStringAsFixed(1)}%',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PerformanceListCard extends StatelessWidget {
  const _PerformanceListCard({
    required this.title,
    required this.emptyText,
    required this.members,
    required this.color,
  });

  final String title;
  final String emptyText;
  final List<_MemberProductivity> members;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (members.isEmpty)
                Text(emptyText)
              else
                ...members.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(m.name, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${m.productivityPercent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
