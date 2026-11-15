String? hrFormSubmissionError(
  String template,
  Map<String, dynamic> data,
  bool ar,
) {
  String tr(String a, String e) => ar ? a : e;
  if (data['employee_id'] == null) {
    return tr('اختر الموظف أولًا.', 'Select an employee first.');
  }
  if (template == 'leave-application-prototype') {
    final start = DateTime.tryParse(data['from']?.toString() ?? '');
    final end = DateTime.tryParse(data['to']?.toString() ?? '');
    if (start == null || end == null) {
      return tr(
        'حدد بداية ونهاية الإجازة.',
        'Select leave start and end dates.',
      );
    }
    if (end.isBefore(start)) {
      return tr(
        'نهاية الإجازة يجب أن تكون بعد البداية أو في نفس اليوم.',
        'Leave end must be on or after its start.',
      );
    }
    if (start.year != end.year) {
      return tr(
        'قسّم الإجازة الممتدة بين عامين إلى طلبين.',
        'Split cross-year leave into two requests.',
      );
    }
  } else if (template == 'early-exit') {
    final f = data['fields'] as Map? ?? {};
    final date = DateTime.tryParse(
      (f['date']?.toString() ?? '').replaceAll('/', '-'),
    );
    final from = f['departure']?.toString() ?? '';
    final to = f['shiftEnd']?.toString() ?? '';
    final time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
    if (date == null || !time.hasMatch(from) || !time.hasMatch(to)) {
      return tr(
        'حدد تاريخ الخروج والوقت المطلوب ونهاية الدوام.',
        'Select exit date, departure time and shift end.',
      );
    }
    if (from.compareTo(to) >= 0) {
      return tr(
        'وقت الخروج يجب أن يسبق نهاية الدوام في نفس اليوم.',
        'Departure must be before shift end on the same day.',
      );
    }
    if ((f['reason']?.toString() ?? '').trim().isEmpty) {
      return tr('اكتب سبب الخروج المبكر.', 'Enter the reason for early exit.');
    }
  } else {
    return tr(
      'الإرسال غير متاح لهذا النموذج حاليًا.',
      'Submission is not enabled for this form yet.',
    );
  }
  return null;
}

String hrFormStatusLabel(String status, bool ar) => switch (status) {
  'pending' => ar ? 'بانتظار الاعتماد' : 'Pending approval',
  'approved' => ar ? 'معتمد' : 'Approved',
  'rejected' => ar ? 'مرفوض' : 'Rejected',
  _ => ar ? 'مسودة' : 'Draft',
};
String hrFormApproverLabel(String? role, bool ar) => switch (role) {
  'manager' || 'direct_manager' => ar ? 'المدير المباشر' : 'Direct manager',
  'finance_manager' => ar ? 'مدير المالية' : 'Finance manager',
  'hr' => ar ? 'الموارد البشرية' : 'HR',
  'admin' => ar ? 'الإدارة' : 'Admin',
  _ => role ?? '',
};
String hrFormEventLabel(String action, bool ar) => switch (action) {
  'created' => ar ? 'إنشاء المسودة' : 'Draft created',
  'submitted' => ar ? 'إرسال للاعتماد' : 'Submitted for approval',
  'reviewed' => ar ? 'اعتماد مرحلة المراجعة' : 'Review stage approved',
  'approved' => ar ? 'اعتماد نهائي' : 'Final approval',
  'rejected' => ar ? 'رفض الطلب' : 'Request rejected',
  _ => ar ? 'حفظ التعديلات' : 'Changes saved',
};
String hrFormWorkflowError(String message, bool ar) {
  if (message.contains('No eligible')) {
    return ar
        ? 'لا يوجد حساب مراجعة نشط مناسب. راجع ربط المدير وحسابات الموارد البشرية والإدارة.'
        : 'No eligible active reviewer. Check manager links and HR/Admin accounts.';
  }
  if (message.contains('Insufficient leave balance')) {
    return ar
        ? 'رصيد الإجازة غير كافٍ لهذا الطلب.'
        : 'Insufficient leave balance for this request.';
  }
  if (message.contains('not yet eligible')) {
    return ar
        ? 'الموظف لم يستحق الإجازة السنوية لهذا العام بعد.'
        : 'The employee is not yet eligible for annual leave in this year.';
  }
  if (message.contains('Draft changed')) {
    return ar
        ? 'تم تعديل المسودة من جلسة أخرى. افتح أحدث نسخة من السجل.'
        : 'The draft changed in another session. Reopen the latest version.';
  }
  if (message.contains('active employee')) {
    return ar
        ? 'اختر موظفًا نشطًا للإرسال.'
        : 'Select an active employee for submission.';
  }
  return ar
      ? 'تعذر الإرسال. المسودة محفوظة؛ تحقق من الاتصال وتفعيل خدمة الطلبات ثم حاول مجددًا.'
      : 'Submission failed. The draft is saved; check connection and that request submission is enabled, then retry.';
}
