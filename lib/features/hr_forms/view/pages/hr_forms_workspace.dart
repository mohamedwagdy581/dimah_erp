import 'package:erp_sys/core/ui/app_data_state.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/safe_file_picker.dart';
import '../../../employees/data/repos/hr_employees_repo.dart';
import '../../../employees/domain/models/employee.dart';
import '../../domain/models/hr_form_template_def.dart';
import '../../domain/models/hr_prototype_def.dart';
import '../../domain/models/hr_form_submission.dart';
import 'hr_prototype_editor.dart';
import '../../data/hr_form_drafts_repo.dart';
import 'hr_draft_history_dialog.dart';
import '../services/hr_form_file_service.dart';
import '../../../../core/ui/app_assets.dart';
import '../services/hr_portal_form_pdf.dart';

class HrFormsWorkspace extends StatefulWidget {
  const HrFormsWorkspace({
    super.key,
    this.loadEmployees,
    this.buildPdf,
    this.previewBuilder,
    this.exportPdf,
    this.today,
    this.draftsRepo,
    this.initialTemplateId,
  });
  final Future<HrEmployeesData> Function()? loadEmployees;
  final Future<Uint8List> Function(HrPortalFormDraft)? buildPdf;
  final Widget Function(Uint8List)? previewBuilder;
  final Future<void> Function(Uint8List, String)? exportPdf;
  final DateTime? today;
  final HrFormDraftsRepo? draftsRepo;
  final String? initialTemplateId;
  @override
  State<HrFormsWorkspace> createState() => _HrFormsWorkspaceState();
}

class _HrFormsWorkspaceState extends State<HrFormsWorkspace> {
  static const purple = Color(0xFF8654BC),
      ink = Color(0xFF21194E),
      border = Color(0xFFECE6F4);
  HrEmployeesData _data = const HrEmployeesData();
  final _templateScroll = ScrollController();
  bool _loading = true, _busy = false, _leave = false, _agreed = false;
  String? _error, _employeeId;
  final _statement = TextEditingController(),
      _signature = TextEditingController();
  final _notes = TextEditingController(),
      _replacement = TextEditingController(),
      _address = TextEditingController(),
      _contact = TextEditingController();
  DateTime? _from, _to;
  late DateTime _date;
  String _leaveType = 'annual';
  Future<Uint8List>? _pdf;
  HrPrototypeDef? _prototype;
  HrSavedDraft? _savedDraft;
  Map<String, dynamic> _prototypeData = {};
  String _baseline = '';
  bool _saving = false;
  bool get _submitted => _savedDraft != null && _savedDraft!.status != 'draft';
  Future<void> submitDraft() async {
    if (_saving || _busy || _submitted) return;
    final issue = hrFormSubmissionError(_templateId, _currentData, ar);
    if (issue != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(issue)));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('إرسال للاعتماد', 'Submit for approval')),
        content: Text(
          tr(
            'سيُرسل الطلب للمراجعين المناسبين: المدير ثم الموارد البشرية ثم الإدارة حسب المتاح. بعد الإرسال تصبح النسخة للعرض فقط. لا يُخصم رصيد الإجازة إلا عند الاعتماد النهائي.',
            'The request goes to the available manager, HR and Admin reviewers. This copy becomes read-only after submission. Leave balance changes only on final approval.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('إلغاء', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('تأكيد الإرسال', 'Confirm submission')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    if ((_savedDraft == null || _dirty) && !await saveDraft()) return;
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      final submitted = await draftsRepo.submit(_savedDraft!);
      if (!mounted) return;
      setState(() {
        _savedDraft = submitted;
        _baseline = hrDraftFingerprint(_currentData);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تم إرسال الطلب للاعتماد. تابع حالته من سجل الطلبات.',
              'Request submitted. Track it in request history.',
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hrFormWorkflowError(e is PostgrestException ? e.message : '', ar),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _editorGeneration = 0;
  HrFormDraftsRepo get draftsRepo =>
      widget.draftsRepo ?? SupabaseHrFormDraftsRepo(Supabase.instance.client);
  String get _templateId =>
      _prototype?.id ??
      (_leave ? leavePrototypeTemplateId : acknowledgmentPrototypeTemplateId);
  Map<String, dynamic> get _currentData => _prototype != null
      ? _prototypeData
      : {
          'employee_id': _employeeId,
          'statement': _statement.text,
          'signature': _signature.text,
          'notes': _notes.text,
          'replacement': _replacement.text,
          'address': _address.text,
          'contact': _contact.text,
          'from': _from?.toIso8601String(),
          'to': _to?.toIso8601String(),
          'date': _date.toIso8601String(),
          'leave_type': _leaveType,
          'agreed': _agreed,
        };
  bool get _dirty =>
      !_submitted &&
      _baseline.isNotEmpty &&
      hrDraftFingerprint(_currentData) != _baseline;
  Map<String, dynamic> blankPrototype(HrPrototypeDef? template) =>
      template == null
      ? {}
      : {
          'employee_id': null,
          'fields': {for (final f in template.fields) f.id: ''},
          'checks': {
            for (final f in template.fields)
              if (f.type == HrPrototypeFieldType.check) f.id: false,
          },
        };
  Future<void> newDraft() async {
    if (_saving || _busy || !await confirmChange() || !mounted) return;
    _debounce?.cancel();
    setState(() {
      _savedDraft = null;
      _prototypeData = blankPrototype(_prototype);
      _editorGeneration++;
      _pdf = null;
      _employeeId = null;
      _from = null;
      _to = null;
      _date = widget.today ?? DateTime.now();
      _leaveType = 'annual';
      _agreed = false;
      for (final c in [_signature, _notes, _replacement, _address, _contact]) {
        c.clear();
      }
      _statement.text = tr(
        'أقر بأنني اطلعت على سياسات وأنظمة الشركة وأتعهد بالالتزام بها.',
        'I have read the company policies and regulations and agree to comply with them.',
      );
      _baseline = hrDraftFingerprint(_currentData);
    });
  }

  Future<bool> saveDraft() async {
    if (_saving || _busy || _submitted) return false;
    final template = _templateId;
    final data = Map<String, dynamic>.from(_currentData);
    final snapshot = hrDraftFingerprint(data);
    setState(() => _saving = true);
    try {
      final saved = await draftsRepo.save(
        templateId: template,
        data: data,
        employeeId: data['employee_id'] as String?,
        previous: _savedDraft,
      );
      if (!mounted) return false;
      setState(() {
        _savedDraft = saved;
        _baseline = snapshot;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تم حفظ المسودة. يمكنك استكمالها من سجل المسودات.',
              'Draft saved. Resume it from draft history.',
            ),
          ),
        ),
      );
      return true;
    } catch (e) {
      if (mounted) {
        final conflict = e is PostgrestException && e.code == '40001';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              conflict
                  ? tr(
                      'المسودة اتغيرت من جلسة أخرى. افتح النسخة الأحدث من السجل قبل الحفظ.',
                      'This draft changed in another session. Reopen the latest version before saving.',
                    )
                  : tr(
                      'تعذر حفظ المسودة. بياناتك ما زالت في الشاشة؛ تحقق من الاتصال وتفعيل خدمة المسودات ثم حاول مجددًا.',
                      'Could not save. Your data remains on screen; check the connection and that draft storage is enabled, then retry.',
                    ),
            ),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> confirmChange() async {
    if (!_dirty) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('تعديلات غير محفوظة', 'Unsaved changes')),
        content: Text(
          tr(
            'احفظ المسودة قبل تغيير النموذج أو فتح مسودة أخرى.',
            'Save your draft before changing forms or opening another draft.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(tr('إلغاء', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text(tr('تجاهل التعديلات', 'Discard changes')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: Text(tr('حفظ المسودة', 'Save draft')),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    if (choice == 'save') return saveDraft();
    return choice == 'discard';
  }

  Future<void> selectTemplate(String id) async {
    if (_saving ||
        _busy ||
        id == _templateId ||
        !await confirmChange() ||
        !mounted) {
      return;
    }
    _debounce?.cancel();
    setState(() {
      _prototype = findHrPrototype(id);
      _leave = id == leavePrototypeTemplateId;
      _savedDraft = null;
      _prototypeData = blankPrototype(_prototype);
      _pdf = null;
      _editorGeneration++;
      _baseline = hrDraftFingerprint(_currentData);
    });
    refresh();
  }

  Future<void> openHistory() async {
    if (_saving || _busy || !await confirmChange() || !mounted) return;
    final saved = await showDialog<HrSavedDraft>(
      context: context,
      builder: (context) => HrDraftHistoryDialog(repo: draftsRepo),
    );
    if (!mounted || saved == null) return;
    _debounce?.cancel();
    setState(() {
      _savedDraft = saved;
      _prototype = findHrPrototype(saved.templateId);
      _leave = saved.templateId == leavePrototypeTemplateId;
      _prototypeData = Map<String, dynamic>.from(saved.data);
      _editorGeneration++;
      _pdf = null;
      if (_prototype == null) {
        final d = saved.data;
        _employeeId = _data.employees.any((e) => e.id == saved.employeeId)
            ? saved.employeeId
            : null;
        _statement.text = d['statement'] as String? ?? '';
        _signature.text = d['signature'] as String? ?? '';
        _notes.text = d['notes'] as String? ?? '';
        _replacement.text = d['replacement'] as String? ?? '';
        _address.text = d['address'] as String? ?? '';
        _contact.text = d['contact'] as String? ?? '';
        _from = DateTime.tryParse(d['from'] as String? ?? '');
        _to = DateTime.tryParse(d['to'] as String? ?? '');
        _date = DateTime.tryParse(d['date'] as String? ?? '') ?? DateTime.now();
        _leaveType =
            ['annual', 'sick', 'unpaid', 'other'].contains(d['leave_type'])
            ? d['leave_type'] as String
            : 'annual';
        _agreed = d['agreed'] == true;
      }
      _baseline = hrDraftFingerprint(_currentData);
    });
    refresh();
  }

  Timer? _debounce;
  bool _initialized = false;
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => ar ? a : e;
  Employee? get employee {
    final rows = _data.employees.where((e) => e.id == _employeeId);
    return rows.isEmpty ? null : rows.first;
  }

  String date(DateTime? d) => d == null
      ? '—'
      : '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  @override
  void initState() {
    super.initState();
    _date = widget.today ?? DateTime.now();
    _prototype = findHrPrototype(widget.initialTemplateId ?? '');
    _prototypeData = blankPrototype(_prototype);
    _leave = widget.initialTemplateId == leavePrototypeTemplateId;
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _statement.text = tr(
        'أقر أنا الموقّع أدناه بأنني قد اطلعت على سياسات وأنظمة الشركة، وأتعهد بالالتزام بجميع ما ورد فيها والعمل بموجبها.',
        'I have read the company policies and regulations and agree to comply with them.',
      );
      _baseline = hrDraftFingerprint(_currentData);
    }
  }

  @override
  void dispose() {
    _templateScroll.dispose();
    _debounce?.cancel();
    for (final c in [
      _statement,
      _signature,
      _notes,
      _replacement,
      _address,
      _contact,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data =
          await (widget.loadEmployees ??
              () => SupabaseHrEmployeesRepo(Supabase.instance.client).load())();
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  HrPortalFormDraft get draft => HrPortalFormDraft(
    isArabic: ar,
    isLeave: _leave,
    employeeName: employee?.fullName ?? '',
    employeeNumber: employee?.employeeNumber ?? '—',
    department: employee?.departmentName ?? '—',
    jobTitle: employee?.jobTitleName ?? '—',
    date: date(_date),
    agreed: _agreed,
    fields: _leave
        ? {
            tr('نوع الإجازة', 'Leave type'): leaveLabel(_leaveType),
            tr('من تاريخ', 'From'): date(_from),
            tr('إلى تاريخ', 'To'): date(_to),
            tr('المدة', 'Duration'): _from == null || _to == null
                ? '—'
                : '${_to!.difference(_from!).inDays + 1} ${tr('يوم', 'days')}',
            tr('سبب الإجازة / الملاحظات', 'Reason / notes'): _notes.text,
            tr('الموظف البديل', 'Replacement'): _replacement.text,
            tr('العنوان أثناء الإجازة', 'Address during leave'): _address.text,
            tr('التواصل أثناء الإجازة', 'Contact during leave'): _contact.text,
            tr('اسم الموقّع', 'Signatory'): _signature.text,
          }
        : {
            tr('نص الإقرار', 'Acknowledgment'): _statement.text,
            tr('اسم الموقّع', 'Signatory'): _signature.text,
          },
  );
  String leaveLabel(String value) => switch (value) {
    'annual' => tr('سنوية', 'Annual'),
    'sick' => tr('مرضية', 'Sick'),
    _ => tr('أخرى', 'Other'),
  };
  void refresh({bool delayed = false}) {
    if (_prototype != null) return;
    _debounce?.cancel();
    if (employee == null) {
      setState(() => _pdf = null);
      return;
    }
    void update() {
      if (mounted) {
        setState(() {
          _pdf = (widget.buildPdf ?? buildHrPortalFormPdf)(draft);
        });
      }
    }

    if (delayed) {
      _debounce = Timer(const Duration(milliseconds: 350), update);
    } else {
      update();
    }
  }

  Future<void> pickDate(String which) async {
    final initial = which == 'from'
        ? _from
        : which == 'to'
        ? _to
        : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (which == 'from') {
        _from = picked;
        if (_to?.isBefore(picked) == true) _to = picked;
      } else if (which == 'to') {
        _to = picked;
        if (_from?.isAfter(picked) == true) _from = picked;
      } else {
        _date = picked;
      }
    });
    refresh();
  }

  Future<void> pdfAction(bool export) async {
    if (_busy) return;
    String? error;
    if (employee == null) {
      error = tr('اختر الموظف أولًا', 'Choose an employee first');
    } else if (_leave && (_from == null || _to == null)) {
      error = tr(
        'حدد تاريخ بداية ونهاية الإجازة',
        'Choose leave start and end dates',
      );
    } else if (!_leave && _statement.text.trim().isEmpty) {
      error = tr('أدخل نص الإقرار', 'Enter the acknowledgment text');
    }
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    _debounce?.cancel();
    final snapshot = draft;
    final name =
        '${_leave ? 'leave_request' : 'acknowledgment'}_${employee!.employeeNumber ?? employee!.id}_${_date.year}-${_date.month}-${_date.day}.pdf';
    setState(() => _busy = true);
    try {
      final bytes = await (widget.buildPdf ?? buildHrPortalFormPdf)(snapshot);
      if (!mounted) return;
      setState(() {
        _pdf = Future.value(bytes);
      });
      if (export) {
        if (widget.exportPdf != null) {
          await widget.exportPdf!(bytes, name);
        } else {
          final location = await SafeFilePicker.saveLocation(
            context: context,
            suggestedName: name,
            acceptedTypeGroups: const [
              XTypeGroup(label: 'PDF', extensions: ['pdf']),
            ],
          );
          if (location != null) {
            await XFile.fromData(bytes, name: name).saveTo(location.path);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr('تم تصدير النموذج', 'Form exported')),
                ),
              );
            }
          }
        }
      } else {
        await HrFormFileService.openPdfPreview(
          context,
          title: name,
          buildBytes: () async => bytes,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${tr('تعذر تجهيز النموذج', 'Could not prepare the form')}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget heading(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
    );
    Widget panel(Widget child) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      // Transparent Material so ListTiles (e.g. the agreement checkbox) paint
      // their ink/selection above the panel's white background.
      child: Material(type: MaterialType.transparency, child: child),
    );
    InputDecoration decoration(String label) => InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFFCFAFF),
      contentPadding: const EdgeInsets.all(12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: border),
      ),
      border: const OutlineInputBorder(),
    );
    Widget input(
      String label,
      TextEditingController controller, {
      int lines = 1,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: !_busy && !_saving && !_submitted,
        maxLines: lines,
        style: const TextStyle(fontSize: 13, color: ink),
        decoration: decoration(label),
        onChanged: (_) => refresh(delayed: true),
      ),
    );
    Widget dateButton(
      String label,
      String key,
      DateTime? value,
    ) => OutlinedButton.icon(
      onPressed: _busy || _saving || _submitted ? null : () => pickDate(key),
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      icon: const Icon(Icons.calendar_month_outlined, size: 17),
      label: Text(
        '$label: ${date(value)}',
        style: const TextStyle(fontSize: 12),
      ),
    );
    final templates = panel(
      SizedBox(
        height: 600,
        child: Scrollbar(
          controller: _templateScroll,
          thumbVisibility: true,
          child: SingleChildScrollView(
            key: const ValueKey('hr-template-list-scroll'),
            controller: _templateScroll,
            primary: false,
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading(tr('قوالب النماذج', 'Form templates')),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    key: const ValueKey('hr-form-library'),
                    onPressed: _busy
                        ? null
                        : () => context.push(
                            AppRoutes.hrFormTemplate.replaceFirst(
                              ':templateId',
                              'library',
                            ),
                          ),
                    icon: const Icon(Icons.folder_copy_outlined),
                    label: Text(
                      tr(
                        'مكتبة النماذج — ${hrFormTemplates.length} نموذج',
                        'Forms library — ${hrFormTemplates.length} forms',
                      ),
                    ),
                  ),
                ),
                for (final leave in [false, true])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      key: ValueKey(leave ? 'template-leave' : 'template-ack'),
                      onTap: _busy || _saving
                          ? null
                          : () => selectTemplate(
                              leave
                                  ? leavePrototypeTemplateId
                                  : acknowledgmentPrototypeTemplateId,
                            ),
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _prototype == null && _leave == leave
                              ? const Color(0xFFF7F0FF)
                              : Colors.white,
                          border: Border.all(
                            color: _prototype == null && _leave == leave
                                ? purple
                                : border,
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0E3FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.file_copy_outlined,
                                color: purple,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              tr(
                                leave ? 'طلب إجازة' : 'إقرار إلكتروني',
                                leave
                                    ? 'Leave request'
                                    : 'Electronic acknowledgment',
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              tr(
                                leave
                                    ? 'نموذج طلب إجازة الموظف'
                                    : 'إقرار بسياسات وأنظمة الشركة',
                                leave
                                    ? 'Employee leave request form'
                                    : 'Company policies and regulations',
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF77738C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                for (final template in hrFormTemplates.skip(2))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      key: ValueKey('template-${template.id}'),
                      onTap: _busy || _saving
                          ? null
                          : () => selectTemplate(template.id),
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _prototype?.id == template.id
                              ? const Color(0xFFF7F0FF)
                              : Colors.white,
                          border: Border.all(
                            color: _prototype?.id == template.id
                                ? purple
                                : border,
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0E3FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                template.icon,
                                color: purple,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              template.title(ar),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              template.subtitle(ar),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF77738C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    final editor = _prototype != null
        ? HrPrototypeEditor(
            key: ValueKey('${_prototype!.id}-$_editorGeneration'),
            template: _prototype!,
            embedded: true,
            readOnly: _submitted || _saving,
            loadEmployees: widget.loadEmployees,
            exportPdf: widget.exportPdf,
            initialData: _prototypeData,
            onDraftChanged: (data) {
              _prototypeData = data;
            },
            onPreview: (future) {
              if (mounted) {
                setState(() {
                  _pdf = future;
                });
              }
            },
          )
        : Builder(
            key: ValueKey('base-editor-$_editorGeneration'),
            builder: (context) => panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading(
                    tr(
                      _leave ? 'طلب إجازة' : 'إقرار إلكتروني',
                      _leave ? 'Leave request' : 'Electronic acknowledgment',
                    ),
                  ),
                  Text(
                    tr(
                      'تعبئة نموذج الموظف الإلكتروني',
                      'Prepare the employee form',
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF77738C),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_loading) const AppLoadingState(compact: true),
                  if (_error != null) ...[
                    AppFailureState(
                      error: _error,
                      onRetry: _load,
                      compact: true,
                    ),
                  ],
                  DropdownButtonFormField<String>(
                    key: const ValueKey('hr-form-employee'),
                    initialValue: _employeeId,
                    isExpanded: true,
                    decoration: decoration(tr('الموظف *', 'Employee *')),
                    items: [
                      for (final e in _data.employees)
                        DropdownMenuItem(
                          value: e.id,
                          child: Text(
                            '${e.fullName} (${e.employeeNumber ?? '—'})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                    onChanged: _loading || _busy || _saving || _submitted
                        ? null
                        : (v) {
                            setState(() {
                              _employeeId = v;
                              _signature.text = employee?.fullName ?? '';
                              _agreed = false;
                            });
                            refresh();
                          },
                  ),
                  const SizedBox(height: 16),
                  heading(tr('بيانات الموظف', 'Employee information')),
                  Table(
                    border: TableBorder.all(color: border),
                    children: [
                      for (final row in [
                        [
                          tr('الاسم', 'Name'),
                          tr('رقم الموظف', 'Employee number'),
                        ],
                        [
                          employee?.fullName ?? '—',
                          employee?.employeeNumber ?? '—',
                        ],
                        [tr('الوظيفة', 'Job title'), tr('القسم', 'Department')],
                        [
                          employee?.jobTitleName ?? '—',
                          employee?.departmentName ?? '—',
                        ],
                      ])
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFAF8FD),
                          ),
                          children: [
                            for (final value in row)
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ink,
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_leave) ...[
                    heading(tr('نص الإقرار', 'Acknowledgment text')),
                    input(
                      tr('نص الإقرار', 'Acknowledgment text'),
                      _statement,
                      lines: 4,
                    ),
                    heading(tr('موافقة الموظف', 'Employee acknowledgment')),
                    CheckboxListTile(
                      key: const ValueKey('hr-form-agreement'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _agreed,
                      activeColor: purple,
                      onChanged: _busy || _saving || _submitted
                          ? null
                          : (v) {
                              setState(() => _agreed = v ?? false);
                              refresh();
                            },
                      title: Text(
                        tr(
                          'أقر بما ورد أعلاه',
                          'I acknowledge the statement above',
                        ),
                        style: const TextStyle(fontSize: 13, color: ink),
                      ),
                    ),
                  ],
                  if (_leave) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _leaveType,
                      isExpanded: true,
                      decoration: decoration(tr('نوع الإجازة', 'Leave type')),
                      items: [
                        for (final value in ['annual', 'sick', 'other'])
                          DropdownMenuItem(
                            value: value,
                            child: Text(leaveLabel(value)),
                          ),
                      ],
                      onChanged: _busy || _saving || _submitted
                          ? null
                          : (v) {
                              setState(() => _leaveType = v!);
                              refresh();
                            },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        dateButton(tr('من', 'From'), 'from', _from),
                        dateButton(tr('إلى', 'To'), 'to', _to),
                      ],
                    ),
                    if (_from != null && _to != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          '${tr('المدة', 'Duration')}: ${_to!.difference(_from!).inDays + 1} ${tr('يوم', 'days')}',
                          style: const TextStyle(
                            color: purple,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    input(
                      tr('سبب الإجازة / ملاحظات', 'Reason / notes'),
                      _notes,
                      lines: 3,
                    ),
                    ExpansionTile(
                      title: Text(
                        tr(
                          'بيانات إضافية للإجازة',
                          'Additional leave information',
                        ),
                        style: const TextStyle(fontSize: 13, color: ink),
                      ),
                      children: [
                        input(tr('الموظف البديل', 'Replacement'), _replacement),
                        input(
                          tr('العنوان أثناء الإجازة', 'Address during leave'),
                          _address,
                        ),
                        input(
                          tr('التواصل أثناء الإجازة', 'Contact during leave'),
                          _contact,
                        ),
                      ],
                    ),
                  ],
                  input(tr('اسم الموقّع', 'Signatory name'), _signature),
                  dateButton(tr('التاريخ', 'Date'), 'date', _date),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => context.push(
                            AppRoutes.hrFormTemplate.replaceFirst(
                              ':templateId',
                              _leave
                                  ? leavePrototypeTemplateId
                                  : acknowledgmentPrototypeTemplateId,
                            ),
                          ),
                    icon: const Icon(Icons.open_in_new, size: 15),
                    label: Text(
                      tr('فتح النموذج التفصيلي', 'Open detailed form'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
    final preview = panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: heading(tr('معاينة PDF', 'PDF preview'))),
              if (_prototype == null)
                IconButton(
                  onPressed: _busy || employee == null
                      ? null
                      : () => pdfAction(false),
                  icon: const Icon(Icons.open_in_full, size: 18, color: purple),
                  tooltip: tr('تكبير المعاينة', 'Expand preview'),
                ),
            ],
          ),
          Container(
            height: 440,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF2EDF8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: _pdf == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          AppAssets.fullLogo,
                          height: 96,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            tr(
                              'اختر موظفًا لعرض معاينة النموذج',
                              'Choose an employee to preview the form',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF77738C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : FutureBuilder<Uint8List>(
                    future: _pdf,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return AppFailureState(
                          error: snapshot.error,
                          onRetry: refresh,
                          title: tr(
                            'تعذر تحميل المعاينة؛ حاول مجددًا',
                            'Preview failed; try again',
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const AppLoadingState(compact: true);
                      }
                      return widget.previewBuilder?.call(snapshot.data!) ??
                          PdfPreview(
                            key: ObjectKey(snapshot.data),
                            build: (_) async => snapshot.data!,
                            allowPrinting: false,
                            allowSharing: false,
                            useActions: false,
                            canChangeOrientation: false,
                            canChangePageFormat: false,
                            maxPageWidth: 450,
                          );
                    },
                  ),
          ),
          const SizedBox(height: 14),
          if (_prototype == null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  key: const ValueKey('hr-form-preview'),
                  onPressed: _busy ? null : () => pdfAction(false),
                  style: FilledButton.styleFrom(
                    backgroundColor: purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: Text(tr('معاينة PDF', 'Preview PDF')),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('hr-form-export'),
                  onPressed: _busy ? null : () => pdfAction(true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: purple,
                    side: const BorderSide(color: purple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  icon: const Icon(Icons.download_outlined, size: 17),
                  label: Text(tr('تصدير PDF', 'Export PDF')),
                ),
              ],
            ),
          if (_busy) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(color: purple),
          ],
        ],
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('نماذج الموارد البشرية', 'HR forms'),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr(
                'إدارة نماذج الموارد البشرية والإقرارات',
                'Manage HR forms and acknowledgments',
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF77738C)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  key: const ValueKey('hr-save-draft'),
                  onPressed: _saving || _busy || _submitted ? null : saveDraft,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(tr('حفظ المسودة', 'Save draft')),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('hr-draft-history'),
                  onPressed: _saving || _busy || _loading ? null : openHistory,
                  icon: const Icon(Icons.history),
                  label: Text(
                    tr('المسودات وسجل الطلبات', 'Drafts and request history'),
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('hr-new-draft'),
                  onPressed: _saving || _busy ? null : newDraft,
                  icon: const Icon(Icons.add),
                  label: Text(tr('مسودة جديدة', 'New draft')),
                ),
                if (_templateId == leavePrototypeTemplateId ||
                    _templateId == 'early-exit')
                  FilledButton.icon(
                    key: const ValueKey('hr-submit-form'),
                    onPressed: _saving || _busy || _loading || _submitted
                        ? null
                        : submitDraft,
                    icon: const Icon(Icons.send_outlined),
                    label: Text(tr('إرسال للاعتماد', 'Submit for approval')),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_submitted)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EDFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_savedDraft!.reference ?? ''} · ${hrFormStatusLabel(_savedDraft!.status, ar)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: ink,
                      ),
                    ),
                    if (_savedDraft!.approverRole != null)
                      Text(
                        '${tr('بانتظار', 'Waiting for')}: ${hrFormApproverLabel(_savedDraft!.approverRole, ar)}',
                      ),
                    if (_savedDraft!.rejectReason != null)
                      Text(
                        '${tr('سبب الرفض', 'Rejection reason')}: ${_savedDraft!.rejectReason}',
                      ),
                    Text(
                      tr(
                        'الطلب المرسل للعرض فقط. يمكنك بدء مسودة جديدة لأي تعديل.',
                        'Submitted requests are read-only. Start a new draft for changes.',
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              _savedDraft == null
                  ? tr(
                      'احفظ المسودة قبل إغلاق الصفحة. الحفظ لا يرسل طلب اعتماد.',
                      'Save your draft before closing this page. Saving does not submit an approval request.',
                    )
                  : '${_dirty ? tr('تعديلات غير محفوظة', 'Unsaved changes') : tr('مسودة محفوظة', 'Saved draft')} · v${_savedDraft!.version} · ${_savedDraft!.updatedAt.toLocal().toIso8601String().substring(0, 16).replaceFirst('T', ' ')}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF77738C)),
            ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, c) => c.maxWidth >= 1050
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: c.maxWidth * .36, child: preview),
                        const SizedBox(width: 14),
                        Expanded(child: editor),
                        const SizedBox(width: 14),
                        SizedBox(width: c.maxWidth * .20, child: templates),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        templates,
                        const SizedBox(height: 14),
                        editor,
                        const SizedBox(height: 14),
                        preview,
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
