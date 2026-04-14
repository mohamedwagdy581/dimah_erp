import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/session/app_user.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/notification_item.dart';

class NotificationsRepo {
  NotificationsRepo(this._client);

  final SupabaseClient _client;

  Future<List<NotificationItem>> fetch(AppUser user, AppLocalizations t) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];
    final me = await _client.from('users').select('tenant_id').eq('id', uid).single();
    final tenantId = me['tenant_id'].toString();

    if (user.role == 'employee' && user.employeeId != null) {
      return _fetchEmployeeNotifications(tenantId, user.employeeId!, t);
    }
    if (user.role == 'manager' || user.role == 'direct_manager') {
      return _fetchManagerNotifications(tenantId, user.employeeId, t);
    }
    if (user.role == 'finance_manager') {
      return _fetchFinanceManagerNotifications(tenantId, user.employeeId, t);
    }
    if (user.role == 'accountant') {
      return _fetchAccountantNotifications(tenantId, user.employeeId, t);
    }
    if (user.role == 'hr' || user.role == 'admin') {
      return _fetchBackofficeNotifications(tenantId, user.role, t);
    }
    return const [];
  }

  Future<List<NotificationItem>> _fetchEmployeeNotifications(
    String tenantId,
    String employeeId,
    AppLocalizations t,
  ) async {
    final rows = await _client
        .from('employee_tasks')
        .select(
          'title, due_date, qa_status, employee_review_status, manager_review_note, updated_at, status',
        )
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .order('updated_at', ascending: false)
        .limit(30);
    final now = DateTime.now();
    final items = <NotificationItem>[];
    for (final row in (rows as List).cast<Map<String, dynamic>>()) {
      final title = row['title']?.toString() ?? '-';
      final updatedAt = _dateLabel(row['updated_at']?.toString());
      final managerNote = row['manager_review_note']?.toString() ?? updatedAt;
      final reviewStatus = (row['employee_review_status'] ?? 'none').toString();
      final qaStatus = (row['qa_status'] ?? 'pending').toString();
      if (reviewStatus == 'approved') {
        items.add(_item(t.reviewApproved, '$title - $updatedAt', Icons.rule_folder_outlined, Colors.blue, AppRoutes.myPortal));
      } else if (reviewStatus == 'rejected') {
        items.add(_item(t.reviewRejected, '$title - $updatedAt', Icons.reply_outlined, Colors.orange, AppRoutes.myPortal));
      }
      if (qaStatus == 'accepted') {
        items.add(_item(t.qaAccepted, '$title - $updatedAt', Icons.verified_outlined, Colors.green, AppRoutes.myPortal));
      } else if (qaStatus == 'rework') {
        items.add(_item(t.qaRework, '$title - $managerNote', Icons.restart_alt_outlined, Colors.orange, AppRoutes.myPortal));
      } else if (qaStatus == 'rejected') {
        items.add(_item(t.qaRejected, '$title - $managerNote', Icons.block_outlined, Colors.red, AppRoutes.myPortal));
      }
      final dueDate = DateTime.tryParse(row['due_date']?.toString() ?? '');
      if ((row['status'] ?? '') != 'done' && dueDate != null) {
        final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
        final todayOnly = DateTime(now.year, now.month, now.day);
        if (!dueOnly.isBefore(todayOnly) && !dueOnly.isAfter(todayOnly.add(const Duration(days: 2)))) {
          items.add(_item(t.taskDueSoon, '$title - ${_dateLabel(row['due_date']?.toString())}', Icons.schedule_outlined, Colors.amber, AppRoutes.myPortal));
        }
      }
    }
    return items.take(20).toList();
  }

  Future<List<NotificationItem>> _fetchManagerNotifications(
    String tenantId,
    String? employeeId,
    AppLocalizations t,
  ) async {
    if (employeeId == null) return const [];
    final deptIdsRes = await _client.from('departments').select('id').eq('tenant_id', tenantId).eq('manager_id', employeeId);
    final deptIds = (deptIdsRes as List).map((e) => e['id'].toString()).toList();
    if (deptIds.isEmpty) return const [];
    final employeeRows = await _client
        .from('employees')
        .select('id, full_name')
        .eq('tenant_id', tenantId)
        .inFilter('department_id', deptIds)
        .eq('status', 'active');
    final employeeMap = {
      for (final row in (employeeRows as List).cast<Map<String, dynamic>>())
        row['id'].toString(): (row['full_name'] ?? '-').toString(),
    };
    if (employeeMap.isEmpty) return const [];
    final taskRows = await _client
        .from('employee_tasks')
        .select('title, employee_id, employee_review_status, employee_review_requested_at, status, qa_status, completed_at')
        .eq('tenant_id', tenantId)
        .inFilter('employee_id', employeeMap.keys.toList());
    final items = <NotificationItem>[];
    for (final row in (taskRows as List).cast<Map<String, dynamic>>()) {
      final employeeName = employeeMap[row['employee_id']?.toString() ?? ''] ?? '-';
      final title = row['title'] ?? '-';
      if ((row['employee_review_status'] ?? 'none') == 'pending') {
        items.add(_item(t.pendingTaskReviews, '$title - $employeeName - ${_dateLabel(row['employee_review_requested_at']?.toString())}', Icons.rate_review_outlined, Colors.orange, AppRoutes.dashboard));
      }
      if ((row['status'] ?? '') == 'done' && (row['qa_status'] ?? 'pending') == 'pending') {
        items.add(_item(t.pendingTaskQa, '$title - $employeeName - ${_dateLabel(row['completed_at']?.toString())}', Icons.verified_outlined, Colors.blue, AppRoutes.dashboard));
      }
    }
    return items.take(20).toList();
  }

  Future<List<NotificationItem>> _fetchFinanceManagerNotifications(
    String tenantId,
    String? employeeId,
    AppLocalizations t,
  ) async {
    final items = <NotificationItem>[];
    final payrollRows = await _client
        .from('payroll_runs')
        .select('period_start, period_end, status, disbursement_status, created_at')
        .eq('tenant_id', tenantId)
        .or('status.eq.pending_finance_manager,and(status.eq.approved,disbursement_status.eq.assigned_to_finance_manager)')
        .order('created_at', ascending: false)
        .limit(20);

    for (final row in (payrollRows as List).cast<Map<String, dynamic>>()) {
      final period = _payrollPeriodLabel(
        row['period_start']?.toString(),
        row['period_end']?.toString(),
      );
      final status = (row['status'] ?? '').toString();
      final disbursementStatus = (row['disbursement_status'] ?? '').toString();
      if (status == 'pending_finance_manager') {
        items.add(
          _item(
            _txt(t, 'مسير رواتب بانتظار اعتمادك', 'Payroll waiting for your approval'),
            period,
            Icons.request_page_outlined,
            Colors.orange,
            AppRoutes.payroll,
          ),
        );
      }
      if (status == 'approved' && disbursementStatus == 'assigned_to_finance_manager') {
        items.add(
          _item(
            _txt(t, 'تم إنشاء مهمة صرف الرواتب', 'Payroll disbursement task created'),
            period,
            Icons.payments_outlined,
            Colors.deepPurple,
            AppRoutes.payroll,
          ),
        );
      }
    }

    if (employeeId != null && employeeId.isNotEmpty) {
      final taskRows = await _client
          .from('employee_tasks')
          .select('title, updated_at, task_type')
          .eq('tenant_id', tenantId)
          .eq('employee_id', employeeId)
          .eq('task_type', 'payroll')
          .order('updated_at', ascending: false)
          .limit(10);
      for (final row in (taskRows as List).cast<Map<String, dynamic>>()) {
        items.add(
          _item(
            _txt(t, 'تحديث على مهمة رواتب', 'Payroll task update'),
            '${row['title'] ?? '-'} - ${_dateLabel(row['updated_at']?.toString())}',
            Icons.assignment_outlined,
            Colors.blue,
            AppRoutes.myPortal,
          ),
        );
      }
    }

    return items.take(20).toList();
  }

  Future<List<NotificationItem>> _fetchAccountantNotifications(
    String tenantId,
    String? employeeId,
    AppLocalizations t,
  ) async {
    if (employeeId == null || employeeId.isEmpty) return const [];
    final taskRows = await _client
        .from('employee_tasks')
        .select('title, updated_at, task_type, status')
        .eq('tenant_id', tenantId)
        .eq('employee_id', employeeId)
        .eq('task_type', 'payroll')
        .order('updated_at', ascending: false)
        .limit(20);

    return (taskRows as List)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => _item(
            _txt(t, 'تم إسناد مهمة رواتب لك', 'Payroll task assigned'),
            '${row['title'] ?? '-'} - ${_dateLabel(row['updated_at']?.toString())}',
            Icons.payments_outlined,
            Colors.blue,
            AppRoutes.myPortal,
          ),
        )
        .toList();
  }

  Future<List<NotificationItem>> _fetchBackofficeNotifications(
    String tenantId,
    String role,
    AppLocalizations t,
  ) async {
    final items = <NotificationItem>[];
    final approvals = await _client
        .from('approval_requests')
        .select('request_type, created_at, status')
        .eq('tenant_id', tenantId)
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(12);
    items.addAll(
      (approvals as List)
          .cast<Map<String, dynamic>>()
          .map(
            (row) => _item(
              t.pendingApprovalsKpi,
              '${row['request_type'] ?? '-'} - ${_dateLabel(row['created_at']?.toString())}',
              Icons.approval_outlined,
              Colors.orange,
              AppRoutes.approvals,
            ),
          ),
    );

    if (role == 'hr') {
      final payrollRows = await _client
          .from('payroll_runs')
          .select('period_start, period_end, status, reject_reason, created_at')
          .eq('tenant_id', tenantId)
          .inFilter('status', ['rejected_by_finance_manager', 'rejected_by_admin'])
          .order('created_at', ascending: false)
          .limit(10);
      for (final row in (payrollRows as List).cast<Map<String, dynamic>>()) {
        items.add(
          _item(
            _txt(t, 'تمت إعادة مسير الرواتب للمراجعة', 'Payroll returned for revision'),
            '${_payrollPeriodLabel(row['period_start']?.toString(), row['period_end']?.toString())} - ${(row['reject_reason'] ?? '-').toString()}',
            Icons.reply_outlined,
            Colors.red,
            AppRoutes.payroll,
          ),
        );
      }
    }

    if (role == 'admin') {
      final payrollRows = await _client
          .from('payroll_runs')
          .select('period_start, period_end, status, created_at')
          .eq('tenant_id', tenantId)
          .eq('status', 'pending_admin_approval')
          .order('created_at', ascending: false)
          .limit(10);
      for (final row in (payrollRows as List).cast<Map<String, dynamic>>()) {
        items.add(
          _item(
            _txt(t, 'مسير رواتب بانتظار الاعتماد النهائي', 'Payroll awaiting final approval'),
            _payrollPeriodLabel(
              row['period_start']?.toString(),
              row['period_end']?.toString(),
            ),
            Icons.verified_user_outlined,
            Colors.indigo,
            AppRoutes.payroll,
          ),
        );
      }
    }

    return items.take(20).toList();
  }

  NotificationItem _item(String title, String subtitle, IconData icon, Color color, String route) {
    return NotificationItem(title: title, subtitle: subtitle, icon: icon, color: color, route: route);
  }

  static String _dateLabel(String? raw) {
    final date = DateTime.tryParse(raw ?? '');
    if (date == null) return '-';
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _payrollPeriodLabel(String? startRaw, String? endRaw) {
    final start = _dateLabel(startRaw);
    final end = _dateLabel(endRaw);
    return '$start -> $end';
  }

  static String _txt(AppLocalizations t, String ar, String en) {
    return t.localeName.startsWith('ar') ? ar : en;
  }
}
