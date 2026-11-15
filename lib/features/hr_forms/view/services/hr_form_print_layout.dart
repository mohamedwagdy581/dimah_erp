import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'hr_form_pdf_support.dart';

Future<Uint8List> buildHrPrintDocument({
  required bool isArabic,
  required bool isLeave,
  required bool agreed,
  required String employeeName,
  required String employeeNumber,
  required String department,
  required String jobTitle,
  required String date,
  required Map<String, String> fields,
  String? documentTitle,
  String? templateCode,
  List<String>? signatureLabels,
}) async {
  final pdf = pw.Document(
    theme: await loadHrFormPdfTheme(),
    title:
        documentTitle ??
        (isLeave ? 'DIMAH Leave Request' : 'DIMAH Acknowledgment'),
    author: 'DIMAH MUSIC',
  );
  final logo = await loadHrFormLogo();
  final ink = PdfColor.fromHex('#0F172A'),
      text = PdfColor.fromHex('#334155'),
      muted = PdfColor.fromHex('#64748B'),
      purple = PdfColor.fromHex('#8659BB'),
      line = PdfColor.fromHex('#E2E8F0');
  final direction = isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  String tr(String a, String e) => isArabic ? a : e;
  String clean(String value) =>
      value.trim().isEmpty || value.trim() == '—' ? '-' : value.trim();
  pw.TextDirection valueDirection(String value) =>
      RegExp(r'[\u0600-\u06ff]').hasMatch(value)
      ? pw.TextDirection.rtl
      : pw.TextDirection.ltr;
  Iterable<String> paragraphs(String value) sync* {
    for (final row in value.split('\n')) {
      var remaining = row.trim();
      while (remaining.length > 700) {
        final split = remaining.lastIndexOf(' ', 700);
        final end = split > 0 ? split : 700;
        yield remaining.substring(0, end);
        remaining = remaining.substring(end).trimLeft();
      }
      if (remaining.isNotEmpty) yield remaining;
    }
  }

  pw.Widget field(String label, String value) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Text(
        label,
        textDirection: direction,
        style: pw.TextStyle(fontSize: 9, color: muted),
      ),
      pw.SizedBox(height: 5),
      pw.Text(
        clean(value),
        textDirection: valueDirection(value),
        textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 11.5,
          color: text,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ],
  );
  List<pw.Widget> grid(List<MapEntry<String, String>> entries) => [
    for (var i = 0; i < entries.length; i += 2)
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 14),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: field(entries[i].key, entries[i].value)),
            pw.SizedBox(width: 28),
            pw.Expanded(
              child: i + 1 < entries.length
                  ? field(entries[i + 1].key, entries[i + 1].value)
                  : pw.SizedBox(),
            ),
          ],
        ),
      ),
  ];
  pw.Widget section(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 14, bottom: 14),
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8),
      decoration: pw.BoxDecoration(
        border: isArabic
            ? pw.Border(right: pw.BorderSide(color: purple, width: 2))
            : pw.Border(left: pw.BorderSide(color: purple, width: 2)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          color: purple,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ),
  );
  final entries = fields.entries
      .where((e) => e.value.trim().isNotEmpty)
      .toList();
  final narrative = entries
      .where(
        (e) =>
            e.value.length > 180 ||
            [
              tr('نص الإقرار', 'Acknowledgment'),
              tr('سبب الإجازة / الملاحظات', 'Reason / notes'),
              tr('سرية المعلومات', 'Information confidentiality'),
              tr('عدم الاحتفاظ أو الإفشاء', 'No retention or disclosure'),
              tr('المسؤولية النظامية', 'Administrative responsibility'),
            ].contains(e.key),
      )
      .toList();
  final compact = entries.where((e) => !narrative.contains(e)).toList();
  pw.Widget signature(String label) => pw.Expanded(
    child: pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Divider(color: muted, thickness: .6),
        ],
      ),
    ),
  );
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 42, 48, 42),
      textDirection: direction,
      header: (context) => pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(logo, width: 58, height: 46, fit: pw.BoxFit.contain),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DIMAH MUSIC',
                      textDirection: pw.TextDirection.ltr,
                      style: pw.TextStyle(
                        fontSize: 17,
                        fontWeight: pw.FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      tr('إدارة الموارد البشرية', 'Human Resources'),
                      style: pw.TextStyle(fontSize: 9, color: muted),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    tr('رمز النموذج', 'Template code'),
                    style: pw.TextStyle(fontSize: 8, color: muted),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    templateCode ?? (isLeave ? 'HR-LV / 01' : 'HR-ACK / 01'),
                    textDirection: pw.TextDirection.ltr,
                    style: pw.TextStyle(fontSize: 9, color: ink),
                  ),
                  pw.SizedBox(height: 7),
                  pw.Text(
                    clean(date),
                    textDirection: pw.TextDirection.ltr,
                    style: pw.TextStyle(fontSize: 9, color: muted),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: purple, thickness: 1),
          pw.SizedBox(height: 18),
        ],
      ),
      footer: (context) => pw.Column(
        children: [
          pw.SizedBox(height: 10),
          pw.Divider(color: line, thickness: .5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                tr(
                  documentTitle != null
                      ? 'نموذج أولي - غير معتمد | DIMAH ERP'
                      : 'مُنشأ إلكترونيًا عبر DIMAH ERP',
                  documentTitle != null
                      ? 'Prototype - not approved | DIMAH ERP'
                      : 'Generated electronically by DIMAH ERP',
                ),
                style: pw.TextStyle(fontSize: 7.5, color: muted),
              ),
              pw.Text(
                '${context.pageNumber} / ${context.pagesCount}',
                textDirection: pw.TextDirection.ltr,
                style: pw.TextStyle(fontSize: 7.5, color: muted),
              ),
            ],
          ),
        ],
      ),
      build: (_) => [
        pw.Text(
          documentTitle ??
              tr(
                isLeave
                    ? 'طلب إجازة موظف إلكتروني'
                    : 'إقرار بالالتزام بسياسات الشركة',
                isLeave
                    ? 'Employee leave request'
                    : 'Company policy acknowledgment',
              ),
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: ink,
          ),
        ),
        pw.SizedBox(height: 12),
        section(tr('بيانات الموظف الأساسية', 'Employee information')),
        ...grid([
          MapEntry(tr('اسم الموظف', 'Employee name'), employeeName),
          MapEntry(tr('الرقم الوظيفي', 'Employee number'), employeeNumber),
          MapEntry(tr('القسم', 'Department'), department),
          MapEntry(tr('المسمى الوظيفي', 'Job title'), jobTitle),
        ]),
        section(
          tr(
            documentTitle != null
                ? 'تفاصيل النموذج'
                : (isLeave ? 'تفاصيل الإجازة' : 'بيانات الإقرار'),
            documentTitle != null
                ? 'Form details'
                : (isLeave ? 'Leave details' : 'Acknowledgment details'),
          ),
        ),
        ...grid(compact),
        for (final item in narrative) ...[
          section(item.key),
          for (final paragraph in paragraphs(item.value))
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(
                paragraph,
                textDirection: valueDirection(paragraph),
                style: pw.TextStyle(fontSize: 11, color: text, lineSpacing: 4),
              ),
            ),
        ],
        if (!isLeave && documentTitle == null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              agreed
                  ? tr(
                      'تم تحديد موافقة الموظف على النص في النموذج.',
                      'The employee acknowledgment checkbox was selected.',
                    )
                  : tr('بانتظار توقيع الموظف.', 'Awaiting employee signature.'),
              style: pw.TextStyle(fontSize: 9, color: muted),
            ),
          ),
        pw.Container(
          padding: const pw.EdgeInsets.only(top: 30),
          child: pw.Row(
            children: [
              if (signatureLabels != null)
                for (final label in signatureLabels) signature(label),
              if (signatureLabels == null)
                signature(tr('توقيع الموظف', 'Employee signature')),
              if (isLeave && signatureLabels == null)
                signature(tr('المدير المباشر', 'Line manager')),
              if (signatureLabels == null)
                signature(tr('الموارد البشرية', 'Human Resources')),
            ],
          ),
        ),
      ],
    ),
  );
  return pdf.save();
}
