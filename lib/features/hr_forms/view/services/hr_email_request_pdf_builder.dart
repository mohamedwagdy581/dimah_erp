import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'hr_form_pdf_support.dart';

Future<Uint8List> buildEmailRequestFormPdf({
  required bool isArabic,
  required String employeeName,
  required String employeeNumber,
  required String department,
  required String jobTitle,
  required String employeeSignature,
  required String firstNameCaps,
  required String familyNameCaps,
  required String location,
  required String officeAddress,
  required String companyMobile,
  required String emailAddress,
  required String lineManagerSignature,
  required String hrSignature,
  required String itSignature,
}) async {
  final pdf = pw.Document(theme: await loadHrFormPdfTheme());
  final logo = await loadHrFormLogo();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(22),
      build: (_) => _emailRequestPdfPage(
        isArabic: isArabic,
        logo: logo,
        employeeName: employeeName,
        employeeNumber: employeeNumber,
        department: department,
        jobTitle: jobTitle,
        employeeSignature: employeeSignature,
        firstNameCaps: firstNameCaps,
        familyNameCaps: familyNameCaps,
        location: location,
        officeAddress: officeAddress,
        companyMobile: companyMobile,
        emailAddress: emailAddress,
        lineManagerSignature: lineManagerSignature,
        hrSignature: hrSignature,
        itSignature: itSignature,
      ),
    ),
  );

  return pdf.save();
}

pw.Widget _emailRequestPdfPage({
  required bool isArabic,
  required pw.MemoryImage logo,
  required String employeeName,
  required String employeeNumber,
  required String department,
  required String jobTitle,
  required String employeeSignature,
  required String firstNameCaps,
  required String familyNameCaps,
  required String location,
  required String officeAddress,
  required String companyMobile,
  required String emailAddress,
  required String lineManagerSignature,
  required String hrSignature,
  required String itSignature,
}) {
  const accent = PdfColor.fromInt(0xFFD9EFEA);
  const light = PdfColor.fromInt(0xFFF4F7F6);
  const border = PdfColor.fromInt(0xFF1E1E1E);

  pw.Widget txt(
    String value, {
    double size = 10,
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

  pw.BorderSide gridSide([double width = 1]) {
    return const pw.BorderSide(color: border, width: 1);
  }

  pw.Widget topCell({
    required String arLabel,
    required String enLabel,
    required String value,
    required double labelWidth,
    double minHeight = 44,
  }) {
    return pw.Container(
      constraints: pw.BoxConstraints(minHeight: minHeight),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: gridSide(),
          right: gridSide(),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: labelWidth,
            constraints: pw.BoxConstraints(minHeight: minHeight),
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: pw.BoxDecoration(
              color: light,
              border: pw.Border(right: gridSide()),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                txt(arLabel, size: 8, bold: true, align: pw.TextAlign.left),
                pw.SizedBox(height: 2),
                txt(enLabel, size: 7.6, bold: true, align: pw.TextAlign.left),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              constraints: pw.BoxConstraints(minHeight: minHeight),
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: txt(value, align: pw.TextAlign.right),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget detailRow({
    required String label,
    required String value,
    double minHeight = 30,
    double labelWidth = 240,
    double labelFontSize = 8.8,
  }) {
    return pw.Row(
      children: [
        pw.Container(
          width: labelWidth,
          constraints: pw.BoxConstraints(minHeight: minHeight),
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: pw.BoxDecoration(
            color: light,
            border: pw.Border(
              top: gridSide(),
              right: gridSide(),
            ),
          ),
          child: pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: txt(
              label,
              size: labelFontSize,
              bold: true,
              align: pw.TextAlign.left,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Container(
            constraints: pw.BoxConstraints(minHeight: minHeight),
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: gridSide()),
            ),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: txt(value, align: pw.TextAlign.right),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget signCell({
    required String arLabel,
    required String enLabel,
    required String value,
    bool drawRightBorder = true,
    bool drawLeftBorder = false,
  }) {
    return pw.Expanded(
      child: pw.Container(
        constraints: const pw.BoxConstraints(minHeight: 110),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            left: drawLeftBorder ? gridSide() : pw.BorderSide.none,
            right: drawRightBorder ? gridSide() : pw.BorderSide.none,
            bottom: gridSide(),
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              color: light,
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  txt(arLabel, size: 8.4, bold: true, align: pw.TextAlign.left),
                  pw.SizedBox(height: 2),
                  txt(enLabel, size: 8, bold: true, align: pw.TextAlign.left),
                ],
              ),
            ),
            pw.Container(
              constraints: const pw.BoxConstraints(minHeight: 68),
              decoration: pw.BoxDecoration(
                border: pw.Border(top: gridSide()),
              ),
              padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: pw.Align(
                alignment: pw.Alignment.topRight,
                child: txt(value, align: pw.TextAlign.right),
              ),
            ),
          ],
        ),
      ),
    );
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 64,
            padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: pw.BoxDecoration(
              color: accent,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: txt('طلب\nبريد\nإلكتروني', bold: true, align: pw.TextAlign.center),
          ),
          pw.Spacer(),
          pw.Image(logo, width: 118),
          pw.Spacer(),
          pw.SizedBox(width: 64),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Container(
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: border, width: 1.35),
        ),
        child: pw.Column(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: pw.Column(
                children: [
                  txt(
                    'يرجى عمل بريد إلكتروني للموظف التالي',
                    size: 10.5,
                    bold: true,
                  ),
                  pw.SizedBox(height: 3),
                  txt(
                    'Please Email Registration for the following employee',
                    size: 9.5,
                    bold: true,
                  ),
                ],
              ),
            ),
            pw.Row(
              children: [
                pw.Expanded(
                  child: topCell(
                    arLabel: 'اسم الموظف',
                    enLabel: 'Employee Name',
                    value: employeeName,
                    labelWidth: 120,
                  ),
                ),
                pw.Expanded(
                  child: topCell(
                    arLabel: 'رقم الموظف',
                    enLabel: 'Employee No.',
                    value: employeeNumber,
                    labelWidth: 120,
                  ),
                ),
              ],
            ),
            pw.Row(
              children: [
                pw.Expanded(
                  child: topCell(
                    arLabel: 'القسم',
                    enLabel: 'Department',
                    value: department,
                    labelWidth: 120,
                  ),
                ),
                pw.Expanded(
                  child: topCell(
                    arLabel: 'المسمى الوظيفي',
                    enLabel: 'Job Title',
                    value: jobTitle,
                    labelWidth: 120,
                  ),
                ),
              ],
            ),
            pw.Row(
              children: [
                pw.Expanded(
                  child: topCell(
                    arLabel: 'التوقيع',
                    enLabel: 'Signature',
                    value: employeeSignature,
                    labelWidth: 120,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: border, width: 1.35),
        ),
        child: pw.Column(
          children: [
            detailRow(label: 'First name (in caps)', value: firstNameCaps),
            detailRow(label: 'Family name (in caps)', value: familyNameCaps),
            detailRow(label: 'Job Title', value: jobTitle),
            detailRow(label: 'Location', value: location),
            detailRow(label: 'Office Address', value: officeAddress),
            detailRow(label: 'Company Mobile', value: companyMobile),
            detailRow(
              label: 'Email Address: First name . Family Name @dimahmusic.com',
              value: emailAddress,
              minHeight: 38,
              labelWidth: 300,
              labelFontSize: 7.8,
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 14),
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: border, width: 1.35),
        ),
        child: pw.Row(
          children: [
            signCell(
              arLabel: 'توقيع المدير المباشر',
              enLabel: 'Line Manager Signature',
              value: lineManagerSignature,
              drawLeftBorder: true,
            ),
            signCell(
              arLabel: 'توقيع مدير الموارد البشرية',
              enLabel: 'Human Resources Department',
              value: hrSignature,
              drawLeftBorder: true,
            ),
            signCell(
              arLabel: 'قسم التقنية',
              enLabel: 'Information Technology',
              value: itSignature,
              drawRightBorder: false,
              drawLeftBorder: true,
            ),
          ],
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
