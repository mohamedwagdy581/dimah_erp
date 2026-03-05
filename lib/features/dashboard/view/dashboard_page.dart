import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        if (user.role == 'manager' && user.employeeId != null) {
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
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Text(
                  t.hrDashboard,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
                  title: t.activeEmployeesKpi,
                  value: '${data.activeEmployees}',
                  subtitle: t.currentHeadcount,
                  icon: Icons.badge_outlined,
                ),
                _KpiCard(
                  title: t.pendingApprovalsKpi,
                  value: '${data.pendingApprovals}',
                  subtitle: t.waitingHrAction,
                  icon: Icons.approval_outlined,
                ),
                _KpiCard(
                  title: t.onLeaveTodayKpi,
                  value: '${data.onLeaveToday}',
                  subtitle: t.approvedLeaveToday,
                  icon: Icons.event_busy_outlined,
                ),
                _KpiCard(
                  title: t.noCheckInTodayKpi,
                  value: '${data.missingCheckInToday}',
                  subtitle: t.activeStaffNotCheckedIn,
                  icon: Icons.login_outlined,
                ),
                _KpiCard(
                  title: t.leavesThisMonthKpi,
                  value: '${data.leavesThisMonth}',
                  subtitle: t.approvedLeaveRequests,
                  icon: Icons.date_range_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.pendingRequestsTop10,
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          if (data.pendingItems.isEmpty)
                            Text(t.noPendingRequests)
                          else
                            ...data.pendingItems.map(
                              (r) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.pending_actions),
                                title: Text(r.employeeName),
                                subtitle: Text(
                                  '${r.requestType} | ${_dateOnly(r.createdAt)}',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.expiringDocuments30Days,
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          if (data.expiringDocuments.isEmpty)
                            Text(t.noDocumentExpiries30Days)
                          else
                            ...data.expiringDocuments.map(
                              (d) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.description_outlined),
                                title: Text(
                                  d['employee_name']?.toString() ?? '-',
                                ),
                                subtitle: Text(
                                  '${d['doc_type'] ?? t.documentLabel} | ${t.expires}: ${d['expires_at'] ?? '-'}',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
        .select('employee_id, check_in')
        .eq('tenant_id', tenantId)
        .eq('date', todayStr);
    final attendedEmployeeIds = (todayAttendanceRes as List)
        .where((r) => r['check_in'] != null)
        .map((r) => r['employee_id'].toString())
        .toSet();
    final missingCheckInToday = activeEmployees - attendedEmployeeIds.length;

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
    try {
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
        return {
          'employee_name': employee is Map
              ? (employee['full_name'] ?? '-').toString()
              : '-',
          'doc_type': e['doc_type']?.toString() ?? '-',
          'expires_at': e['expires_at']?.toString() ?? '-',
        };
      }).toList();
    } catch (_) {
      expiringDocuments = const [];
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

    return _HrDashboardData(
      activeEmployees: activeEmployees,
      pendingApprovals: pendingApprovals,
      onLeaveToday: onLeaveToday,
      missingCheckInToday: missingCheckInToday < 0 ? 0 : missingCheckInToday,
      leavesThisMonth: leavesThisMonth,
      pendingItems: pendingItems,
      expiringDocuments: expiringDocuments,
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
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
    this.pendingItems = const [],
    this.expiringDocuments = const [],
  });

  final int activeEmployees;
  final int pendingApprovals;
  final int onLeaveToday;
  final int missingCheckInToday;
  final int leavesThisMonth;
  final List<_PendingItem> pendingItems;
  final List<Map<String, dynamic>> expiringDocuments;
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
  String? _employeeId;
  bool _saving = false;
  DateTime? _dueDate;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return FutureBuilder<_ManagerDashboardData>(
      future: _loadData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? const _ManagerDashboardData();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              t.teamProductivity,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: data.members.map((m) {
                return SizedBox(
                  width: 220,
                  child: Card(
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
                );
              }).toList(),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _employeeId,
                      decoration: InputDecoration(
                        labelText: t.employee,
                        border: OutlineInputBorder(),
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
                        border: OutlineInputBorder(),
                      ),
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
      await client.from('employee_tasks').insert({
        'tenant_id': tenantId,
        'employee_id': _employeeId,
        'assigned_by_employee_id': widget.managerEmployeeId,
        'title': title,
        'due_date': _dueDate == null
            ? null
            : DateTime(
                _dueDate!.year,
                _dueDate!.month,
                _dueDate!.day,
              ).toIso8601String().split('T').first,
        'status': 'todo',
        'progress': 0,
      });
      if (!mounted) return;
      _title.clear();
      _dueDate = null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.taskAssigned)));
      setState(() => _saving = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.assignFailed(e.toString()))));
    }
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
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('manager_id', widget.managerEmployeeId);
    final managedDepartmentIds = (managedDepartmentsRes as List)
        .map((e) => e['id'].toString())
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
        .select('employee_id, status, progress')
        .eq('tenant_id', tenantId)
        .inFilter('employee_id', ids);
    final taskRows = (tasks as List).cast<Map<String, dynamic>>();

    final metrics = members.map((m) {
      final id = m['id'].toString();
      final own = taskRows.where((t) => t['employee_id'].toString() == id);
      final total = own.length;
      final done = own.where((t) => t['status'] == 'done').length;
      final avg = total == 0
          ? 0.0
          : own.fold<double>(
                  0,
                  (sum, t) =>
                      sum + ((t['progress'] as num?)?.toDouble() ?? 0),
                ) /
                total;
      return _MemberProductivity(
        employeeId: id,
        name: m['full_name']?.toString() ?? '-',
        totalTasks: total,
        doneTasks: done,
        productivityPercent: avg,
      );
    }).toList();

    return _ManagerDashboardData(members: metrics);
  }
}

class _ProductivityCircle extends StatelessWidget {
  const _ProductivityCircle({required this.value, required this.title});

  final double value;
  final String title;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 100).toDouble();
    final color = v >= 80
        ? Colors.green
        : v >= 50
            ? Colors.orange
            : Colors.red;
    return Column(
      children: [
        SizedBox(
          width: 92,
          height: 92,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: v / 100,
                strokeWidth: 9,
                color: color,
                backgroundColor: Colors.grey.shade300,
              ),
              Text(
                '${v.toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
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
  const _ManagerDashboardData({this.members = const []});
  final List<_MemberProductivity> members;
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
