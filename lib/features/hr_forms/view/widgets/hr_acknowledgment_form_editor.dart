import 'package:flutter/material.dart';

import '../services/hr_acknowledgment_pdf_builder.dart';
import '../services/hr_form_file_service.dart';
import 'hr_form_shell.dart';

class HrAcknowledgmentFormEditor extends StatefulWidget {
  const HrAcknowledgmentFormEditor({super.key});

  @override
  State<HrAcknowledgmentFormEditor> createState() =>
      _HrAcknowledgmentFormEditorState();
}

class _HrAcknowledgmentFormEditorState
    extends State<HrAcknowledgmentFormEditor> {
  final _employeeName = TextEditingController();
  final _employeeId = TextEditingController();
  final _mobile = TextEditingController();
  final _signature = TextEditingController();

  static const _paperBorder = Color(0xFF1E1E1E);
  static const _badge = Color(0xFFD9EFEA);

  @override
  void dispose() {
    for (final controller in [_employeeName, _employeeId, _mobile, _signature]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return HrFormShell(
      title: isArabic ? 'إقرار وتعهد' : 'Acknowledgment & Undertaking',
      subtitle: isArabic
          ? 'نموذج رسمي جاهز للتعبئة أو الطباعة الفارغة.'
          : 'A formal template ready for digital filling or blank printing.',
      actions: [
        OutlinedButton.icon(
          onPressed: _clear,
          icon: const Icon(Icons.cleaning_services_outlined),
          label: Text(isArabic ? 'تفريغ' : 'Clear'),
        ),
        FilledButton.icon(
          onPressed: () => _downloadPdf(context, isArabic),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(isArabic ? 'طباعة / PDF' : 'Print / PDF'),
        ),
      ],
      child: Container(
        width: 850,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _paperBorder.withValues(alpha: 0.18)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 94,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: _badge,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'إقرار وتعهد',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Image.asset('assets/images/fullLogo.png', width: 150),
                const Spacer(),
                const SizedBox(width: 94),
              ],
            ),
            const SizedBox(height: 26),
            _lineField('أقر وأنا الموقع /', _employeeName),
            const SizedBox(height: 10),
            _dualLineField('هويتي رقم /', _employeeId, 'جوال /', _mobile),
            const SizedBox(height: 22),
            ..._undertakingParagraphs(),
            const SizedBox(height: 30),
            const Text(
              'التوقيع',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _paperBorder, width: 1.2),
                ),
              ),
              child: TextField(
                controller: _signature,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF2D8C82).withValues(alpha: 0.8),
                  ),
                ),
              ),
              child: Text(
                'CR 4030171445 Chamber of Commerce membership 122057',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineField(String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 4),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _paperBorder, width: 1),
              ),
            ),
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _dualLineField(
    String rightLabel,
    TextEditingController rightController,
    String leftLabel,
    TextEditingController leftController,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 4),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _paperBorder, width: 1),
              ),
            ),
            child: TextField(
              controller: leftController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          leftLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 28),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 4),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _paperBorder, width: 1),
              ),
            ),
            child: TextField(
              controller: rightController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          rightLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  List<Widget> _undertakingParagraphs() {
    const items = [
      '1- أحافظ محافظة تامة على جميع البيانات التجارية وعلى حسب الوظيفة المقررة في العقد المبرم مني، وجميع المعلومات التي حصلت عليها والتي ستكون متوفرة لي لدى الشركة والإدارات التي تدير المؤسسة بناءً عليها من خلال سجل العملاء وسجل الفعاليات على سبيل المثال للاطلاع على الخطط والاستراتيجيات وخطة العمل وسياسات الأعمال الداخلية، وسجلات المستخدمين وتفاصيل الطلبات والاجتماعات والملفات المالية والحسابات البنكية، وكل ما يخص الشركة من معلومات خاصة وأسرار ومصلحة المؤسسة سواء تمت هذه المعلومات بصورة مكتوبة أو شفوية.',
      '2- أتعهد بعدم إفشاء أو تقديم أو توصيف أو التسجيل أو الاحتفاظ بشكل عام أو غير مباشر بأي طريقة عمل تخص المؤسسة، وأتعهد بعدم الاحتفاظ بنسخة من المعلومات سواء خلال فترة عملي مع المؤسسة أو بعد تركي للعمل بالمؤسسة وبعد التواصل معهم بقدر لا يخل بكل الأشكال.',
      '3- في حالة إن قام الغير بتعريضي للمساءلة النظامية أو الملاحقة القانونية داخل المملكة وخارجها، فإنني مسؤول مسؤولية كاملة ويحق للمؤسسة حينها أن تقوم بتحصيل كل ما صرف وكذلك أي مطالبات تنشأ عن هذه الأضرار.',
      '4- كما أتعهد بعدم استغلال عملي لدى المؤسسة في أي أمر يروج إلى عمل غير احترافي وفي حال ثبت ذلك يحق للمؤسسة اتخاذ الإجراء قانونًا لدى الجهات المختصة.',
    ];

    return items
        .map(
          (text) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15.5,
                height: 1.7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        )
        .toList();
  }

  void _clear() {
    for (final controller in [_employeeName, _employeeId, _mobile, _signature]) {
      controller.clear();
    }
    setState(() {});
  }

  Future<void> _downloadPdf(BuildContext context, bool isArabic) async {
    await HrFormFileService.savePdf(
      context,
      suggestedName: 'acknowledgment_undertaking_form.pdf',
      buildBytes: () => buildAcknowledgmentFormPdf(
        isArabic: isArabic,
        employeeName: _employeeName.text,
        employeeId: _employeeId.text,
        department: '',
        jobTitle: '',
        subject: _mobile.text,
        body: '',
        employeeSignature: _signature.text,
        date: '',
        hrSignature: '',
      ),
      successMessage: isArabic
          ? 'تم حفظ نموذج الإقرار والتعهد بصيغة PDF'
          : 'Acknowledgment form saved as PDF',
    );
  }
}
