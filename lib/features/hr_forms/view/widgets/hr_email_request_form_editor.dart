import 'package:flutter/material.dart';

import '../../../../core/di/app_di.dart';
import '../../../employees/domain/models/employee_lookup.dart';
import '../../../employees/domain/models/employee_profile_details.dart';
import '../services/hr_email_request_pdf_builder.dart';
import '../services/hr_form_file_service.dart';
import 'hr_form_shell.dart';

class HrEmailRequestFormEditor extends StatefulWidget {
  const HrEmailRequestFormEditor({super.key});

  @override
  State<HrEmailRequestFormEditor> createState() =>
      _HrEmailRequestFormEditorState();
}

class _HrEmailRequestFormEditorState extends State<HrEmailRequestFormEditor> {
  final _employeeName = TextEditingController();
  final _employeeNumber = TextEditingController();
  final _department = TextEditingController();
  final _jobTitle = TextEditingController();
  final _employeeSignature = TextEditingController();
  final _firstNameCaps = TextEditingController();
  final _familyNameCaps = TextEditingController();
  final _location = TextEditingController();
  final _officeAddress = TextEditingController();
  final _companyMobile = TextEditingController();
  final _emailAddress = TextEditingController();
  final _lineManagerSignature = TextEditingController();
  final _hrSignature = TextEditingController();
  final _itSignature = TextEditingController();

  List<EmployeeLookup> _employeeOptions = const [];
  String? _selectedEmployeeId;
  bool _loadingEmployees = true;
  bool _fillingEmployee = false;

  static const _paperBorder = Color(0xFF1E1E1E);
  static const _accent = Color(0xFFD9EFEA);
  static const _mutedFill = Color(0xFFF4F7F6);

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    for (final controller in [
      _employeeName,
      _employeeNumber,
      _department,
      _jobTitle,
      _employeeSignature,
      _firstNameCaps,
      _familyNameCaps,
      _location,
      _officeAddress,
      _companyMobile,
      _emailAddress,
      _lineManagerSignature,
      _hrSignature,
      _itSignature,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return HrFormShell(
      title: isArabic ? 'طلب بريد إلكتروني' : 'Email Registration Request',
      subtitle: isArabic
          ? 'النموذج قابل للتعبئة والطباعة كما هو، سواء كان فارغًا أو مكتمل البيانات.'
          : 'This form can be filled digitally and printed either blank or completed.',
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
        width: 900,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _paperBorder.withValues(alpha: 0.18)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _employeePicker(isArabic),
            const SizedBox(height: 16),
            _header(isArabic),
            const SizedBox(height: 18),
            _requestBlock(),
            const SizedBox(height: 16),
            _detailsBlock(),
            const SizedBox(height: 18),
            _signaturesBlock(),
            const SizedBox(height: 20),
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

  Widget _employeePicker(bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF8),
        borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(12),
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

  Widget _header(bool isArabic) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            isArabic ? 'طلب\nبريد\nإلكتروني' : 'Email\nRequest',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ),
        const Spacer(),
        Column(
          children: [Image.asset('assets/images/fullLogo.png', width: 148)],
        ),
        const Spacer(),
        const SizedBox(width: 92),
      ],
    );
  }

  Widget _requestBlock() {
    return Container(
      decoration: _outerBorder(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: const [
                Text(
                  'يرجى عمل بريد إلكتروني للموظف التالي',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Please Email Registration for the following employee',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _cell(
                  arLabel: 'اسم الموظف',
                  enLabel: 'Employee Name',
                  controller: _employeeName,
                  minHeight: 64,
                  labelWidth: 180,
                ),
              ),
              Expanded(
                child: _cell(
                  arLabel: 'رقم الموظف',
                  enLabel: 'Employee No.',
                  controller: _employeeNumber,
                  minHeight: 64,
                  labelWidth: 180,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _cell(
                  arLabel: 'القسم',
                  enLabel: 'Department',
                  controller: _department,
                  minHeight: 64,
                  labelWidth: 180,
                ),
              ),
              Expanded(
                child: _cell(
                  arLabel: 'المسمى الوظيفي',
                  enLabel: 'Job Title',
                  controller: _jobTitle,
                  minHeight: 64,
                  labelWidth: 180,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _cell(
                  arLabel: 'التوقيع',
                  enLabel: 'Signature',
                  controller: _employeeSignature,
                  minHeight: 64,
                  labelWidth: 180,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailsBlock() {
    return Container(
      decoration: _outerBorder(),
      child: Column(
        children: [
          _fullWidthRow(
            label: 'First name (in caps)',
            controller: _firstNameCaps,
          ),
          _fullWidthRow(
            label: 'Family name (in caps)',
            controller: _familyNameCaps,
          ),
          _fullWidthRow(label: 'Job Title', controller: _jobTitle),
          _fullWidthRow(label: 'Location', controller: _location),
          _fullWidthRow(label: 'Office Address', controller: _officeAddress),
          _fullWidthRow(label: 'Company Mobile', controller: _companyMobile),
          _fullWidthRow(
            label: 'Email Address: First name . Family Name @dimahmusic.com',
            controller: _emailAddress,
            minHeight: 66,
            labelWidth: 320,
            labelFontSize: 12.2,
          ),
        ],
      ),
    );
  }

  Widget _signaturesBlock() {
    return Container(
      decoration: _outerBorder(),
      child: Row(
        children: [
          Expanded(
            child: _signatureCell(
              arLabel: 'توقيع المدير المباشر',
              enLabel: 'Line Manager Signature',
              controller: _lineManagerSignature,
              drawLeftBorder: true,
            ),
          ),
          Expanded(
            child: _signatureCell(
              arLabel: 'توقيع مدير الموارد البشرية',
              enLabel: 'Human Resources Department',
              controller: _hrSignature,
              drawLeftBorder: true,
            ),
          ),
          Expanded(
            child: _signatureCell(
              arLabel: 'قسم التقنية',
              enLabel: 'Information Technology',
              controller: _itSignature,
              drawRightBorder: false,
              drawLeftBorder: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fullWidthRow({
    required String label,
    required TextEditingController controller,
    double minHeight = 54,
    double labelWidth = 240,
    double labelFontSize = 14,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            constraints: BoxConstraints(minHeight: minHeight),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(border: Border(top: _gridSide())),
            child: TextField(
              controller: controller,
              textAlign: TextAlign.left,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 15, height: 1.3),
            ),
          ),
        ),
        Container(
          width: labelWidth,
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _mutedFill,
            border: Border(
              top: _gridSide(),
              left: _gridSide(),
              right: _gridSide(),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _signatureCell({
    required String arLabel,
    required String enLabel,
    required TextEditingController controller,
    bool drawRightBorder = true,
    bool drawLeftBorder = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 138),
      decoration: BoxDecoration(
        border: Border(
          left: drawLeftBorder ? _gridSide() : BorderSide.none,
          right: drawRightBorder ? _gridSide() : BorderSide.none,
          bottom: _gridSide(),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: _mutedFill,
            child: Column(
              children: [
                Text(
                  arLabel,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  enLabel,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              decoration: BoxDecoration(border: Border(top: _gridSide())),
              padding: const EdgeInsets.only(top: 10),
              child: TextField(
                controller: controller,
                minLines: 3,
                maxLines: 4,
                textAlign: TextAlign.left,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell({
    required String arLabel,
    required String enLabel,
    required TextEditingController controller,
    double minHeight = 58,
    double labelWidth = 160,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        border: Border(top: _gridSide(), right: _gridSide()),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: BoxConstraints(minHeight: minHeight),
              decoration: BoxDecoration(border: Border(left: _gridSide())),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: TextField(
                controller: controller,
                textAlign: TextAlign.left,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          SizedBox(
            width: labelWidth,
            child: Container(
              constraints: BoxConstraints(minHeight: minHeight),
              decoration: BoxDecoration(
                color: _mutedFill,
                border: Border(left: _gridSide()),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    arLabel,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    enLabel,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _outerBorder() {
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _paperBorder, width: 1.35),
    );
  }

  BorderSide _gridSide() {
    return BorderSide(color: _paperBorder.withValues(alpha: 0.78), width: 1);
  }

  void _clear() {
    for (final controller in [
      _employeeName,
      _employeeNumber,
      _department,
      _jobTitle,
      _employeeSignature,
      _firstNameCaps,
      _familyNameCaps,
      _location,
      _officeAddress,
      _companyMobile,
      _emailAddress,
      _lineManagerSignature,
      _hrSignature,
      _itSignature,
    ]) {
      controller.clear();
    }
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
    final parts = _splitName(profile.fullName);
    _employeeName.text = profile.fullName;
    _employeeNumber.text = profile.nationalId ?? '';
    _department.text = profile.departmentName ?? '';
    _jobTitle.text = profile.jobTitleName ?? '';
    _firstNameCaps.text = parts.$1.toUpperCase();
    _familyNameCaps.text = parts.$2.toUpperCase();
    _location.text = [
      profile.city,
      profile.country,
    ].where((value) => (value ?? '').trim().isNotEmpty).join(', ');
    _officeAddress.text = profile.address ?? '';
    _companyMobile.text = profile.phone;
    _emailAddress.text = profile.email;
  }

  (String, String) _splitName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }

  Future<void> _downloadPdf(BuildContext context, bool isArabic) async {
    await HrFormFileService.savePdf(
      context,
      suggestedName: 'email_request_form.pdf',
      buildBytes: () => buildEmailRequestFormPdf(
        isArabic: isArabic,
        employeeName: _employeeName.text,
        employeeNumber: _employeeNumber.text,
        department: _department.text,
        jobTitle: _jobTitle.text,
        employeeSignature: _employeeSignature.text,
        firstNameCaps: _firstNameCaps.text,
        familyNameCaps: _familyNameCaps.text,
        location: _location.text,
        officeAddress: _officeAddress.text,
        companyMobile: _companyMobile.text,
        emailAddress: _emailAddress.text,
        lineManagerSignature: _lineManagerSignature.text,
        hrSignature: _hrSignature.text,
        itSignature: _itSignature.text,
      ),
      successMessage: isArabic
          ? 'تم حفظ نموذج طلب البريد بصيغة PDF'
          : 'Email request form saved as PDF',
    );
  }
}
