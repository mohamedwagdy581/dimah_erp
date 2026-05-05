import 'package:flutter/material.dart';

import '../../shared/electronic_form_theme.dart';
import '../../shared/electronic_section_card.dart';
import '../widgets/electronic_acknowledgment_clause_card.dart';

class ElectronicAcknowledgmentClausesSection extends StatelessWidget {
  const ElectronicAcknowledgmentClausesSection({
    super.key,
    required this.isArabic,
  });

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return ElectronicSectionCard(
      title: isArabic ? 'بنود الإقرار' : 'Acknowledgment Clauses',
      hint: isArabic ? 'صياغة تجريبية' : 'Prototype Copy',
      child: Column(
        children: [
          ElectronicAcknowledgmentClauseCard(
            index: '01',
            title: isArabic ? 'سرية المعلومات' : 'Information Confidentiality',
            body: isArabic
                ? 'أقر بأن جميع البيانات والملفات والسجلات التي أطلع عليها خلال عملي تعتبر معلومات داخلية تخص المؤسسة، وأتعهد بالمحافظة عليها وعدم نسخها أو مشاركتها إلا في حدود صلاحياتي العملية.'
                : 'I acknowledge that all records, files, and internal materials accessed during my work are confidential and may only be used within my authorized scope.',
          ),
          const SizedBox(height: ElectronicFormDimensions.sectionSpacing),
          ElectronicAcknowledgmentClauseCard(
            index: '02',
            title: isArabic
                ? 'عدم الاحتفاظ أو الإفشاء'
                : 'No Retention or Disclosure',
            body: isArabic
                ? 'أتعهد بعدم الاحتفاظ بأي نسخة من المعلومات أو المستندات الخاصة بالمؤسسة بعد انتهاء الحاجة العملية إليها، سواء خلال العمل أو بعد انتهاء العلاقة التعاقدية.'
                : 'I undertake not to retain or disclose company documents or data beyond operational need, whether during employment or after it ends.',
          ),
          const SizedBox(height: ElectronicFormDimensions.sectionSpacing),
          ElectronicAcknowledgmentClauseCard(
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
    );
  }
}
