import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'hr_form_pdf_support.dart';

Future<Uint8List> buildAcknowledgmentFormPdf({
  required bool isArabic,
  required String employeeName,
  required String employeeId,
  required String department,
  required String jobTitle,
  required String subject,
  required String body,
  required String employeeSignature,
  required String date,
  required String hrSignature,
}) async {
  final pdf = pw.Document(theme: await loadHrFormPdfTheme());
  final logo = await loadHrFormLogo();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => _buildPage(
        isArabic: isArabic,
        logo: logo,
        employeeName: employeeName,
        employeeId: employeeId,
        mobile: subject,
        signature: employeeSignature,
      ),
    ),
  );

  return pdf.save();
}

pw.Widget _buildPage({
  required bool isArabic,
  required pw.MemoryImage logo,
  required String employeeName,
  required String employeeId,
  required String mobile,
  required String signature,
}) {
  const accent = PdfColor.fromInt(0xFFD9EFEA);

  pw.Widget txt(
    String value, {
    double size = 11,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Text(
      value,
      textAlign: align,
      textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      style: pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    );
  }

  pw.Widget lineField(String label, String value) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 1),
              ),
            ),
            child: txt(value, align: pw.TextAlign.right),
          ),
        ),
        pw.SizedBox(width: 8),
        txt(label, size: 12, bold: true, align: pw.TextAlign.right),
      ],
    );
  }

  pw.Widget dualLineField(
    String rightLabel,
    String rightValue,
    String leftLabel,
    String leftValue,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 1),
              ),
            ),
            child: txt(leftValue, align: pw.TextAlign.right),
          ),
        ),
        pw.SizedBox(width: 8),
        txt(leftLabel, size: 12, bold: true, align: pw.TextAlign.right),
        pw.SizedBox(width: 24),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 1),
              ),
            ),
            child: txt(rightValue, align: pw.TextAlign.right),
          ),
        ),
        pw.SizedBox(width: 8),
        txt(rightLabel, size: 12, bold: true, align: pw.TextAlign.right),
      ],
    );
  }

  const paragraphs = [
    '1- أحافظ محافظة تامة على جميع البيانات التجارية وعلى حسب الوظيفة المقررة في العقد المبرم مني، وجميع المعلومات التي حصلت عليها والتي ستكون متوفرة لي لدى الشركة والإدارات التي تدير المؤسسة بناءً عليها من خلال سجل العملاء وسجل الفعاليات على سبيل المثال للاطلاع على الخطط والاستراتيجيات وخطة العمل وسياسات الأعمال الداخلية، وسجلات المستخدمين وتفاصيل الطلبات والاجتماعات والملفات المالية والحسابات البنكية، وكل ما يخص الشركة من معلومات خاصة وأسرار ومصلحة المؤسسة سواء تمت هذه المعلومات بصورة مكتوبة أو شفوية.',
    '2- أتعهد بعدم إفشاء أو تقديم أو توصيف أو التسجيل أو الاحتفاظ بشكل عام أو غير مباشر بأي طريقة عمل تخص المؤسسة، وأتعهد بعدم الاحتفاظ بنسخة من المعلومات سواء خلال فترة عملي مع المؤسسة أو بعد تركي للعمل بالمؤسسة وبعد التواصل معهم بقدر لا يخل بكل الأشكال.',
    '3- في حالة إن قام الغير بتعريضي للمساءلة النظامية أو الملاحقة القانونية داخل المملكة وخارجها، فإنني مسؤول مسؤولية كاملة ويحق للمؤسسة حينها أن تقوم بتحصيل كل ما صرف وكذلك أي مطالبات تنشأ عن هذه الأضرار.',
    '4- كما أتعهد بعدم استغلال عملي لدى المؤسسة في أي أمر يروج إلى عمل غير احترافي وفي حال ثبت ذلك يحق للمؤسسة اتخاذ الإجراء قانونًا لدى الجهات المختصة.',
  ];

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 72,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            decoration: pw.BoxDecoration(
              color: accent,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: txt('إقرار وتعهد', size: 12, bold: true),
          ),
          pw.Spacer(),
          pw.Image(logo, width: 120),
          pw.Spacer(),
          pw.SizedBox(width: 72),
        ],
      ),
      pw.SizedBox(height: 24),
      lineField('أقر وأنا الموقع /', employeeName),
      pw.SizedBox(height: 10),
      dualLineField('هويتي رقم /', employeeId, 'جوال /', mobile),
      pw.SizedBox(height: 18),
      ...paragraphs.map(
        (paragraph) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: txt(
            paragraph,
            size: 11.5,
            bold: true,
            align: pw.TextAlign.right,
          ),
        ),
      ),
      pw.SizedBox(height: 24),
      txt('التوقيع', size: 16, bold: true, align: pw.TextAlign.right),
      pw.SizedBox(height: 10),
      pw.Container(
        height: 28,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.black, width: 1.2),
          ),
        ),
        child: pw.Align(
          alignment: pw.Alignment.centerRight,
          child: txt(signature, align: pw.TextAlign.right),
        ),
      ),
      pw.Spacer(),
      pw.Container(
        padding: const pw.EdgeInsets.only(top: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(
              color: PdfColor.fromInt(0xFF2D8C82),
              width: 1,
            ),
          ),
        ),
        child: txt(
          'CR 4030171445 Chamber of Commerce membership 122057',
          size: 7.5,
        ),
      ),
    ],
  );
}
