import 'package:flutter/material.dart';

import '../../domain/models/hr_form_template_def.dart';
import '../widgets/prototypes/electronic_acknowledgment_form_editor.dart';
import '../widgets/prototypes/electronic_leave_request_form_editor.dart';

class HrFormEditorPage extends StatelessWidget {
  const HrFormEditorPage({super.key, required this.templateId});

  final String templateId;

  @override
  Widget build(BuildContext context) {
    final template = findHrFormTemplate(templateId);
    if (template == null) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      return Center(
        child: Text(isArabic ? 'النموذج غير موجود' : 'Template not found'),
      );
    }

    switch (templateId) {
      case acknowledgmentPrototypeTemplateId:
        return const ElectronicAcknowledgmentFormEditor();
      case leavePrototypeTemplateId:
        return const ElectronicLeaveRequestFormEditor();
      default:
        return const SizedBox.shrink();
    }
  }
}
