import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../../../core/utils/safe_file_picker.dart';
import '../../../../employee_portal/view/widgets/my_tasks/task_formatters.dart';

class GovernmentAlertDraft {
  const GovernmentAlertDraft({
    required this.title,
    required this.alertType,
    required this.startDate,
    required this.endDate,
    this.description,
    this.fileName,
    this.fileBytes,
    this.mimeType,
  });

  final String title;
  final String alertType;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final String? fileName;
  final List<int>? fileBytes;
  final String? mimeType;
}

Future<GovernmentAlertDraft?> showGovernmentAlertDialog(BuildContext context) {
  return showDialog<GovernmentAlertDraft>(
    context: context,
    builder: (_) => const _GovernmentAlertDialog(),
  );
}

Future<GovernmentAlertDraft?> showEditGovernmentAlertDialog(
  BuildContext context, {
  required GovernmentAlertDraft initialDraft,
  required String title,
  required String submitLabel,
}) {
  return showDialog<GovernmentAlertDraft>(
    context: context,
    builder: (_) => _GovernmentAlertDialog(
      initialDraft: initialDraft,
      dialogTitle: title,
      submitLabel: submitLabel,
    ),
  );
}

class _GovernmentAlertDialog extends StatefulWidget {
  const _GovernmentAlertDialog({
    this.initialDraft,
    this.dialogTitle,
    this.submitLabel,
  });

  final GovernmentAlertDraft? initialDraft;
  final String? dialogTitle;
  final String? submitLabel;

  @override
  State<_GovernmentAlertDialog> createState() => _GovernmentAlertDialogState();
}

class _GovernmentAlertDialogState extends State<_GovernmentAlertDialog> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late String _type;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _fileName;
  List<int>? _fileBytes;
  String? _mimeType;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDraft;
    _title = TextEditingController(text: initial?.title ?? '');
    _description = TextEditingController(text: initial?.description ?? '');
    _type = initial?.alertType ?? 'office_lease';
    _startDate = initial?.startDate;
    _endDate = initial?.endDate;
    _fileName = initial?.fileName;
    _fileBytes = initial?.fileBytes;
    _mimeType = initial?.mimeType;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return AlertDialog(
      title: Text(
        widget.dialogTitle ??
            (isArabic ? 'إضافة تنبيه حكومي' : 'Add Government Alert'),
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: InputDecoration(labelText: isArabic ? 'الاسم' : 'Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              items: _types(isArabic)
                  .map((item) => DropdownMenuItem<String>(
                        value: item.key,
                        child: Text(item.value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _type = value);
              },
              decoration: InputDecoration(labelText: isArabic ? 'النوع' : 'Type'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: InputDecoration(labelText: isArabic ? 'الوصف' : 'Description'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(start: true),
                    child: Text(
                      _startDate == null
                          ? (isArabic ? 'تاريخ البداية' : 'Start Date')
                          : dateOnly(_startDate!.toIso8601String()),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(start: false),
                    child: Text(
                      _endDate == null
                          ? (isArabic ? 'تاريخ النهاية' : 'End Date')
                          : dateOnly(_endDate!.toIso8601String()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file_outlined),
                  label: Text(isArabic ? 'إرفاق ملف' : 'Attach File'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fileName ?? (isArabic ? 'لم يتم اختيار ملف' : 'No file selected'),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.submitLabel ?? (isArabic ? 'حفظ' : 'Save')),
        ),
      ],
    );
  }

  List<MapEntry<String, String>> _types(bool isArabic) => [
        MapEntry('commercial_registration', isArabic ? 'السجل التجاري' : 'Commercial Registration'),
        MapEntry('office_lease', isArabic ? 'إيجار المكتب' : 'Office Lease'),
        MapEntry('medical_insurance', isArabic ? 'التأمين الصحي' : 'Medical Insurance'),
        MapEntry('social_insurance', isArabic ? 'التأمينات الاجتماعية' : 'Social Insurance'),
        MapEntry('qiwa_subscription', isArabic ? 'اشتراك منصة قوى' : 'Qiwa Subscription'),
        MapEntry('mudad_subscription', isArabic ? 'اشتراك منصة مدد' : 'Mudad Subscription'),
        MapEntry('muqeem_subscription', isArabic ? 'اشتراك منصة مقيم' : 'Muqeem Subscription'),
        MapEntry('other', isArabic ? 'أخرى' : 'Other'),
      ];

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickFile() async {
    final file = await SafeFilePicker.openSingle(
      context: context,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Attachments', extensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx']),
      ],
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _fileName = file.name;
      _fileBytes = bytes;
      _mimeType = contentTypeFor(file.name);
    });
  }

  void _submit() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (_title.text.trim().isEmpty) {
      setState(() => _error = isArabic ? 'الاسم مطلوب' : 'Name is required');
      return;
    }
    if (_startDate == null || _endDate == null) {
      setState(() => _error = isArabic ? 'تاريخ البداية والنهاية مطلوبان' : 'Start and end dates are required');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      setState(() => _error = isArabic ? 'تاريخ النهاية يجب أن يكون بعد تاريخ البداية' : 'End date must be after start date');
      return;
    }
    Navigator.of(context).pop(
      GovernmentAlertDraft(
        title: _title.text.trim(),
        alertType: _type,
        startDate: _startDate!,
        endDate: _endDate!,
        description: _description.text.trim(),
        fileName: _fileName,
        fileBytes: _fileBytes,
        mimeType: _mimeType,
      ),
    );
  }
}
