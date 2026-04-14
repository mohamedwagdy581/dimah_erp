import 'package:flutter/material.dart';

import '../hr_form_shell.dart';
import 'shared/electronic_form_frame.dart';

class ElectronicLeaveRequestFormEditor extends StatefulWidget {
  const ElectronicLeaveRequestFormEditor({super.key});

  @override
  State<ElectronicLeaveRequestFormEditor> createState() =>
      _ElectronicLeaveRequestFormEditorState();
}

class _ElectronicLeaveRequestFormEditorState
    extends State<ElectronicLeaveRequestFormEditor> {
  final _employeeName = TextEditingController();
  final _employeeId = TextEditingController();
  final _position = TextEditingController();
  final _leaveType = TextEditingController();
  final _fromDate = TextEditingController();
  final _toDate = TextEditingController();
  final _days = TextEditingController();
  final _replacement = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    for (final controller in [
      _employeeName,
      _employeeId,
      _position,
      _leaveType,
      _fromDate,
      _toDate,
      _days,
      _replacement,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return HrFormShell(
      title: isArabic ? 'نموذج تجريبي - طلب إجازة إلكتروني' : 'Prototype - Electronic Leave Request',
      subtitle: isArabic
          ? 'نسخة تجريبية أكثر إلكترونية ووضوحًا لطلب الإجازة لاختبار الذوق البصري مع العميل.'
          : 'A more digital leave request prototype to test visual direction with the client.',
      actions: const [],
      child: Center(
        child: ElectronicFormFrame(
          title: isArabic ? 'طلب إجازة' : 'Leave Request',
          subtitle: isArabic
              ? 'نسخة تصميمية للتجربة قبل اعتماد الشكل النهائي'
              : 'Design prototype before final approval',
          actions: [
            OutlinedButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.refresh),
              label: Text(isArabic ? 'تفريغ' : 'Clear'),
            ),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isArabic
                          ? 'هذا نموذج تجريبي مستقل، ولن يؤثر على نموذج الإجازة الرسمي الحالي.'
                          : 'This is a separate prototype and will not affect the current official leave form.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(isArabic ? 'تجربة العميل' : 'Client Preview'),
            ),
          ],
          child: Column(
            children: [
              ElectronicSectionCard(
                title: isArabic ? 'بيانات الموظف' : 'Employee Information',
                child: Column(
                  children: [
                    _row([
                      _field(_employeeName, isArabic ? 'اسم الموظف' : 'Employee Name'),
                      _field(_employeeId, isArabic ? 'الرقم الوظيفي' : 'Employee ID'),
                    ]),
                    const SizedBox(height: 14),
                    _row([
                      _field(_position, isArabic ? 'المسمى الوظيفي' : 'Job Title'),
                    ]),
                  ],
                ),
              ),
              ElectronicSectionCard(
                title: isArabic ? 'تفاصيل الإجازة' : 'Leave Details',
                child: Column(
                  children: [
                    _row([
                      _field(_leaveType, isArabic ? 'نوع الإجازة' : 'Leave Type'),
                      _field(_days, isArabic ? 'عدد الأيام' : 'No. of Days'),
                    ]),
                    const SizedBox(height: 14),
                    _row([
                      _field(_fromDate, isArabic ? 'من تاريخ' : 'From Date'),
                      _field(_toDate, isArabic ? 'إلى تاريخ' : 'To Date'),
                    ]),
                  ],
                ),
              ),
              ElectronicSectionCard(
                title: isArabic ? 'التغطية أثناء الإجازة' : 'Coverage During Leave',
                child: Column(
                  children: [
                    _row([
                      _field(_replacement, isArabic ? 'الموظف البديل' : 'Replacement Employee'),
                    ]),
                    const SizedBox(height: 14),
                    _row([
                      _field(_notes, isArabic ? 'ملاحظات إضافية' : 'Additional Notes', minLines: 4),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int minLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCDE0E8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF486673),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            minLines: minLines,
            maxLines: minLines,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  void _clear() {
    for (final controller in [
      _employeeName,
      _employeeId,
      _position,
      _leaveType,
      _fromDate,
      _toDate,
      _days,
      _replacement,
      _notes,
    ]) {
      controller.clear();
    }
    setState(() {});
  }
}
