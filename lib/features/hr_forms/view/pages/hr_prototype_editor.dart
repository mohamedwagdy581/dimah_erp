import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/ui/app_data_state.dart';
import '../../../../core/utils/safe_file_picker.dart';
import '../../../employees/data/repos/hr_employees_repo.dart';
import '../../../employees/domain/models/employee.dart';
import '../../domain/models/hr_prototype_def.dart';
import '../services/hr_form_file_service.dart';
import '../services/hr_form_print_layout.dart';

class HrPrototypeEditor extends StatefulWidget {
  const HrPrototypeEditor({
    super.key,
    required this.template,
    this.loadEmployees,
    this.buildPdf,
    this.exportPdf,
    this.embedded = false,
    this.onPreview,
    this.initialData,
    this.onDraftChanged,
    this.readOnly = false,
  });
  final HrPrototypeDef template;
  final Future<HrEmployeesData> Function()? loadEmployees;
  final Future<Uint8List> Function(Map<String, String>, Employee?)? buildPdf;
  final Future<void> Function(Uint8List, String)? exportPdf;
  final bool embedded;
  final void Function(Future<Uint8List>?)? onPreview;
  final Map<String, dynamic>? initialData;
  final void Function(Map<String, dynamic>)? onDraftChanged;
  final bool readOnly;
  @override
  State<HrPrototypeEditor> createState() => _HrPrototypeEditorState();
}

class _HrPrototypeEditorState extends State<HrPrototypeEditor> {
  final form = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  final checks = <String, bool>{};
  Timer? previewTimer;
  List<Employee> employees = [];
  String? selected;
  Object? error;
  bool loading = true, busy = false;
  bool savedEmployeeUnavailable = false;
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => ar ? a : e;
  @override
  void initState() {
    super.initState();
    for (final f in widget.template.fields) {
      final savedFields = widget.initialData?['fields'] as Map?;
      final savedChecks = widget.initialData?['checks'] as Map?;
      controllers[f.id] = TextEditingController(
        text: savedFields?[f.id]?.toString() ?? '',
      );
      checks[f.id] = savedChecks?[f.id] == true;
    }
    selected = widget.initialData?['employee_id'] as String?;
    load();
  }

  @override
  void dispose() {
    previewTimer?.cancel();
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data =
          await (widget.loadEmployees ??
              () => SupabaseHrEmployeesRepo(Supabase.instance.client).load())();
      if (mounted) {
        setState(() {
          employees = data.employees
              .where((e) => widget.readOnly || e.status == 'active')
              .toList();
          if (selected != null && !employees.any((e) => e.id == selected)) {
            savedEmployeeUnavailable = true;
            selected = null;
          }
          loading = false;
        });
        refreshPreview();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = e;
        });
      }
    }
  }

  Employee? get employee {
    for (final e in employees) {
      if (e.id == selected) return e;
    }
    return null;
  }

  String stamp(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  Future<void> pick(HrPrototypeField f) async {
    if (busy || widget.readOnly) return;
    if (f.type == HrPrototypeFieldType.date) {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (mounted && picked != null) {
        setState(() => controllers[f.id]!.text = stamp(picked));
      }
    } else {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (mounted && picked != null) {
        setState(
          () => controllers[f.id]!.text =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
        );
      }
    }
  }

  Map<String, String> get values => {
    for (final f in widget.template.fields)
      f.label(ar): f.type == HrPrototypeFieldType.check
          ? tr(
              checks[f.id] == true ? 'تم' : 'لم يتم',
              checks[f.id] == true ? 'Completed' : 'Not completed',
            )
          : controllers[f.id]!.text.trim(),
  };
  Future<Uint8List> document(Map<String, String> data, Employee? person) =>
      widget.buildPdf?.call(data, person) ??
      buildHrPrintDocument(
        isArabic: ar,
        isLeave: false,
        agreed: false,
        employeeName: person?.fullName ?? '-',
        employeeNumber: person?.employeeNumber ?? '-',
        department: person?.departmentName ?? '-',
        jobTitle: person?.jobTitleName ?? '-',
        date: stamp(DateTime.now()),
        fields: data,
        documentTitle: widget.template.title(ar),
        templateCode: widget.template.code,
        signatureLabels: [
          tr('مقدم الطلب', 'Requested by'),
          tr('مراجعة المدير', 'Manager review'),
          tr('الموارد البشرية', 'Human Resources'),
        ],
      );
  void refreshPreview() {
    widget.onDraftChanged?.call({
      'employee_id': selected,
      'fields': {
        for (final f in widget.template.fields) f.id: controllers[f.id]!.text,
      },
      'checks': {
        for (final f in widget.template.fields)
          if (f.type == HrPrototypeFieldType.check) f.id: checks[f.id] ?? false,
      },
    });
    if (widget.onPreview == null) return;
    previewTimer?.cancel();
    previewTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (widget.template.employeeRequired && employee == null) {
        widget.onPreview!(null);
      } else {
        widget.onPreview!(document(values, employee));
      }
    });
  }

  Future<void> action(bool export, {bool print = false}) async {
    if (busy || loading || !(form.currentState?.validate() ?? false)) return;
    if (widget.template.employeeRequired && employee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'اختر موظفًا نشطًا قبل الطباعة أو التصدير.',
              'Select an active employee before printing or exporting.',
            ),
          ),
        ),
      );
      return;
    }
    final data = values, person = employee;
    setState(() => busy = true);
    try {
      final bytes = await document(data, person);
      if (!mounted) return;
      final name =
          '${widget.template.id}_${person?.employeeNumber ?? 'draft'}.pdf';
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
            await XFile.fromData(
              bytes,
              mimeType: 'application/pdf',
              name: name,
            ).saveTo(location.path);
          }
        }
      } else if (widget.embedded && !print) {
        widget.onPreview?.call(Future.value(bytes));
      } else {
        await HrFormFileService.openPdfPreview(
          context,
          title: widget.template.title(ar),
          buildBytes: () async => bytes,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'تعذر إنشاء النموذج. البيانات التي أدخلتها محفوظة في الشاشة؛ حاول مجددًا.',
                'Could not generate the document. Your entered values remain on this screen; retry.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: widget.embedded ? EdgeInsets.zero : const EdgeInsets.all(16),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DDF2)),
      ),
      child: Form(
        key: form,
        onChanged: refreshPreview,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.template.title(ar),
              style: TextStyle(
                fontSize: widget.embedded ? 18 : 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF21194E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              tr(
                'نموذج أولي قابل للتعبئة والطباعة. لا يغيّر بيانات الموظف ولا ينشئ طلب اعتماد داخل النظام.',
                'Fillable and printable prototype. It does not change employee records or submit an approval request.',
              ),
              style: const TextStyle(color: Color(0xFF77709A), height: 1.6),
            ),
            const SizedBox(height: 18),
            if (loading) const AppLoadingState(compact: true),
            if (error != null)
              AppFailureState(error: error, onRetry: load, compact: true),
            if (savedEmployeeUnavailable)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  tr(
                    'الموظف المحفوظ لم يعد ضمن الموظفين النشطين. اختر الموظف الصحيح لاستكمال النموذج.',
                    'The saved employee is no longer in the active list. Select the correct employee to continue.',
                  ),
                ),
              ),
            if (!loading && error == null)
              DropdownButtonFormField<String>(
                key: const ValueKey('prototype-employee'),
                initialValue: selected,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: tr(
                    widget.template.employeeRequired
                        ? 'الموظف *'
                        : 'الموظف (اختياري)',
                    'Employee${widget.template.employeeRequired ? ' *' : ' (optional)'}',
                  ),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final e in employees)
                    DropdownMenuItem(
                      value: e.id,
                      child: Text(
                        '${e.fullName} (${e.employeeNumber ?? '-'})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: loading || busy || widget.readOnly
                    ? null
                    : (id) => setState(() => selected = id),
                validator: (v) => widget.template.employeeRequired && v == null
                    ? tr('اختر الموظف', 'Select an employee')
                    : null,
              ),
            if (employee != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  '${employee!.departmentName ?? '-'} • ${employee!.jobTitleName ?? '-'}',
                  style: const TextStyle(color: Color(0xFF8659BB)),
                ),
              ),
            const SizedBox(height: 16),
            for (final f in widget.template.fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: f.type == HrPrototypeFieldType.check
                    ? CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(f.label(ar)),
                        value: checks[f.id] ?? false,
                        onChanged: busy || widget.readOnly
                            ? null
                            : (v) {
                                setState(() => checks[f.id] = v ?? false);
                                refreshPreview();
                              },
                      )
                    : TextFormField(
                        key: ValueKey('prototype-field-${f.id}'),
                        controller: controllers[f.id],
                        enabled: !busy && !widget.readOnly,
                        readOnly:
                            f.type == HrPrototypeFieldType.date ||
                            f.type == HrPrototypeFieldType.time,
                        onTap:
                            f.type == HrPrototypeFieldType.date ||
                                f.type == HrPrototypeFieldType.time
                            ? () => pick(f)
                            : null,
                        keyboardType: f.type == HrPrototypeFieldType.number
                            ? const TextInputType.numberWithOptions(
                                decimal: true,
                              )
                            : TextInputType.text,
                        textDirection:
                            [
                              HrPrototypeFieldType.date,
                              HrPrototypeFieldType.time,
                              HrPrototypeFieldType.number,
                            ].contains(f.type)
                            ? TextDirection.ltr
                            : null,
                        maxLines: f.type == HrPrototypeFieldType.notes ? 3 : 1,
                        decoration: InputDecoration(
                          labelText: '${f.label(ar)}${f.required ? ' *' : ''}',
                          border: const OutlineInputBorder(),
                          suffixIcon: f.type == HrPrototypeFieldType.date
                              ? const Icon(Icons.calendar_month_outlined)
                              : f.type == HrPrototypeFieldType.time
                              ? const Icon(Icons.schedule)
                              : null,
                        ),
                        validator: (v) {
                          if (f.required && (v ?? '').trim().isEmpty) {
                            return tr('هذا الحقل مطلوب', 'Required field');
                          }
                          if (f.type == HrPrototypeFieldType.number &&
                              (v ?? '').isNotEmpty) {
                            final n = num.tryParse(v!.trim());
                            if (n == null || !n.isFinite || n < 0) {
                              return tr(
                                'أدخل رقمًا صحيحًا غير سالب',
                                'Enter a valid non-negative number',
                              );
                            }
                          }
                          return null;
                        },
                      ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  key: const ValueKey('prototype-preview'),
                  onPressed: busy || loading ? null : () => action(false),
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(
                    widget.embedded
                        ? tr('تحديث المعاينة', 'Update preview')
                        : tr('معاينة وطباعة', 'Preview and print'),
                  ),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('prototype-export'),
                  onPressed: busy || loading ? null : () => action(true),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(tr('تصدير PDF', 'Export PDF')),
                ),
                if (widget.embedded)
                  OutlinedButton.icon(
                    onPressed: busy || loading
                        ? null
                        : () => action(false, print: true),
                    icon: const Icon(Icons.print_outlined),
                    label: Text(tr('معاينة وطباعة', 'Preview and print')),
                  ),
              ],
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    ),
  );
}
