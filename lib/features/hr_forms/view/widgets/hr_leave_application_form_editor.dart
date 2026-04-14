import 'package:flutter/material.dart';

import '../../../../core/di/app_di.dart';
import '../../../employees/domain/models/employee_lookup.dart';
import '../../../employees/domain/models/employee_profile_details.dart';
import '../services/hr_form_file_service.dart';
import '../services/hr_leave_application_pdf_builder.dart';
import 'hr_form_shell.dart';

class HrLeaveApplicationFormEditor extends StatefulWidget {
  const HrLeaveApplicationFormEditor({super.key});

  @override
  State<HrLeaveApplicationFormEditor> createState() =>
      _HrLeaveApplicationFormEditorState();
}

class _HrLeaveApplicationFormEditorState
    extends State<HrLeaveApplicationFormEditor> {
  final _employeeName = TextEditingController();
  final _idNumber = TextEditingController();
  final _position = TextEditingController();
  final _applicationDate = TextEditingController();
  final _annualLeave = TextEditingController();
  final _emergencyLeave = TextEditingController();
  final _numberOfDays = TextEditingController();
  final _fromDate = TextEditingController();
  final _toDate = TextEditingController();
  final _addressInLeave = TextEditingController();
  final _applicantSignature = TextEditingController();
  final _replacedEmployeeName = TextEditingController();
  final _contactDuringLeave = TextEditingController();
  final _replacedSignature = TextEditingController();
  final _lineManagerSignature = TextEditingController();
  final _joiningDate = TextEditingController(text: '2025-05-12');
  final _laterAccruedAnnualLeave = TextEditingController(text: '2026-05-31');
  final _previousBalance = TextEditingController(text: '0');
  final _newBalance = TextEditingController(text: '0');
  final _benefitTickets = TextEditingController(text: '0');
  final _deserve = TextEditingController(text: 'نعم');
  final _doesNotDeserve = TextEditingController();
  final _hrDepartment = TextEditingController();
  final _departmentManagerSignature = TextEditingController();

  List<EmployeeLookup> _employeeOptions = const [];
  String? _selectedEmployeeId;
  bool _loadingEmployees = true;
  bool _fillingEmployee = false;
  static const _gridColor = Color(0xFFE8EEEB);

  @override
  void initState() {
    super.initState();
    _applicationDate.text = _formatDate(DateTime.now());
    _loadEmployees();
  }

  @override
  void dispose() {
    for (final controller in [
      _employeeName,
      _idNumber,
      _position,
      _applicationDate,
      _annualLeave,
      _emergencyLeave,
      _numberOfDays,
      _fromDate,
      _toDate,
      _addressInLeave,
      _applicantSignature,
      _replacedEmployeeName,
      _contactDuringLeave,
      _replacedSignature,
      _lineManagerSignature,
      _joiningDate,
      _laterAccruedAnnualLeave,
      _previousBalance,
      _newBalance,
      _benefitTickets,
      _deserve,
      _doesNotDeserve,
      _hrDepartment,
      _departmentManagerSignature,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return HrFormShell(
      title: isArabic ? 'طلب إجازة' : 'Leave Application',
      subtitle: isArabic
          ? 'نسخة أقرب للنموذج الورقي الرسمي، قابلة للتعبئة والطباعة مباشرة.'
          : 'A refined printable version that closely follows the official paper form.',
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
        width: 980,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: const _LeaveGridPainter(color: _gridColor),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _employeePicker(isArabic),
                const SizedBox(height: 10),
                _header(),
                const SizedBox(height: 8),
                _sectionHeader('Employee Information', 'معلومات الموظف'),
                _infoRow('Employee Name :', _employeeName, 'اسم الموظف :'),
                _infoRow('ID Number :', _idNumber, 'الرقم الوظيفي :'),
                _infoRow('Position :', _position, 'المسمى الوظيفي :'),
                _infoRow('Application Date :', _applicationDate, 'تاريخ التقديم :'),
                _sectionHeader(
                  'Type of Leave :',
                  'نوع الإجازة المطلوبة :',
                  alignStart: true,
                ),
                _infoRow('Annual Leave :', _annualLeave, 'سنوية :'),
                _infoRow('Emergency :', _emergencyLeave, 'طارئة :'),
                _infoRow('No. of Days :', _numberOfDays, 'عدد الأيام :'),
                _dateRow('From :', _fromDate, 'من :'),
                _dateRow('To :', _toDate, 'إلى :'),
                _infoRow(
                  'Address In Leave :',
                  _addressInLeave,
                  'العنوان خلال الإجازة :',
                  height: 52,
                  maxLines: 2,
                ),
                _infoRow(
                  'Signature of Applicant',
                  _applicantSignature,
                  'توقيع مقدم الطلب',
                  height: 36,
                ),
                _sectionHeader(
                  'Replaced Employee Information',
                  'معلومات الموظف البديل',
                ),
                _infoRow('Employee Name', _replacedEmployeeName, 'اسم الموظف'),
                _infoRow('', _contactDuringLeave, 'تواصل وإبلاغ'),
                _infoRow(
                  'Replaced Signature',
                  _replacedSignature,
                  'توقيع الموظف البديل',
                  height: 36,
                ),
                _infoRow(
                  'Line Mgr. Signature',
                  _lineManagerSignature,
                  'توقيع المدير المباشر',
                  height: 36,
                ),
                _sectionHeader(
                  'Using Human Resources Management',
                  'لاستخدام إدارة الموارد البشرية',
                ),
                _infoRow('Joining Date:', _joiningDate, 'تاريخ بداية الخدمة:'),
                _infoRow(
                  'Later Accrued Annual Leave:',
                  _laterAccruedAnnualLeave,
                  'موعد الإجازة السنوية المستحقة:',
                ),
                _infoRow('Previous balance:', _previousBalance, 'الرصيد السابق:'),
                _infoRow('New balance:', _newBalance, 'الرصيد الجديد:'),
                _infoRow(
                  'Benefit Tickets:',
                  _benefitTickets,
                  'استحقاق تذاكر السفر:',
                ),
                _infoRow('Deserve:', _deserve, 'يستحق إجازة:'),
                _infoRow('Does not Deserve:', _doesNotDeserve, 'لا يستحق إجازة:'),
                _infoRow(
                  'HR Department:',
                  _hrDepartment,
                  'إدارة الموارد البشرية:',
                  height: 44,
                ),
                _infoRow(
                  'Dep. Mgr. Signature:',
                  _departmentManagerSignature,
                  'توقيع مدير الإدارة:',
                  height: 44,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _employeePicker(bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBCD8D2)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, color: Colors.teal.shade700),
          Text(
            isArabic ? 'تعبئة تلقائية من الموظف' : 'Auto-fill from employee',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(
            width: 320,
            child: DropdownButtonFormField<String>(
              value: _selectedEmployeeId,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelText: isArabic ? 'اختيار موظف' : 'Select employee',
              ),
              items: _employeeOptions
                  .map(
                    (employee) => DropdownMenuItem(
                      value: employee.id,
                      child: Text(
                        employee.fullName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _loadingEmployees || _fillingEmployee
                  ? null
                  : (value) {
                      if (value != null) _fillFromEmployee(value);
                    },
            ),
          ),
          if (_loadingEmployees || _fillingEmployee)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          TextButton.icon(
            onPressed: _fillingEmployee ? null : _clearFilledEmployee,
            icon: const Icon(Icons.restart_alt),
            label: Text(isArabic ? 'إلغاء الربط' : 'Clear selection'),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return SizedBox(
      height: 92,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Image.asset('assets/images/fullLogo.png', width: 118),
          ),
          const Spacer(),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'طلب إجازة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6),
              Text(
                'Leave Application',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 118),
        ],
      ),
    );
  }

  Widget _sectionHeader(String left, String right, {bool alignStart = false}) {
    return Row(
      children: [
        Expanded(
          child: _labelCell(
            left,
            height: 24,
            bold: true,
            alignStart: alignStart,
            thick: true,
          ),
        ),
        Expanded(
          child: _labelCell(
            right,
            height: 24,
            bold: true,
            alignStart: alignStart,
            thick: true,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    String leftLabel,
    TextEditingController controller,
    String rightLabel, {
    double height = 32,
    int maxLines = 1,
  }) {
    return Row(
      children: [
        SizedBox(width: 184, child: _labelCell(leftLabel, height: height)),
        Expanded(
          child: _valueCell(controller, height: height, maxLines: maxLines),
        ),
        SizedBox(width: 184, child: _labelCell(rightLabel, height: height)),
      ],
    );
  }

  Widget _dateRow(
    String leftLabel,
    TextEditingController controller,
    String rightLabel,
  ) {
    return Row(
      children: [
        SizedBox(width: 184, child: _labelCell(leftLabel, height: 32)),
        Expanded(
          child: _valueCell(
            controller,
            height: 32,
            fillColor: const Color(0xFFE0E0E0),
          ),
        ),
        SizedBox(width: 184, child: _labelCell(rightLabel, height: 32)),
      ],
    );
  }

  Widget _labelCell(
    String text, {
    required double height,
    bool bold = false,
    bool alignStart = false,
    bool thick = false,
  }) {
    return Container(
      height: height,
      alignment: alignStart ? Alignment.centerLeft : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bold ? const Color(0xFFF7F7F7) : Colors.white.withValues(alpha: 0.95),
        border: Border.all(color: Colors.black, width: thick ? 1.4 : .8),
      ),
      child: Text(
        text,
        textAlign: alignStart ? TextAlign.start : TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _valueCell(
    TextEditingController controller, {
    required double height,
    int maxLines = 1,
    Color? fillColor,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: fillColor ?? Colors.white.withValues(alpha: 0.95),
        border: Border.all(color: Colors.black, width: .8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: maxLines,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12.5),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  void _clear() {
    for (final controller in [
      _employeeName,
      _idNumber,
      _position,
      _applicationDate,
      _annualLeave,
      _emergencyLeave,
      _numberOfDays,
      _fromDate,
      _toDate,
      _addressInLeave,
      _applicantSignature,
      _replacedEmployeeName,
      _contactDuringLeave,
      _replacedSignature,
      _lineManagerSignature,
      _joiningDate,
      _laterAccruedAnnualLeave,
      _previousBalance,
      _newBalance,
      _benefitTickets,
      _deserve,
      _doesNotDeserve,
      _hrDepartment,
      _departmentManagerSignature,
    ]) {
      controller.clear();
    }
    _applicationDate.text = _formatDate(DateTime.now());
    _joiningDate.text = '2025-05-12';
    _laterAccruedAnnualLeave.text = '2026-05-31';
    _previousBalance.text = '0';
    _newBalance.text = '0';
    _benefitTickets.text = '0';
    _deserve.text = 'نعم';
    setState(() {
      _selectedEmployeeId = null;
    });
  }

  void _clearFilledEmployee() {
    setState(() {
      _selectedEmployeeId = null;
    });
  }

  Future<void> _loadEmployees() async {
    try {
      final items = await AppDI.employeesRepo.fetchEmployeeLookup(limit: 200);
      if (!mounted) return;
      setState(() {
        _employeeOptions = items;
        _loadingEmployees = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _employeeOptions = const [];
        _loadingEmployees = false;
      });
    }
  }

  Future<void> _fillFromEmployee(String employeeId) async {
    setState(() {
      _selectedEmployeeId = employeeId;
      _fillingEmployee = true;
    });
    try {
      final profile = await AppDI.employeesRepo.fetchEmployeeProfile(
        employeeId: employeeId,
      );
      if (!mounted) return;
      _applyEmployeeProfile(profile);
      setState(() {
        _fillingEmployee = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fillingEmployee = false;
      });
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
  }

  void _applyEmployeeProfile(EmployeeProfileDetails profile) {
    _employeeName.text = profile.fullName;
    _idNumber.text = profile.nationalId ?? '';
    _position.text = profile.jobTitleName ?? '';
    _applicationDate.text = _formatDate(DateTime.now());
    _joiningDate.text = _formatDate(profile.hireDate);
    _hrDepartment.text = profile.departmentName ?? '';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _downloadPdf(BuildContext context, bool isArabic) async {
    await HrFormFileService.savePdf(
      context,
      suggestedName: 'leave_application_form.pdf',
      buildBytes: () => buildLeaveApplicationPdf(
        isArabic: isArabic,
        employeeName: _employeeName.text,
        idNumber: _idNumber.text,
        position: _position.text,
        applicationDate: _applicationDate.text,
        annualLeave: _annualLeave.text,
        emergencyLeave: _emergencyLeave.text,
        numberOfDays: _numberOfDays.text,
        fromDate: _fromDate.text,
        toDate: _toDate.text,
        addressInLeave: _addressInLeave.text,
        applicantSignature: _applicantSignature.text,
        replacedEmployeeName: _replacedEmployeeName.text,
        contactDuringLeave: _contactDuringLeave.text,
        replacedSignature: _replacedSignature.text,
        lineManagerSignature: _lineManagerSignature.text,
        joiningDate: _joiningDate.text,
        laterAccruedAnnualLeave: _laterAccruedAnnualLeave.text,
        previousBalance: _previousBalance.text,
        newBalance: _newBalance.text,
        benefitTickets: _benefitTickets.text,
        deserve: _deserve.text,
        doesNotDeserve: _doesNotDeserve.text,
        hrDepartment: _hrDepartment.text,
        departmentManagerSignature: _departmentManagerSignature.text,
      ),
      successMessage: isArabic
          ? 'تم حفظ نموذج طلب الإجازة بصيغة PDF'
          : 'Leave application form saved as PDF',
    );
  }
}

class _LeaveGridPainter extends CustomPainter {
  const _LeaveGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.6;

    const spacing = 28.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LeaveGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
