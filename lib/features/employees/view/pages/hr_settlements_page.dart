import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:erp_sys/core/ui/app_search_field.dart';
import 'dart:math' as math;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/safe_file_picker.dart';
import '../../data/repos/hr_settlements_repo.dart';
import '../../domain/models/hr_settlement.dart';
import '../widgets/employee_wizard/wizard_layout.dart';

class HrSettlementsPage extends StatefulWidget {
  const HrSettlementsPage({
    super.key,
    this.repo,
    this.today,
    this.pickAttachment,
    this.openAttachment,
    this.openProfile,
  });
  final HrSettlementsRepo? repo;
  final DateTime? today;
  final Future<SettlementAttachment?> Function()? pickAttachment;
  final Future<void> Function(HrSettlement)? openAttachment;
  final ValueChanged<String>? openProfile;
  @override
  State<HrSettlementsPage> createState() => _HrSettlementsPageState();
}

class _HrSettlementsPageState extends State<HrSettlementsPage> {
  late final HrSettlementsRepo _repo;
  final _form = GlobalKey<FormState>();
  final _gross = TextEditingController(),
      _deductions = TextEditingController(text: '0'),
      _notes = TextEditingController();
  HrSettlementsData _data = const HrSettlementsData();
  String? _employee, _type, _error;
  String _requestId = newSettlementId(), _search = '';
  late DateTime _date, _lastDay;
  SettlementAttachment? _attachment;
  bool _loading = true, _saving = false, _picking = false;
  int _page = 0;
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => ar ? a : e;
  String date(DateTime? d) => d == null
      ? '—'
      : '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  String type(String code) => switch (code) {
    'final' => tr('مخالصة نهاية عقد', 'Final settlement'),
    'partial' => tr('مخالصة جزئية', 'Partial settlement'),
    _ => tr('أخرى', 'Other'),
  };
  @override
  void initState() {
    super.initState();
    _repo = widget.repo ?? SupabaseHrSettlementsRepo(Supabase.instance.client);
    _date = _lastDay = widget.today ?? DateTime.now();
    _load();
  }

  @override
  void dispose() {
    _gross.dispose();
    _deductions.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _repo.load();
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
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

  void _changed() => _requestId = newSettlementId();
  void _reset() {
    _form.currentState?.reset();
    setState(() {
      _employee = _type = null;
      _attachment = null;
      _date = _lastDay = widget.today ?? DateTime.now();
      _gross.clear();
      _deductions.text = '0';
      _notes.clear();
      _changed();
    });
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _pickDate(bool last) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: last ? _lastDay : _date,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        if (last) {
          _lastDay = picked;
        } else {
          _date = picked;
        }
        _changed();
      });
    }
  }

  Future<void> _pick() async {
    if (_saving || _picking) return;
    setState(() => _picking = true);
    try {
      SettlementAttachment? attachment;
      if (widget.pickAttachment != null) {
        attachment = await widget.pickAttachment!();
      } else {
        final file = await SafeFilePicker.openSingle(
          context: context,
          acceptedTypeGroups: const [
            XTypeGroup(
              label: 'PDF / Images',
              extensions: ['pdf', 'jpg', 'jpeg', 'png'],
            ),
          ],
        );
        if (file != null) {
          if (await file.length() > 5 * 1024 * 1024) {
            throw StateError('Maximum 5 MB');
          }
          attachment = SettlementAttachment(
            name: file.name,
            bytes: await file.readAsBytes(),
          );
        }
      }
      if (attachment == null || !mounted) return;
      if (!attachment.isValid) {
        _message(
          tr(
            'اختر PDF أو JPG أو PNG بحجم لا يزيد عن 5 ميجابايت',
            'Choose PDF/JPG/PNG up to 5 MB',
          ),
        );
        return;
      }
      setState(() {
        _attachment = attachment;
        _changed();
      });
    } catch (e) {
      if (mounted) {
        _message(
          tr('تعذّر اختيار المرفق: $e', 'Unable to select attachment: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  String? _amount(String? value, {bool deduction = false}) {
    final money = double.tryParse((value ?? '').trim());
    if (money == null ||
        !money.isFinite ||
        money < 0 ||
        (!deduction && money <= 0)) {
      return tr('أدخل مبلغًا صحيحًا', 'Enter a valid amount');
    }
    if (deduction && money > (double.tryParse(_gross.text) ?? 0)) {
      return tr('الخصومات أكبر من المبلغ', 'Deductions exceed the amount');
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving || _picking || !(_form.currentState?.validate() ?? false)) {
      return;
    }
    if (_type == 'final' &&
        DateUtils.dateOnly(_lastDay).isAfter(DateUtils.dateOnly(_date))) {
      _message(
        tr(
          'تاريخ آخر يوم عمل يجب ألا يكون بعد تاريخ المخالصة',
          'Final working date cannot follow the settlement date',
        ),
      );
      return;
    }
    final draft = HrSettlementDraft(
      id: _requestId,
      employeeId: _employee!,
      date: _date,
      finalWorkingDate: _type == 'final' ? _lastDay : _date,
      type: _type!,
      gross: double.parse(_gross.text.trim()),
      deductions: double.parse(_deductions.text.trim()),
      notes: _notes.text.trim(),
      attachment: _attachment,
    );
    setState(() => _saving = true);
    try {
      await _repo.save(draft);
      if (!mounted) return;
      _reset();
      _message(tr('تمت إضافة المخالصة', 'Settlement added'));
      await _load();
    } catch (e) {
      if (mounted) {
        _message(
          e is StorageException && e.statusCode == '403'
              ? tr(
                  'لم تُحفظ المخالصة لأن صلاحية رفع المرفق مرفوضة. راجع مسؤول النظام لتحديث صلاحيات مرفقات المخالصات، ثم أعد المحاولة بنفس البيانات.',
                  'Settlement was not saved because attachment access was denied. Ask your administrator to update settlement attachment permissions, then retry with the same values.',
                )
              : tr(
                  'تعذّر حفظ المخالصة. يمكنك إعادة المحاولة بنفس البيانات: $e',
                  'Unable to save settlement. Retry with the same values: $e',
                ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openFile(HrSettlement row) async {
    try {
      if (widget.openAttachment != null) {
        await widget.openAttachment!(row);
        return;
      }
      final path = row.filePath;
      if (path == null) return;
      final uri = Uri.parse(await _repo.attachmentUrl(path));
      if (uri.scheme != 'https' ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Unable to open attachment');
      }
    } catch (e) {
      if (mounted) {
        _message(tr('تعذّر فتح المرفق: $e', 'Unable to open attachment: $e'));
      }
    }
  }

  void _profile(HrSettlement row) {
    if (widget.openProfile != null) {
      widget.openProfile!(row.employeeId);
    } else {
      context.push('/employees/${row.employeeId}');
    }
  }

  void _details(HrSettlement row) {
    showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(tr('تفاصيل المخالصة', 'Settlement details')),
        scrollable: true,
        content: SizedBox(
          width: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                row.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: wizardInk,
                ),
              ),
              if (row.employeeNumber.isNotEmpty) Text(row.employeeNumber),
              const SizedBox(height: 16),
              for (final entry in <String, String>{
                tr('نوع المخالصة', 'Settlement type'): type(row.type),
                tr('تاريخ المخالصة', 'Settlement date'): date(row.date),
                tr('آخر يوم عمل', 'Final working date'): date(
                  row.finalWorkingDate,
                ),
                tr('المبلغ الإجمالي', 'Gross amount'): row.gross
                    .toStringAsFixed(2),
                tr('الخصومات', 'Deductions'): row.deductions.toStringAsFixed(2),
                tr('صافي المخالصة', 'Net settlement'): row.net.toStringAsFixed(
                  2,
                ),
              }.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text('${entry.key}: ${entry.value}'),
                ),
              const Divider(color: wizardBorder),
              Text(
                row.notes.isEmpty
                    ? tr('لا توجد ملاحظات', 'No notes')
                    : row.notes,
              ),
              if (row.filePath != null)
                TextButton.icon(
                  onPressed: () => _openFile(row),
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    row.fileName ?? tr('عرض المرفق', 'View attachment'),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text(tr('إغلاق', 'Close')),
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, bool last) => WizardLabeledField(
    label: label,
    required: true,
    child: InkWell(
      onTap: () => _pickDate(last),
      child: InputDecorator(
        decoration: const InputDecoration(
          suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          date(last ? _lastDay : _date),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ),
  );
  Widget _formPanel() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      border: Border.all(color: wizardBorder),
      borderRadius: BorderRadius.circular(8),
    ),
    child: AbsorbPointer(
      absorbing: _saving,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WizardLabeledField(
              label: tr('الموظف', 'Employee'),
              required: true,
              child: DropdownButtonFormField<String>(
                key: ValueKey('settlement-employee-$_employee'),
                initialValue: _employee,
                isExpanded: true,
                hint: Text(
                  tr('اختر الموظف ...', 'Select employee ...'),
                  style: const TextStyle(fontSize: 12),
                ),
                items: _data.employees
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(
                          '${e.fullName}${(e.employeeNumber ?? '').trim().isEmpty ? '' : ' (${e.employeeNumber})'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _loading
                    ? null
                    : (value) => setState(() {
                        _employee = value;
                        _changed();
                      }),
                validator: (v) =>
                    v == null ? tr('اختر الموظف', 'Select an employee') : null,
              ),
            ),
            const SizedBox(height: 16),
            _dateField(tr('تاريخ المخالصة', 'Settlement date'), false),
            const SizedBox(height: 16),
            WizardLabeledField(
              label: tr('نوع المخالصة', 'Settlement type'),
              required: true,
              child: DropdownButtonFormField<String>(
                key: ValueKey('settlement-type-$_type'),
                initialValue: _type,
                isExpanded: true,
                hint: Text(
                  tr('اختر نوع المخالصة ...', 'Select settlement type ...'),
                  style: const TextStyle(fontSize: 12),
                ),
                items: ['final', 'partial', 'other']
                    .map(
                      (v) => DropdownMenuItem(value: v, child: Text(type(v))),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  _type = v;
                  _changed();
                }),
                validator: (v) => v == null
                    ? tr('اختر نوع المخالصة', 'Select settlement type')
                    : null,
              ),
            ),
            if (_type == 'final') ...[
              const SizedBox(height: 16),
              _dateField(tr('آخر يوم عمل', 'Final working date'), true),
              const SizedBox(height: 8),
              Text(
                tr(
                  'المخالصة النهائية تحوّل حالة الموظف إلى غير نشط.',
                  'A final settlement marks the employee inactive.',
                ),
                style: const TextStyle(fontSize: 11, color: Color(0xFF777098)),
              ),
            ],
            const SizedBox(height: 16),
            WizardLabeledField(
              label: tr('المبلغ (ريال)', 'Amount (SAR)'),
              required: true,
              child: TextFormField(
                key: const ValueKey('settlement-gross'),
                controller: _gross,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  suffixIcon: Container(
                    width: 46,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F4F9),
                      border: BorderDirectional(
                        start: BorderSide(color: wizardBorder),
                      ),
                    ),
                    child: Text(
                      tr('ريال', 'SAR'),
                      style: const TextStyle(fontSize: 12, color: wizardInk),
                    ),
                  ),
                ),
                onChanged: (_) => setState(_changed),
                validator: _amount,
              ),
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              maintainState: true,
              title: Text(
                tr('الخصومات وصافي المخالصة', 'Deductions and net settlement'),
                style: const TextStyle(fontSize: 12),
              ),
              children: [
                TextFormField(
                  key: const ValueKey('settlement-deductions'),
                  controller: _deductions,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: tr('الخصومات', 'Deductions'),
                  ),
                  onChanged: (_) => setState(_changed),
                  validator: (v) => _amount(v, deduction: true),
                ),
                const SizedBox(height: 12),
                Text(
                  '${tr('الصافي', 'Net')}: ${((double.tryParse(_gross.text) ?? 0) - (double.tryParse(_deductions.text) ?? 0)).toStringAsFixed(2)} ${tr('ريال', 'SAR')}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: wizardPurple,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
            const SizedBox(height: 12),
            WizardLabeledField(
              label: tr('ملاحظات', 'Notes'),
              child: TextFormField(
                key: const ValueKey('settlement-notes'),
                controller: _notes,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: tr('أدخل الملاحظات ...', 'Enter notes ...'),
                ),
                onChanged: (_) => _changed(),
              ),
            ),
            const SizedBox(height: 12),
            WizardLabeledField(
              label: tr('مرفق (اختياري)', 'Attachment (optional)'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const _AttachmentDecoration(),
                child: Column(
                  children: [
                    TextButton.icon(
                      key: const ValueKey('settlement-attachment'),
                      onPressed: _picking ? null : _pick,
                      icon: const Icon(Icons.attach_file, size: 28),
                      label: Text(
                        _attachment?.name ??
                            tr('اختر ملف المرفق', 'Choose an attachment'),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_attachment == null)
                      Text(
                        tr(
                          'PDF، JPG، PNG · الحد الأقصى 5 ميجابايت',
                          'PDF, JPG, PNG · Maximum 5 MB',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF777098),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () => setState(() {
                          _attachment = null;
                          _changed();
                        }),
                        child: Text(tr('إزالة المرفق', 'Remove attachment')),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    key: const ValueKey('settlement-save'),
                    onPressed: _loading || _picking ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add, size: 18),
                    label: Text(
                      tr('إضافة مخالصة', 'Add settlement'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    child: Text(tr('إلغاء', 'Cancel')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: wizardBorder),
    );
    final rows = _data.settlements
        .where(
          (row) =>
              '${row.name} ${row.employeeNumber} ${row.notes} ${type(row.type)}'
                  .toLowerCase()
                  .contains(_search.toLowerCase()),
        )
        .toList();
    final pages = math.max(1, (rows.length / 10).ceil());
    final page = math.min(_page, pages - 1);
    final visible = rows.skip(page * 10).take(10).toList();
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(
          context,
        ).colorScheme.copyWith(primary: wizardPurple, onPrimary: Colors.white),
        textTheme: Theme.of(
          context,
        ).textTheme.apply(bodyColor: wizardInk, displayColor: wizardInk),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: outline,
          enabledBorder: outline,
          disabledBorder: outline,
          focusedBorder: outline.copyWith(
            borderSide: const BorderSide(color: wizardPurple),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 11,
          ),
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF8B83AF)),
          suffixIconColor: wizardPurple,
          prefixIconColor: wizardPurple,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: wizardPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: wizardPurple,
            side: const BorderSide(color: Color(0xFFD9C5FF)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final panel = SizedBox(
              height: wide ? math.max(560, constraints.maxHeight - 108) : 540,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: wizardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppSearchField(
                              value: _search,
                              onChanged: (v) => setState(() {
                                _search = v;
                                _page = 0;
                              }),
                              decoration: InputDecoration(
                                hintText: tr(
                                  'ابحث بالموظف أو الملاحظات ...',
                                  'Search employee or notes ...',
                                ),
                                suffixIcon: const Icon(Icons.search, size: 18),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _saving || _loading ? null : _load,
                            tooltip: tr('تحديث', 'Refresh'),
                            icon: const Icon(
                              Icons.refresh,
                              color: wizardPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AppDataRegion(
                        loading: _loading,
                        error: _error,
                        empty: visible.isEmpty,
                        filtered: _search.trim().isNotEmpty,
                        onClear: () => setState(() {
                          _search = '';
                          _page = 0;
                        }),
                        onRetry: _load,
                        child: _SettlementTable(
                          rows: visible,
                          offset: page * 10,
                          ar: ar,
                          date: date,
                          type: type,
                          onDetails: _details,
                          onFile: _openFile,
                          onProfile: _profile,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${tr('الإجمالي', 'Total')}: ${rows.length} · ${page + 1} / $pages',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          IconButton(
                            onPressed: page == 0
                                ? null
                                : () => setState(() => _page = page - 1),
                            icon: const Icon(Icons.chevron_right, size: 18),
                            tooltip: tr('السابق', 'Previous'),
                          ),
                          IconButton(
                            onPressed: page >= pages - 1
                                ? null
                                : () => setState(() => _page = page + 1),
                            icon: const Icon(Icons.chevron_left, size: 18),
                            tooltip: tr('التالي', 'Next'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
            return SingleChildScrollView(
              padding: EdgeInsets.all(constraints.maxWidth < 600 ? 12 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr('إضافة مخالصة', 'Add settlement'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: ((constraints.maxWidth - 58) * .39).clamp(
                            340.0,
                            480.0,
                          ),
                          child: _formPanel(),
                        ),
                        const SizedBox(width: 18),
                        Expanded(child: panel),
                      ],
                    )
                  else ...[
                    _formPanel(),
                    const SizedBox(height: 18),
                    panel,
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SettlementTable extends StatefulWidget {
  const _SettlementTable({
    required this.rows,
    required this.offset,
    required this.ar,
    required this.date,
    required this.type,
    required this.onDetails,
    required this.onFile,
    required this.onProfile,
  });
  final List<HrSettlement> rows;
  final int offset;
  final bool ar;
  final String Function(DateTime?) date;
  final String Function(String) type;
  final ValueChanged<HrSettlement> onDetails, onProfile;
  final Future<void> Function(HrSettlement) onFile;
  @override
  State<_SettlementTable> createState() => _SettlementTableState();
}

class _SettlementTableState extends State<_SettlementTable> {
  final _horizontal = ScrollController(), _vertical = ScrollController();
  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.max(900.0, constraints.maxWidth);
      String tr(String a, String e) => widget.ar ? a : e;
      const flexes = [4, 23, 14, 17, 12, 20, 10];
      Widget cell(String value, {bool header = false, bool center = false}) =>
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              value,
              textAlign: center ? TextAlign.center : TextAlign.start,
              maxLines: header ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: header ? 14 : 13,
                fontWeight: header ? FontWeight.w600 : FontWeight.normal,
                color: wizardInk,
              ),
            ),
          );
      Widget row(List<Widget> cells, {bool header = false}) => Container(
        height: header ? 56 : 82,
        decoration: BoxDecoration(
          color: header ? const Color(0xFFF5F4F9) : Colors.white,
          border: const Border(bottom: BorderSide(color: wizardBorder)),
        ),
        child: Row(
          children: List.generate(
            cells.length,
            (i) => Expanded(
              flex: flexes[i],
              child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: math.min(
                    width * flexes[i] / 100,
                    i == 1
                        ? 220.0
                        : i == 5
                        ? 240.0
                        : double.infinity,
                  ),
                  child: cells[i],
                ),
              ),
            ),
          ),
        ),
      );
      return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ScrollbarTheme(
          data: ScrollbarThemeData(
            thumbColor: WidgetStateProperty.all(
              wizardPurple.withValues(alpha: .75),
            ),
            trackColor: WidgetStateProperty.all(const Color(0xFFF1E9FA)),
          ),
          child: Scrollbar(
            key: const ValueKey('settlements-horizontal-scrollbar'),
            controller: _horizontal,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            thickness: 10,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              key: const ValueKey('settlements-horizontal-scroll'),
              controller: _horizontal,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    row(
                      [
                            '#',
                            tr('الموظف', 'Employee'),
                            tr('تاريخ المخالصة', 'Settlement date'),
                            tr('نوع المخالصة', 'Settlement type'),
                            tr('المبلغ (ريال)', 'Amount (SAR)'),
                            tr('ملاحظات', 'Notes'),
                            tr('الإجراءات', 'Actions'),
                          ]
                          .asMap()
                          .entries
                          .map(
                            (v) => cell(
                              v.value,
                              header: true,
                              center: v.key != 1 && v.key != 3 && v.key != 5,
                            ),
                          )
                          .toList(),
                      header: true,
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: _vertical,
                        thumbVisibility: true,
                        interactive: true,
                        notificationPredicate: (n) =>
                            n.metrics.axis == Axis.vertical,
                        child: SingleChildScrollView(
                          controller: _vertical,
                          padding: const EdgeInsets.only(bottom: 18),
                          child: widget.rows.isEmpty
                              ? AppEmptyState(
                                  title: tr(
                                    'لا توجد مخالصات',
                                    'No settlements',
                                  ),
                                )
                              : Column(
                                  children: List.generate(widget.rows.length, (
                                    index,
                                  ) {
                                    final entry = widget.rows[index];
                                    return row([
                                      cell(
                                        '${widget.offset + index + 1}',
                                        center: true,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.name,
                                              textAlign: TextAlign.start,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: wizardInk,
                                              ),
                                            ),
                                            if (entry.employeeNumber.isNotEmpty)
                                              const SizedBox(height: 4),
                                            if (entry.employeeNumber.isNotEmpty)
                                              Text(
                                                entry.employeeNumber,
                                                textAlign: TextAlign.start,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF777098),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      cell(
                                        widget.date(entry.date),
                                        center: true,
                                      ),
                                      cell(widget.type(entry.type)),
                                      cell(
                                        entry.net.toStringAsFixed(2),
                                        center: true,
                                      ),
                                      cell(
                                        entry.notes.isEmpty ? '—' : entry.notes,
                                      ),
                                      PopupMenuButton<String>(
                                        key: ValueKey(
                                          'settlement-actions-${entry.id}',
                                        ),
                                        tooltip: tr('الإجراءات', 'Actions'),
                                        icon: const Icon(
                                          Icons.more_horiz,
                                          size: 20,
                                          color: wizardPurple,
                                        ),
                                        onSelected: (action) {
                                          if (action == 'details') {
                                            widget.onDetails(entry);
                                          } else if (action == 'file') {
                                            widget.onFile(entry);
                                          } else {
                                            widget.onProfile(entry);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          PopupMenuItem(
                                            value: 'details',
                                            child: Text(
                                              tr(
                                                'عرض المخالصة',
                                                'View settlement',
                                              ),
                                            ),
                                          ),
                                          if (entry.filePath != null)
                                            PopupMenuItem(
                                              value: 'file',
                                              child: Text(
                                                tr(
                                                  'عرض المرفق',
                                                  'View attachment',
                                                ),
                                              ),
                                            ),
                                          PopupMenuItem(
                                            value: 'profile',
                                            child: Text(
                                              tr(
                                                'ملف الموظف',
                                                'Employee profile',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ]);
                                  }),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _AttachmentDecoration extends Decoration {
  const _AttachmentDecoration();
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _AttachmentPainter();
}

class _AttachmentPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = RRect.fromRectAndRadius(
      offset & configuration.size!,
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFFFAF7FF));
    final path = Path()..addRRect(rect);
    final paint = Paint()
      ..color = const Color(0xFFD9C5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (double position = 0; position < metric.length; position += 8) {
        canvas.drawPath(
          metric.extractPath(position, math.min(position + 4, metric.length)),
          paint,
        );
      }
    }
  }
}
