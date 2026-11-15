part of 'manager_requests_page.dart';

extension _ManagerRequestDetails on _ManagerRequestsViewState {
  Widget _details(Map<String, dynamic> row, ManagerRequestsState state) {
    final r = ApprovalRequest.fromMap(row);
    final p = r.payload ?? {};
    final leave = r.requestType == 'leave';
    final allowed = managerCanDecideRequest(row, state.data.role);
    final busy = state.saving || state.loading;
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final t = AppLocalizations.of(context)!;
    String type() => switch (p['type']) {
      'annual' => t.leaveTypeAnnual,
      'sick' => t.leaveTypeSick,
      'unpaid' => t.leaveTypeUnpaid,
      'other' => t.leaveTypeOther,
      _ => '—',
    };
    Widget section(String title, Widget child) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: EmployeeTheme.primary.withValues(alpha: .13)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 9),
          child,
        ],
      ),
    );
    Widget informationTable(
      List<({String label, String value, bool numeric})> fields,
    ) => LayoutBuilder(
      builder: (_, box) {
        final columns = box.maxWidth < 460
            ? (fields.length.isEven ? 2 : 1)
            : fields.length;
        Widget cell(
          String text, {
          bool heading = false,
          bool numeric = false,
        }) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          child: Text(
            text,
            textAlign: TextAlign.center,
            textDirection: numeric ? TextDirection.ltr : null,
            style: TextStyle(
              fontSize: heading ? 13 : 15,
              height: 1.5,
              color: heading ? color : null,
              fontWeight: heading ? FontWeight.w500 : FontWeight.w600,
            ),
          ),
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder.all(
              color: EmployeeTheme.primary.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(7),
            ),
            children: [
              for (var start = 0; start < fields.length; start += columns) ...[
                TableRow(
                  decoration: BoxDecoration(
                    color: EmployeeTheme.primary.withValues(alpha: .055),
                  ),
                  children: [
                    for (var i = 0; i < columns; i++)
                      cell(
                        start + i < fields.length
                            ? fields[start + i].label
                            : '—',
                        heading: true,
                      ),
                  ],
                ),
                TableRow(
                  children: [
                    for (var i = 0; i < columns; i++)
                      cell(
                        start + i < fields.length
                            ? fields[start + i].value
                            : '—',
                        numeric:
                            start + i < fields.length &&
                            fields[start + i].numeric,
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
    String proposedTime(dynamic raw) {
      final date = DateTime.tryParse('$raw')?.toLocal();
      if (date == null) return '—';
      final day = historyDate(date);
      return day == historyDate(p['date'])
          ? historyTime(date)
          : '${historyTime(date)}\n$day';
    }

    String duration() {
      final start = DateTime.tryParse('${p['start_date']}');
      final end = DateTime.tryParse('${p['end_date']}');
      if (start == null || end == null || end.isBefore(start)) return '—';
      final days =
          DateTime.utc(end.year, end.month, end.day)
              .difference(DateTime.utc(start.year, start.month, start.day))
              .inDays +
          1;
      return '$days ${tr('أيام', 'days')}';
    }

    Widget event(String label, Object? timestamp, Color marker) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: marker, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          if (timestamp != null)
            Text(
              '${historyDate(DateTime.tryParse('$timestamp')?.toLocal())}\n${DateTime.tryParse('$timestamp') == null ? '—' : historyTime(DateTime.parse('$timestamp').toLocal())}',
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.4, color: color),
            ),
        ],
      ),
    );
    final url = p['file_url']?.toString().trim() ?? '';
    final uri = Uri.tryParse(url);
    final filename =
        p['file_name']?.toString() ??
        (uri?.pathSegments.isNotEmpty == true
            ? uri!.pathSegments.last
            : tr('مرفق الطلب', 'Request attachment'));
    final approver = switch (r.currentApproverRole) {
      'manager' || 'direct_manager' => tr('المدير المباشر', 'Direct manager'),
      'hr' => tr('الموارد البشرية', 'HR'),
      'admin' => tr('مدير النظام', 'Administrator'),
      _ => r.currentApproverRole ?? '—',
    };
    return panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EmployeeTheme.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  leave ? Icons.calendar_month_rounded : Icons.schedule,
                  color: EmployeeTheme.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave
                          ? '${tr('طلب إجازة', 'Leave request:')} ${type()}'
                          : historyType(t, r.requestType, ar),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    Text(
                      tr(
                        'طلب مقدم من أحد أعضاء فريقك',
                        'Submitted by a member of your team',
                      ),
                      style: TextStyle(color: color, fontSize: 13),
                    ),
                  ],
                ),
              ),
              statusBadge(r),
            ],
          ),
          const SizedBox(height: 16),
          section(
            tr('موظف الطلب', 'Employee'),
            Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: EmployeeTheme.primary.withValues(
                        alpha: .16,
                      ),
                      child: Text(
                        r.employeeName
                            .split(' ')
                            .where((s) => s.isNotEmpty)
                            .take(2)
                            .map((s) => s.characters.first)
                            .join(),
                        style: const TextStyle(
                          color: EmployeeTheme.dark,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.employeeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${row['job_title'] ?? tr('الوظيفة غير محددة', 'Job title not specified')}',
                            style: TextStyle(fontSize: 13, color: color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                informationTable(
                  leave
                      ? [
                          (
                            label: tr('نوع الإجازة', 'Leave type'),
                            value: type(),
                            numeric: false,
                          ),
                          (
                            label: tr('تاريخ البدء', 'Start date'),
                            value: historyDate(p['start_date']),
                            numeric: true,
                          ),
                          (
                            label: tr('تاريخ الانتهاء', 'End date'),
                            value: historyDate(p['end_date']),
                            numeric: true,
                          ),
                          (
                            label: tr('المدة', 'Duration'),
                            value: duration(),
                            numeric: false,
                          ),
                        ]
                      : r.requestType == 'attendance_correction'
                      ? [
                          (
                            label: tr('تاريخ الحضور', 'Attendance date'),
                            value: historyDate(p['date']),
                            numeric: true,
                          ),
                          (
                            label: tr('الحضور المقترح', 'Proposed check-in'),
                            value: proposedTime(p['proposed_check_in']),
                            numeric: true,
                          ),
                          (
                            label: tr('الانصراف المقترح', 'Proposed check-out'),
                            value: proposedTime(p['proposed_check_out']),
                            numeric: true,
                          ),
                        ]
                      : [
                          (
                            label: tr('نوع الطلب', 'Request type'),
                            value: historyType(t, r.requestType, ar),
                            numeric: false,
                          ),
                          (
                            label: tr('تاريخ التقديم', 'Submission date'),
                            value: historyDate(r.createdAt.toLocal()),
                            numeric: true,
                          ),
                        ],
                ),
              ],
            ),
          ),
          section(
            tr('سبب الطلب', 'Request reason'),
            Text(
              '${p['reason'] ?? p['notes'] ?? '—'}',
              style: const TextStyle(fontSize: 14, height: 1.7),
            ),
          ),
          if (leave || url.isNotEmpty)
            section(
              tr('مرفق الطلب', 'Request attachment'),
              url.isEmpty
                  ? Text(
                      row['attachment_unavailable'] == true
                          ? tr(
                              'تعذر الوصول لبيانات المرفق. حدّث الطلب أو راجع الموارد البشرية.',
                              'Attachment details could not be accessed. Refresh or contact HR.',
                            )
                          : tr(
                              'لم يُرفق ملف بهذا الطلب.',
                              'No file was attached to this request.',
                            ),
                      style: TextStyle(color: color, fontSize: 13),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filename,
                          style: TextStyle(color: color, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          key: const ValueKey('team-request-attachment'),
                          onPressed: busy
                              ? null
                              : () async {
                                  try {
                                    if (uri == null ||
                                        ![
                                          'https',
                                          'http',
                                        ].contains(uri.scheme) ||
                                        !await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        )) {
                                      throw StateError(
                                        'Unable to open attachment',
                                      );
                                    }
                                  } catch (_) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            tr(
                                              'تعذر فتح المرفق',
                                              'Could not open attachment',
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: const Icon(Icons.file_open_outlined),
                          label: Text(tr('عرض المرفق', 'Open attachment')),
                        ),
                      ],
                    ),
            ),
          if (r.rejectReason?.isNotEmpty == true)
            section(
              tr('سبب الرفض', 'Rejection reason'),
              Text(
                r.rejectReason!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          section(
            tr('سجل الطلب', 'Request activity'),
            Column(
              children: [
                event(
                  tr('تم تقديم الطلب', 'Request submitted'),
                  r.createdAt,
                  EmployeeTheme.primary,
                ),
                if (row['approved_by_manager_at'] != null)
                  event(
                    tr('وافق المدير المباشر', 'Approved by direct manager'),
                    row['approved_by_manager_at'],
                    const Color(0xFF009879),
                  ),
                if (row['approved_by_hr_at'] != null)
                  event(
                    tr('وافقت الموارد البشرية', 'Approved by HR'),
                    row['approved_by_hr_at'],
                    const Color(0xFF009879),
                  ),
                if (row['approved_by_admin_at'] != null)
                  event(
                    tr('تم الاعتماد النهائي', 'Final approval'),
                    row['approved_by_admin_at'],
                    const Color(0xFF009879),
                  ),
                event(
                  r.status == 'pending'
                      ? '${tr('بانتظار', 'Awaiting')} $approver'
                      : historyStatus(t, r.status),
                  null,
                  historyStatusColor(r.status),
                ),
              ],
            ),
          ),
          if (allowed) ...[
            Text(
              tr(
                'سبب الرفض (إلزامي عند الرفض)',
                'Rejection reason (required to reject)',
              ),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('team-rejection-reason'),
              controller: _reason,
              enabled: !busy,
              maxLength: 300,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: tr('اكتب سبب الرفض هنا…', 'Enter rejection reason…'),
                errorText: _reasonRequired
                    ? tr(
                        'اكتب سبب الرفض أولًا',
                        'Enter a rejection reason first',
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: BorderSide(
                    color: EmployeeTheme.primary.withValues(alpha: .22),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: BorderSide(
                    color: EmployeeTheme.primary.withValues(alpha: .22),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('team-request-approve'),
                    onPressed: busy ? null : () => decide(row, true),
                    icon: const Icon(Icons.check, size: 20),
                    label: Text(tr('موافقة', 'Approve')),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('team-request-reject'),
                    onPressed: busy ? null : () => decide(row, false),
                    icon: const Icon(Icons.close, size: 20),
                    label: Text(tr('رفض', 'Reject')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withValues(alpha: .3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                'الموافقة تُحيل الطلب للموارد البشرية لاستكمال الاعتماد.',
                'Approval forwards the request to HR for further approval.',
              ),
              style: TextStyle(color: color, fontSize: 12, height: 1.5),
            ),
          ] else if (r.status == 'pending')
            Text(
              tr(
                'الطلب عند جهة المراجعة الحالية؛ لا يوجد إجراء مطلوب منك الآن.',
                'The request is with its current approver; no action is required from you.',
              ),
              style: TextStyle(fontSize: 13, height: 1.6, color: color),
            ),
        ],
      ),
    );
  }
}
