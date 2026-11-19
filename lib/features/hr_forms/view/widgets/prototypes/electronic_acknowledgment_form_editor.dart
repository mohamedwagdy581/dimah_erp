import 'package:material_ui/material_ui.dart';

import '../../services/hr_form_file_service.dart';
import '../../services/hr_portal_form_pdf.dart';
import '../hr_form_shell.dart';
import 'electronic_acknowledgment/electronic_acknowledgment_form_body.dart';
import 'electronic_acknowledgment/electronic_acknowledgment_form_controller.dart';

class ElectronicAcknowledgmentFormEditor extends StatefulWidget {
  const ElectronicAcknowledgmentFormEditor({super.key});

  @override
  State<ElectronicAcknowledgmentFormEditor> createState() =>
      _ElectronicAcknowledgmentFormEditorState();
}

class _ElectronicAcknowledgmentFormEditorState
    extends State<ElectronicAcknowledgmentFormEditor> {
  late final ElectronicAcknowledgmentFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ElectronicAcknowledgmentFormController()..initialize();
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
          ? 'نموذج تجريبي - إقرار إلكتروني'
          : 'Prototype - Electronic Acknowledgment',
      subtitle: isArabic
          ? 'نسخة تجريبية ألطف بصريًا لعرضها على العميل دون التأثير على النموذج الرسمي الحالي.'
          : 'A softer electronic prototype for client review without touching the current official form.',
      actions: const [],
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return ElectronicAcknowledgmentFormBody(
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
      isLeave: false,
      employeeName: _controller.employeeName.text,
      employeeNumber: _controller.employeeId.text,
      department: _controller.department.text,
      jobTitle: _controller.role.text,
      date: '',
      agreed: false,
      fields: {
        tr('رقم الجوال', 'Mobile'): _controller.mobile.text,
        tr('اسم الموقّع', 'Signatory'): _controller.signature.text,
        tr('سرية المعلومات', 'Information confidentiality'): tr(
          'أقر بأن جميع البيانات والملفات والسجلات التي أطلع عليها خلال عملي تعتبر معلومات داخلية تخص المؤسسة، وأتعهد بالمحافظة عليها وعدم نسخها أو مشاركتها إلا في حدود صلاحياتي العملية.',
          'I acknowledge that all records, files, and internal materials accessed during my work are confidential and may only be used within my authorized scope.',
        ),
        tr('عدم الاحتفاظ أو الإفشاء', 'No retention or disclosure'): tr(
          'أتعهد بعدم الاحتفاظ بأي نسخة من المعلومات أو المستندات الخاصة بالمؤسسة بعد انتهاء الحاجة العملية إليها، سواء خلال العمل أو بعد انتهاء العلاقة التعاقدية.',
          'I undertake not to retain or disclose company documents or data beyond operational need, whether during employment or after it ends.',
        ),
        tr('المسؤولية النظامية', 'Administrative responsibility'): tr(
          'في حال مخالفة ذلك، أتحمل كامل المسؤولية الإدارية والنظامية عن أي أضرار أو التزامات تنشأ نتيجة الإخلال بهذا الإقرار.',
          'In case of breach, I bear full administrative and legal responsibility for any resulting damage or violation.',
        ),
      },
    );
    await HrFormFileService.openPdfPreview(
      context,
      title: isArabic
          ? 'معاينة الإقرار الإلكتروني التجريبي'
          : 'Electronic Acknowledgment Preview',
      buildBytes: () => buildHrPortalFormPdf(draft),
    );
  }
}
