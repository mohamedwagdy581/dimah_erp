String payrollApprovalError(Object error, {required bool isArabic}) {
  final message = error.toString();
  String text(String ar, String en) => isArabic ? ar : en;
  if (message.contains('PAYROLL_FINANCE_REVIEWER_NOT_LINKED') ||
      message.contains('PAYROLL_FINANCE_MANAGER_NOT_LINKED')) {
    return text(
      'تعذر إنشاء مهمة الصرف: تأكد أن حساب مدير المالية نشط ومربوط بملف موظف نشط في نفس الشركة. لم يتم اعتماد المسير.',
      'Cannot create the payment task. The finance manager needs an active account linked to an active employee in this company. Payroll was not approved.',
    );
  }
  if (message.contains('PAYROLL_FINANCE_MANAGER_AMBIGUOUS')) {
    return text(
      'يوجد أكثر من مدير مالية وهذا الطلب القديم لا يحدد من راجعه. راجع إسناد الطلب قبل الاعتماد.',
      'Multiple finance managers found. This legacy request has no reviewer; review its assignment before approval.',
    );
  }
  if (message.contains('PAYROLL_ADMIN_STATE_CHANGED') ||
      message.contains('PAYROLL_ADMIN_APPROVAL_CONFLICT')) {
    return text(
      'حالة المسير أو طلب الموافقة تغيرت. حدّث الصفحة وراجع مرحلة الاعتماد الحالية.',
      'Payroll or approval state changed. Refresh and check the current approval stage.',
    );
  }
  if (message.contains('PAYROLL_ADMIN_TOTALS_MISMATCH')) {
    return text(
      'تفاصيل الرواتب لا تطابق إجمالي المسير. راجع البنود قبل الاعتماد.',
      'Payroll items do not match the totals. Review the items before approval.',
    );
  }
  if (message.contains('admin_approve_payroll') &&
      (message.contains('PGRST202') || message.contains('42883'))) {
    return text(
      'خدمة الاعتماد النهائي تحتاج تحديثًا في قاعدة البيانات. شغّل ملف install_admin_payroll_approval.sql ثم حاول مجددًا.',
      'Install install_admin_payroll_approval.sql in the database, then retry final approval.',
    );
  }
  return text(
    'تعذر تأكيد الاعتماد النهائي. حدّث الصفحة للتحقق من حالة المسير قبل إعادة المحاولة.',
    'Could not confirm final approval. Refresh to check payroll state before retrying.',
  );
}
