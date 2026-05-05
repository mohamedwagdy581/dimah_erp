import 'package:flutter/material.dart';

import '../../services/hr_form_preview_service.dart';
import '../hr_form_shell.dart';
import 'electronic_leave_request/electronic_leave_request_form_body.dart';
import 'electronic_leave_request/electronic_leave_request_form_controller.dart';

class ElectronicLeaveRequestFormEditor extends StatefulWidget {
  const ElectronicLeaveRequestFormEditor({super.key});

  @override
  State<ElectronicLeaveRequestFormEditor> createState() =>
      _ElectronicLeaveRequestFormEditorState();
}

class _ElectronicLeaveRequestFormEditorState
    extends State<ElectronicLeaveRequestFormEditor> {
  late final ElectronicLeaveRequestFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ElectronicLeaveRequestFormController()..initialize();
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
          ? 'طلب إجازة إلكتروني'
          : 'Prototype - Electronic Leave Request',
      subtitle: isArabic
          ? 'نسخة تصميمية لتجربة الاتجاه البصري مع العميل'
          : 'A more digital leave request prototype to test visual direction with the client.',
      actions: const [],
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return ElectronicLeaveRequestFormBody(
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
          ? 'معاينة تصميم طلب إجازة إلكتروني'
          : 'Electronic Leave Request Preview',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return ElectronicLeaveRequestFormBody(
            controller: _controller,
            isArabic: isArabic,
            readOnly: true,
          );
        },
      ),
    );
  }
}
