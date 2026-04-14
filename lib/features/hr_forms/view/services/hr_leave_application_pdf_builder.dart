import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'hr_form_pdf_support.dart';

Future<Uint8List> buildLeaveApplicationPdf({
  required bool isArabic,
  required String employeeName,
  required String idNumber,
  required String position,
  required String applicationDate,
  required String annualLeave,
  required String emergencyLeave,
  required String numberOfDays,
  required String fromDate,
  required String toDate,
  required String addressInLeave,
  required String applicantSignature,
  required String replacedEmployeeName,
  required String contactDuringLeave,
  required String replacedSignature,
  required String lineManagerSignature,
  required String joiningDate,
  required String laterAccruedAnnualLeave,
  required String previousBalance,
  required String newBalance,
  required String benefitTickets,
  required String deserve,
  required String doesNotDeserve,
  required String hrDepartment,
  required String departmentManagerSignature,
}) async {
  final pdf = pw.Document(theme: await loadHrFormPdfTheme());
  final logo = await loadHrFormLogo();
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(18),
      build: (_) => _buildLeaveApplicationPage(
        logo: logo,
        employeeName: employeeName,
        idNumber: idNumber,
        position: position,
        applicationDate: applicationDate,
        annualLeave: annualLeave,
        emergencyLeave: emergencyLeave,
        numberOfDays: numberOfDays,
        fromDate: fromDate,
        toDate: toDate,
        addressInLeave: addressInLeave,
        applicantSignature: applicantSignature,
        replacedEmployeeName: replacedEmployeeName,
        contactDuringLeave: contactDuringLeave,
        replacedSignature: replacedSignature,
        lineManagerSignature: lineManagerSignature,
        joiningDate: joiningDate,
        laterAccruedAnnualLeave: laterAccruedAnnualLeave,
        previousBalance: previousBalance,
        newBalance: newBalance,
        benefitTickets: benefitTickets,
        deserve: deserve,
        doesNotDeserve: doesNotDeserve,
        hrDepartment: hrDepartment,
        departmentManagerSignature: departmentManagerSignature,
      ),
    ),
  );
  return pdf.save();
}

pw.Widget _buildLeaveApplicationPage({
  required pw.MemoryImage logo,
  required String employeeName,
  required String idNumber,
  required String position,
  required String applicationDate,
  required String annualLeave,
  required String emergencyLeave,
  required String numberOfDays,
  required String fromDate,
  required String toDate,
  required String addressInLeave,
  required String applicantSignature,
  required String replacedEmployeeName,
  required String contactDuringLeave,
  required String replacedSignature,
  required String lineManagerSignature,
  required String joiningDate,
  required String laterAccruedAnnualLeave,
  required String previousBalance,
  required String newBalance,
  required String benefitTickets,
  required String deserve,
  required String doesNotDeserve,
  required String hrDepartment,
  required String departmentManagerSignature,
}) {
  const light = PdfColor.fromInt(0xFFF7F7F7);

  pw.Widget text(
    String value, {
    double size = 9,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Text(
      value,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    );
  }

  pw.Widget labelCell(
    String value, {
    required double width,
    required double height,
    bool bold = false,
    bool alignStart = false,
    bool thick = false,
  }) {
    return pw.Container(
      width: width,
      height: height,
      alignment: alignStart ? pw.Alignment.centerLeft : pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6),
      decoration: pw.BoxDecoration(
        color: bold ? light : PdfColors.white,
        border: pw.Border.all(color: PdfColors.black, width: thick ? 1.3 : .8),
      ),
      child: text(
        value,
        bold: bold,
        align: alignStart ? pw.TextAlign.left : pw.TextAlign.center,
      ),
    );
  }

  pw.Widget valueCell(String value, {required double height, PdfColor? fill}) {
    return pw.Expanded(
      child: pw.Container(
        height: height,
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: pw.BoxDecoration(
          color: fill ?? PdfColors.white,
          border: pw.Border.all(color: PdfColors.black, width: .8),
        ),
        child: text(value, align: pw.TextAlign.center),
      ),
    );
  }

  pw.Widget row3(
    String leftLabel,
    String value,
    String rightLabel, {
    double height = 32,
    PdfColor? fill,
  }) {
    return pw.Row(
      children: [
        labelCell(leftLabel, width: 150, height: height),
        valueCell(value, height: height, fill: fill),
        labelCell(rightLabel, width: 150, height: height),
      ],
    );
  }

  pw.Widget sectionHeader(
    String left,
    String right, {
    bool alignStart = false,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: labelCell(
            left,
            width: 0,
            height: 24,
            bold: true,
            alignStart: alignStart,
            thick: true,
          ),
        ),
        pw.Expanded(
          child: labelCell(
            right,
            width: 0,
            height: 24,
            bold: true,
            alignStart: alignStart,
            thick: true,
          ),
        ),
      ],
    );
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.SizedBox(
        height: 90,
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 6, top: 2),
              child: pw.Image(logo, width: 108),
            ),
            pw.Spacer(),
            pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                text('طلب إجازة', size: 14, bold: true),
                pw.SizedBox(height: 5),
                text('Leave Application', size: 12, bold: true),
              ],
            ),
            pw.Spacer(),
            pw.SizedBox(width: 108),
          ],
        ),
      ),
      sectionHeader('Employee Information', 'معلومات الموظف'),
      row3('Employee Name :', employeeName, 'اسم الموظف :'),
      row3('ID Number :', idNumber, 'الرقم الوظيفي :'),
      row3('Position :', position, 'المسمى الوظيفي :'),
      row3('Application Date :', applicationDate, 'تاريخ التقديم :'),
      sectionHeader(
        'Type of Leave :',
        'نوع الإجازة المطلوبة :',
        alignStart: true,
      ),
      row3('Annual Leave :', annualLeave, 'سنوية :'),
      row3('Emergency :', emergencyLeave, 'طارئة :'),
      row3('No. of Days :', numberOfDays, 'عدد الأيام :'),
      row3('From :', fromDate, 'من :', fill: PdfColors.grey300),
      row3('To :', toDate, 'إلى :', fill: PdfColors.grey300),
      row3(
        'Address In Leave :',
        addressInLeave,
        'العنوان خلال الإجازة :',
        height: 52,
      ),
      row3(
        'Signature of Applicant',
        applicantSignature,
        'توقيع مقدم الطلب',
        height: 36,
      ),
      sectionHeader('Replaced Employee Information', 'معلومات الموظف البديل'),
      row3('Employee Name', replacedEmployeeName, 'اسم الموظف'),
      row3('', contactDuringLeave, 'تواصل وإبلاغ'),
      row3(
        'Replaced Signature',
        replacedSignature,
        'توقيع الموظف البديل',
        height: 36,
      ),
      row3(
        'Line Mgr. Signature',
        lineManagerSignature,
        'توقيع المدير المباشر',
        height: 36,
      ),
      sectionHeader(
        'Using Human Resources Management',
        'لاستخدام إدارة الموارد البشرية',
      ),
      row3('Joining Date:', joiningDate, 'تاريخ بداية الخدمة:'),
      row3(
        'Later Accrued Annual Leave:',
        laterAccruedAnnualLeave,
        'موعد الإجازة السنوية المستحقة:',
      ),
      row3('Previous balance:', previousBalance, 'الرصيد السابق:'),
      row3('New balance:', newBalance, 'الرصيد الجديد:'),
      row3('Benefit Tickets:', benefitTickets, 'استحقاق تذاكر السفر:'),
      row3('Deserve:', deserve, 'يستحق إجازة:'),
      row3('Does not Deserve:', doesNotDeserve, 'لا يستحق إجازة:'),
      row3(
        'HR Department:',
        hrDepartment,
        'إدارة الموارد البشرية:',
        height: 44,
      ),
      row3(
        'Dep. Mgr. Signature:',
        departmentManagerSignature,
        'توقيع مدير الإدارة:',
        height: 44,
      ),
    ],
  );
}
