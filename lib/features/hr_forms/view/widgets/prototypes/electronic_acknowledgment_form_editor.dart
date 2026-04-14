import 'package:flutter/material.dart';

import '../hr_form_shell.dart';
import 'shared/electronic_form_frame.dart';

class ElectronicAcknowledgmentFormEditor extends StatefulWidget {
  const ElectronicAcknowledgmentFormEditor({super.key});

  @override
  State<ElectronicAcknowledgmentFormEditor> createState() =>
      _ElectronicAcknowledgmentFormEditorState();
}

class _ElectronicAcknowledgmentFormEditorState
    extends State<ElectronicAcknowledgmentFormEditor> {
  final _employeeName = TextEditingController();
  final _employeeId = TextEditingController();
  final _mobile = TextEditingController();
  final _role = TextEditingController();
  final _department = TextEditingController();
  final _signature = TextEditingController();

  @override
  void dispose() {
    for (final controller in [
      _employeeName,
      _employeeId,
      _mobile,
      _role,
      _department,
      _signature,
    ]) {
      controller.dispose();
    }
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
        child: ElectronicFormFrame(
          title: isArabic ? 'إقرار وتعهد الموظف' : 'Employee Acknowledgment',
          subtitle: isArabic
              ? 'تصميم إلكتروني مرن لمراجعة العميل واعتماد الاتجاه البصري'
              : 'A flexible electronic layout for client review and visual direction approval',
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
                          ? 'هذا نموذج تجريبي بصري، وسنربط الحفظ والتصدير بعد اعتماد الشكل.'
                          : 'This is a visual prototype. Save/export will be connected after design approval.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.science_outlined),
              label: Text(isArabic ? 'وضع تجريبي' : 'Prototype Mode'),
            ),
          ],
          child: Column(
            children: [
              ElectronicSectionCard(
                title: isArabic ? 'ملخص سريع' : 'Quick Summary',
                hint: isArabic ? 'واجهة عرض' : 'Preview Surface',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _infoChip(
                      isArabic ? 'سري / داخلي' : 'Confidential / Internal',
                      const Color(0xFFEBF7F2),
                      const Color(0xFF2F7F66),
                    ),
                    _infoChip(
                      isArabic ? 'اعتماد موظف' : 'Employee Acknowledgment',
                      const Color(0xFFF0F8FB),
                      const Color(0xFF2E6E86),
                    ),
                    _infoChip(
                      isArabic ? 'نسخة للعميل' : 'Client Review Copy',
                      const Color(0xFFF8F4EA),
                      const Color(0xFF8B6A2D),
                    ),
                  ],
                ),
              ),
              ElectronicSectionCard(
                title: isArabic ? 'بيانات الموظف' : 'Employee Information',
                hint: isArabic ? 'تجريبي' : 'Prototype',
                child: Column(
                  children: [
                    _row([
                      _field(
                        _employeeName,
                        isArabic ? 'اسم الموظف' : 'Employee Name',
                      ),
                      _field(
                        _employeeId,
                        isArabic ? 'رقم الهوية / الإقامة' : 'ID / Iqama Number',
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _row([
                      _field(_department, isArabic ? 'القسم' : 'Department'),
                      _field(_role, isArabic ? 'المسمى الوظيفي' : 'Job Title'),
                    ]),
                    const SizedBox(height: 14),
                    _row([
                      _field(
                        _mobile,
                        isArabic ? 'رقم الجوال' : 'Mobile Number',
                      ),
                    ]),
                  ],
                ),
              ),
              ElectronicSectionCard(
                title: isArabic ? 'بنود الإقرار' : 'Acknowledgment Clauses',
                hint: isArabic ? 'صياغة تجريبية' : 'Prototype Copy',
                child: Column(
                  children: [
                    _clauseCard(
                      index: '01',
                      title: isArabic
                          ? 'سرية المعلومات'
                          : 'Information Confidentiality',
                      body: isArabic
                          ? 'أقر بأن جميع البيانات والملفات والسجلات التي أطلع عليها خلال عملي تعتبر معلومات داخلية تخص المؤسسة، وأتعهد بالمحافظة عليها وعدم نسخها أو مشاركتها إلا في حدود صلاحياتي العلمي.'
                          : 'I acknowledge that all records, files, and internal materials accessed during my work are confidential and may only be used within my authorized scope.',
                    ),
                    const SizedBox(height: 12),
                    _clauseCard(
                      index: '02',
                      title: isArabic
                          ? 'عدم الاحتفاظ أو الإفشاء'
                          : 'No Retention or Disclosure',
                      body: isArabic
                          ? 'أتعهد بعدم الاحتفاظ بأي نسخة من المعلومات أو المستندات الخاصة بالمؤسسة بعد انتهاء الحاجة العملية إليها، سواء خلال العمل أو بعد انتهاء العلاقة التعاقدية.'
                          : 'I undertake not to retain or disclose company documents or data beyond operational need, whether during employment or after it ends.',
                    ),
                    const SizedBox(height: 12),
                    _clauseCard(
                      index: '03',
                      title: isArabic
                          ? 'المسؤولية النظامية'
                          : 'Administrative Responsibility',
                      body: isArabic
                          ? 'في حال مخالفة ذلك، أتحمل كامل المسؤولية الإدارية والنظامية عن أي أضرار أو التزامات تنشأ نتيجة الإخلال بهذا الإقرار.'
                          : 'In case of breach, I bear full administrative and legal responsibility for any resulting damage or violation.',
                    ),
                  ],
                ),
              ),
              ElectronicSectionCard(
                title: isArabic ? 'الاعتماد' : 'Approval',
                hint: isArabic ? 'حقل توقيع' : 'Signature Area',
                child: _row([
                  _field(
                    _signature,
                    isArabic ? 'توقيع الموظف' : 'Employee Signature',
                    minLines: 3,
                  ),
                ]),
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
        color: const Color(0xFFF8FCFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCCE3DC)),
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
              color: Color(0xFF45655D),
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

  Widget _clauseCard({
    required String index,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD2E7E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF3B8D72),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              index,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF264E43),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }

  void _clear() {
    for (final controller in [
      _employeeName,
      _employeeId,
      _mobile,
      _role,
      _department,
      _signature,
    ]) {
      controller.clear();
    }
    setState(() {});
  }
}
