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
    if (user.role == 'hr' || user.role == 'admin') {
      return _fetchHrNotifications(tenantId, t);
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

  Future<List<NotificationItem>> _fetchHrNotifications(String tenantId, AppLocalizations t) async {
    final approvals = await _client
        .from('approval_requests')
        .select('request_type, created_at, status')
        .eq('tenant_id', tenantId)
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(12);
    return (approvals as List)
        .cast<Map<String, dynamic>>()
        .map((row) => _item(t.pendingApprovalsKpi, '${row['request_type'] ?? '-'} - ${_dateLabel(row['created_at']?.toString())}', Icons.approval_outlined, Colors.orange, AppRoutes.approvals))
        .toList();
  }

  NotificationItem _item(String title, String subtitle, IconData icon, Color color, String route) {
    return NotificationItem(title: title, subtitle: subtitle, icon: icon, color: color, route: route);
  }

  static String _dateLabel(String? raw) {
    final date = DateTime.tryParse(raw ?? '');
    if (date == null) return '-';
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
