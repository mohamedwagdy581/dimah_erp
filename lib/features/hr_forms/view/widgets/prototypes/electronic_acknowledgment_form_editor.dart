import 'package:flutter/material.dart';

import '../../services/hr_form_preview_service.dart';
import '../hr_form_shell.dart';
import 'electronic_acknowledgment/electronic_acknowledgment_form_body.dart';
import 'electronic_acknowledgment/electronic_acknowledgment_form_controller.dart';

class ElectronicAcknowledgmentFormEditor extends StatefulWidget {
  const ElectronicAcknowledgmentFormEditor({super.key});

  @override
  State<ElectronicAcknowledgmentFormEditor> createState() =>
      _ElectronicAcknowledgmentFormEditorState();
}

class _ElectronicAcknowledgmentFormEditorState
    extends State<ElectronicAcknowledgmentFormEditor> {
  late final ElectronicAcknowledgmentFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ElectronicAcknowledgmentFormController()..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return ElectronicAcknowledgmentFormBody(
              controller: _controller,
              isArabic: isArabic,
              readOnly: false,
              onClear: _controller.clear,
              onOpenPreview: () => _openDesignPreview(context, isArabic),
              onSelectEmployee: _controller.loadingEmployees ||
                      _controller.fillingEmployee
                  ? null
                  : _handleSelectEmployee,
              onClearSelection: _controller.fillingEmployee
                  ? null
                  : _controller.clearFilledEmployee,
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleSelectEmployee(String employeeId) async {
    final ok = await _controller.fillFromEmployee(employeeId);
    if (!mounted || ok) return;
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

  Future<void> _openDesignPreview(BuildContext context, bool isArabic) async {
    await HrFormPreviewService.openDesignPreview(
      context,
      title: isArabic
          ? 'معاينة الإقرار الإلكتروني التجريبي'
          : 'Electronic Acknowledgment Preview',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return ElectronicAcknowledgmentFormBody(
            controller: _controller,
            isArabic: isArabic,
            readOnly: true,
          );
        },
      ),
    );
  }
}
