import 'package:material_ui/material_ui.dart';

import '../../services/hr_form_file_service.dart';
import '../../services/hr_portal_form_pdf.dart';
import '../hr_form_shell.dart';
import 'electronic_leave_request/electronic_leave_request_form_body.dart';
import 'electronic_leave_request/electronic_leave_request_form_controller.dart';

class ElectronicLeaveRequestFormEditor extends StatefulWidget {
  const ElectronicLeaveRequestFormEditor({super.key});

  @override
  State<ElectronicLeaveRequestFormEditor> createState() =>
      _ElectronicLeaveRequestFormEditorState();
}

class _ElectronicLeaveRequestFormEditorState
    extends State<ElectronicLeaveRequestFormEditor> {
  late final ElectronicLeaveRequestFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ElectronicLeaveRequestFormController()..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return HrFormShell(
      title: isArabic
          ? 'طلب إجازة إلكتروني'
          : 'Prototype - Electronic Leave Request',
      subtitle: isArabic
          ? 'نسخة تصميمية لتجربة الاتجاه البصري مع العميل'
          : 'A more digital leave request prototype to test visual direction with the client.',
      actions: const [],
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return ElectronicLeaveRequestFormBody(
              controller: _controller,
              isArabic: isArabic,
              readOnly: false,
              onClear: _controller.clear,
              onOpenPreview: () => _openDesignPreview(context, isArabic),
              onSelectEmployee:
                  _controller.loadingEmployees || _controller.fillingEmployee
                  ? null
                  : _handleSelectEmployee,
              onClearSelection: _controller.fillingEmployee
                  ? null
                  : _controller.clearFilledEmployee,
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleSelectEmployee(String employeeId) async {
    final ok = await _controller.fillFromEmployee(employeeId);
    if (!mounted || ok) return;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'تعذر تحميل بيانات الموظف للتعبئة التلقائية'
              : 'Failed to load employee details for auto-fill',
        ),
      ),
    );
  }

  Future<void> _openDesignPreview(BuildContext context, bool isArabic) async {
    String tr(String ar, String en) => isArabic ? ar : en;
    final draft = HrPortalFormDraft(
      isArabic: isArabic,
      isLeave: true,
      employeeName: _controller.employeeName.text,
      employeeNumber: _controller.employeeId.text,
      department: _controller.hrDepartment.text,
      jobTitle: _controller.position.text,
      date: _controller.applicationDate.text,
      agreed: false,
      fields: {
        tr('نوع الإجازة', 'Leave type'): _controller.leaveType.text,
        tr('من تاريخ', 'From'): _controller.fromDate.text,
        tr('إلى تاريخ', 'To'): _controller.toDate.text,
        tr('المدة', 'Duration'): _controller.days.text,
        tr('الموظف البديل', 'Replacement'): _controller.replacement.text,
        tr('سبب الإجازة / الملاحظات', 'Reason / notes'): _controller.notes.text,
        tr('العنوان أثناء الإجازة', 'Address during leave'):
            _controller.addressDuringLeave.text,
        tr('التواصل أثناء الإجازة', 'Contact during leave'):
            _controller.contactDuringLeave.text,
        tr('اسم الموقّع', 'Signatory'): _controller.applicantSignature.text,
        tr('توقيع البديل', 'Replacement signature'):
            _controller.replacementSignature.text,
        tr('توقيع المدير المباشر', 'Line manager signature'):
            _controller.lineManagerSignature.text,
        tr('تاريخ الالتحاق', 'Joining date'): _controller.joiningDate.text,
        tr('الرصيد السابق', 'Previous balance'):
            _controller.previousBalance.text,
        tr('الرصيد الجديد', 'New balance'): _controller.newBalance.text,
        tr('توقيع مدير الموارد البشرية', 'HR manager signature'):
            _controller.hrManagerSignature.text,
        tr('توقيع مدير القسم', 'Department manager signature'):
            _controller.departmentManagerSignature.text,
      },
    );
    await HrFormFileService.openPdfPreview(
      context,
      title: isArabic
          ? 'معاينة تصميم طلب إجازة إلكتروني'
          : 'Electronic Leave Request Preview',
      buildBytes: () => buildHrPortalFormPdf(draft),
    );
  }
}
