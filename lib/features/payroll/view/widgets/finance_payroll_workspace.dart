import 'package:flutter/material.dart';
import '../../../../core/ui/app_data_state.dart';
import '../../domain/models/payroll_item.dart';
import '../../domain/models/payroll_run.dart';
import '../../domain/repos/payroll_repo.dart';
import 'finance_payroll_table.dart';
import 'payroll_format.dart';

class FinancePayrollWorkspace extends StatefulWidget {
  const FinancePayrollWorkspace({
    super.key,
    required this.repo,
    this.initialRunId,
    this.onHistory,
    this.onDisbursement,
    this.today,
  });
  final PayrollRepo repo;
  final String? initialRunId;
  final VoidCallback? onHistory;
  final ValueChanged<String>? onDisbursement;
  final DateTime? today;
  @override
  State<FinancePayrollWorkspace> createState() =>
      _FinancePayrollWorkspaceState();
}

class _FinancePayrollWorkspaceState extends State<FinancePayrollWorkspace> {
  final _notes = TextEditingController();
  final _pageScroll = ScrollController();
  final _notesKey = GlobalKey();
  final _drafts = <String, String>{};
  final _decided = <String>{};
  List<PayrollRun> _runs = [];
  List<PayrollItem> _items = [];
  PayrollRun? _run;
  DateTime? _start, _end;
  bool _loading = true, _busy = false, _dirty = false, _reasonRequired = false;
  Object? _error;
  String? _message;
  int _generation = 0;
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  String _tr(String ar, String en) => _ar ? ar : en;
  String _period(DateTime date) {
    const ar = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    const en = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${(_ar ? ar : en)[date.month - 1]} ${date.year}';
  }

  bool get _pending =>
      _run?.status == 'pending_finance_manager' && !_decided.contains(_run?.id);
  bool get _complete =>
      _run != null &&
      _items.isNotEmpty &&
      _run!.totalEmployees == _items.length &&
      ((_items.fold<num>(0, (sum, i) => sum + i.total) - _run!.totalAmount)
              .abs() <
          0.01);

  @override
  void initState() {
    super.initState();
    final now = widget.today ?? DateTime.now();
    _start = DateTime(now.year, now.month);
    _end = DateTime(now.year, now.month + 1, 0);
    _load(initial: true);
  }

  @override
  void dispose() {
    _generation++;
    _notes.dispose();
    _pageScroll.dispose();
    super.dispose();
  }

  void _remember() {
    if (_run != null) _drafts[_run!.id] = _notes.text;
  }

  Future<void> _load({bool initial = false, String? preferred}) async {
    if (_start != null && _end != null && _start!.isAfter(_end!)) {
      setState(() {
        _message = _tr(
          'بداية الفترة يجب أن تسبق نهايتها.',
          'Start date must be before the end date.',
        );
      });
      return;
    }
    _remember();
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      final all = <PayrollRun>[];
      final byId =
          (initial && widget.initialRunId != null) || preferred != null;
      for (var page = 0; ; page++) {
        final result = await widget.repo.fetchRuns(
          page: page,
          pageSize: 50,
          startDate: byId ? null : _start,
          endDate: byId ? null : _end,
          sortBy: 'created_at',
          ascending: false,
        );
        all.addAll(result.items);
        if (all.length >= result.total || result.items.isEmpty) break;
      }
      if (!mounted || generation != _generation) return;
      PayrollRun? selected;
      final wanted = preferred ?? (byId ? widget.initialRunId : null);
      for (final run in all) {
        if (run.id == wanted) selected = run;
      }
      if (byId && selected == null) throw StateError('Payroll not found');
      if (selected == null && all.isNotEmpty) {
        selected = all.firstWhere(
          (r) => r.status == 'pending_finance_manager',
          orElse: () => all.first,
        );
      }
      _runs = byId ? [selected!] : all;
      if (byId) {
        _start = selected!.periodStart;
        _end = selected.periodEnd;
      }
      await _read(selected, generation);
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  Future<void> _read(PayrollRun? run, int generation) async {
    final items = run == null
        ? <PayrollItem>[]
        : await widget.repo.fetchRunItems(runId: run.id);
    final notes = run == null
        ? null
        : await widget.repo.fetchFinanceReviewNotes(runId: run.id);
    if (!mounted || generation != _generation) return;
    setState(() {
      _run = run;
      _items = items;
      _notes.text = run == null
          ? ''
          : (_drafts[run.id] ?? notes ?? run.rejectReason ?? '');
      _loading = false;
      _dirty = false;
      _reasonRequired = false;
    });
  }

  Future<void> _select(String? id) async {
    if (id == null || _busy) return;
    _remember();
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await _read(_runs.firstWhere((r) => r.id == id), generation);
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _error = error;
        });
      }
    }
  }

  Future<void> _decision(bool approve) async {
    if (_busy || !_pending || _dirty || _loading || (approve && !_complete)) {
      return;
    }
    if (!approve && _notes.text.trim().isEmpty) {
      setState(() {
        _reasonRequired = true;
      });
      if (_notesKey.currentContext != null) {
        await Scrollable.ensureVisible(_notesKey.currentContext!);
      }
      return;
    }
    final id = _run!.id;
    _remember();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (approve) {
        await widget.repo.financeManagerApprove(
          runId: id,
          notes: _notes.text.trim(),
        );
      } else {
        await widget.repo.rejectRun(
          runId: id,
          reason: _notes.text.trim(),
          rejectedByRole: 'finance_manager',
        );
      }
      if (!mounted) return;
      _decided.add(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? _tr(
                    'تم إرسال المسير لاعتماد الإدارة.',
                    'Payroll sent for management approval.',
                  )
                : _tr(
                    'تم رفض المسير وإعادته للموارد البشرية مع السبب.',
                    'Payroll returned to HR with your reason.',
                  ),
          ),
        ),
      );
      await _load(preferred: id);
    } catch (error) {
      if (!mounted) return;
      final value = error.toString();
      setState(() {
        _message = value.contains('PGRST202') || value.contains('42883')
            ? _tr(
                'خدمة المراجعة المالية تحتاج تحديثًا. شغّل ملف إعداد مراجعة الرواتب في Supabase ثم أعد المحاولة.',
                'Payroll review service requires its database update. Please contact your administrator.',
              )
            : classifyDataFailure(error) == DataFailureKind.connection
            ? _tr(
                'تعذر الاتصال. تحقق من الإنترنت وأعد المحاولة؛ ملاحظاتك محفوظة هنا.',
                'Connection failed. Check your internet and retry; your notes are kept here.',
              )
            : _tr(
                'تعذر تسجيل القرار. حدّث المسير للتأكد من حالته ثم أعد المحاولة.',
                'Could not save the decision. Reload the payroll to check its current status.',
              );
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _pickDate(bool start) async {
    final value = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? widget.today ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (value != null && mounted) {
      setState(() {
        if (start) {
          _start = value;
        } else {
          _end = value;
        }
        _dirty = true;
      });
    }
  }

  String _status(PayrollRun? run) => switch (run?.status) {
    'pending_finance_manager' => _tr(
      'بانتظار المراجعة المالية',
      'Awaiting finance review',
    ),
    'pending_admin_approval' => _tr(
      'بانتظار اعتماد الإدارة',
      'Awaiting management approval',
    ),
    'approved' => _tr('معتمد', 'Approved'),
    'rejected_by_finance_manager' ||
    'rejected_by_admin' => _tr('مرفوض', 'Rejected'),
    'draft' => _tr('مسودة', 'Draft'),
    _ => _tr('مراجعة الرواتب', 'Payroll review'),
  };

  String get _nextStep => switch (_run?.status) {
    'draft' => _tr(
      'هذا المسير ما زال مسودة. يجب أن ترسله الموارد البشرية للمراجعة المالية أولًا حتى تظهر أزرار الإرسال والرفض هنا.',
      'This payroll is still a draft. HR must submit it for finance review before you can approve or reject it here.',
    ),
    'pending_admin_approval' => _tr(
      'المراجعة المالية انتهت، والمسير ينتظر اعتماد مدير النظام. بعد اعتماده يمكنك تكليف المحاسب بالصرف.',
      'Finance review is complete. Management must approve this payroll before you can assign disbursement.',
    ),
    'approved' => _tr(
      'هذا المسير معتمد من الإدارة. استخدم «متابعة صرف المسير» لمراجعة حالة الصرف أو تكليف المحاسب.',
      'Management approved this payroll. Use Manage payroll disbursement to assign an accountant or check payment status.',
    ),
    'rejected_by_finance_manager' || 'rejected_by_admin' => _tr(
      'هذا المسير مرفوض. يجب أن تعالج الموارد البشرية سبب الرفض وتعيد إرساله للمراجعة.',
      'This payroll was rejected. HR must address the rejection reason and submit it for review again.',
    ),
    'pending_finance_manager' => _tr(
      'تم تسجيل قرارك على هذا المسير. حدّث الحالة للاطلاع على الخطوة التالية.',
      'Your decision has been recorded. Refresh the status to see the next step.',
    ),
    _ => _tr(
      'حالة هذا المسير لا تسمح بالمراجعة المالية حاليًا. حدّث الحالة؛ وإذا كانت الموافقة ما زالت مسندة للمالية، يلزم مراجعة توافقها مع المسير.',
      'This payroll cannot be reviewed in its current state. Refresh its status; if its approval is still assigned to finance, the workflow needs checking.',
    ),
  };

  InputDecoration _input({String? hint, Widget? prefix, String? error}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: prefix,
        errorText: error,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: financeBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: financeBorder),
        ),
      );

  Widget _date(bool start) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        start
            ? _tr('من بداية الفترة', 'Period starts')
            : _tr('إلى نهاية الفترة', 'Period ends'),
        style: const TextStyle(color: Color(0xFF686197), fontSize: 14),
      ),
      const SizedBox(height: 5),
      OutlinedButton(
        onPressed: _busy || _loading ? null : () => _pickDate(start),
        style: OutlinedButton.styleFrom(
          foregroundColor: financeNavy,
          side: const BorderSide(color: financeBorder),
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                (start ? _start : _end) == null
                    ? _tr('كل الفترات', 'All periods')
                    : payrollDate((start ? _start : _end)!),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
              ),
            ),
            const Icon(Icons.calendar_month_outlined, size: 19),
          ],
        ),
      ),
    ],
  );

  Widget _summary(
    String label,
    String value,
    IconData icon, {
    String? unit,
    bool blue = false,
  }) => Container(
    constraints: const BoxConstraints(minHeight: 96),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: Border.all(color: financeBorder),
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 15, color: Color(0xFF686197)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: financeNavy,
                ),
              ),
              if (unit != null)
                Text(
                  unit,
                  style: const TextStyle(
                    color: Color(0xFF686197),
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 25,
          backgroundColor: blue
              ? const Color(0xFFE7EDFF)
              : const Color(0xFFF0E5FF),
          child: Icon(
            icon,
            size: 27,
            color: blue ? const Color(0xFF0879F8) : financePurple,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      return Scrollbar(
        controller: _pageScroll,
        thumbVisibility: true,
        interactive: true,
        notificationPredicate: (n) => n.depth == 0,
        child: SingleChildScrollView(
          controller: _pageScroll,
          primary: false,
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              minHeight: bounds.hasBoundedHeight && bounds.maxHeight > 32
                  ? bounds.maxHeight - 32
                  : 0,
            ),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: financeBorder),
              borderRadius: BorderRadius.circular(9),
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: financeNavy),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tr('مراجعة الرواتب', 'Payroll review'),
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: financeNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _tr(
                              'مراجعة تفاصيل الرواتب قبل إرسالها لاعتماد الإدارة',
                              'Review payroll details before sending for management approval',
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF77709A),
                            ),
                          ),
                        ],
                      ),
                      if (widget.onHistory != null)
                        TextButton.icon(
                          onPressed: _busy ? null : widget.onHistory,
                          icon: const Icon(Icons.history, size: 18),
                          label: Text(_tr('سجل المسيرات', 'Payroll history')),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _run?.status == 'approved'
                            ? const Color(0xFFE2F7ED)
                            : const Color(0xFFFFF0E8),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        _status(_run),
                        style: TextStyle(
                          color: _run?.status == 'approved'
                              ? const Color(0xFF168654)
                              : const Color(0xFFE77B28),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, c) {
                      final dates = [_date(true), _date(false)];
                      final show = FilledButton.icon(
                        key: const ValueKey('finance-show'),
                        onPressed: _busy || _loading ? null : () => _load(),
                        style: FilledButton.styleFrom(
                          backgroundColor: financePurple,
                          minimumSize: const Size(160, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        icon: const Icon(Icons.search, size: 19),
                        label: Text(_tr('عرض الرواتب', 'Show payroll')),
                      );
                      if (c.maxWidth < 640) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            dates[0],
                            const SizedBox(height: 10),
                            dates[1],
                            const SizedBox(height: 10),
                            show,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: dates[0]),
                          const SizedBox(width: 16),
                          Expanded(child: dates[1]),
                          const SizedBox(width: 18),
                          show,
                        ],
                      );
                    },
                  ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _message!,
                          style: const TextStyle(
                            color: Color(0xFFCE3F48),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  if (_loading)
                    const AppLoadingState()
                  else if (_error != null)
                    AppFailureState(
                      error: _error,
                      onRetry: () => _load(
                        initial: widget.initialRunId != null,
                        preferred: _run?.id,
                      ),
                    )
                  else if (_run == null)
                    AppEmptyState(
                      title: _tr(
                        'لا توجد مسيرات رواتب لهذه الفترة',
                        'No payroll runs for this period',
                      ),
                      filtered: _start != null || _end != null,
                      onClear: () {
                        setState(() {
                          _start = null;
                          _end = null;
                        });
                        _load();
                      },
                    )
                  else ...[
                    if (_runs.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DropdownButtonFormField<String>(
                          initialValue: _run!.id,
                          isExpanded: true,
                          decoration: _input(
                            hint: _tr('اختر المسير', 'Select payroll'),
                          ),
                          items: _runs
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r.id,
                                  child: Text(
                                    '${payrollDate(r.periodStart)} — ${payrollDate(r.periodEnd)} · ${_status(r)}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _busy || _dirty ? null : _select,
                        ),
                      ),
                    LayoutBuilder(
                      builder: (context, c) {
                        final cards = [
                          _summary(
                            _tr('فترة الرواتب', 'Payroll period'),
                            _period(_run!.periodStart),
                            Icons.calendar_month_outlined,
                          ),
                          _summary(
                            _tr('إجمالي الرواتب', 'Total payroll'),
                            payrollMoney(_run!.totalAmount),
                            Icons.description_outlined,
                            unit: _tr('ريال', 'SAR'),
                          ),
                          _summary(
                            _tr('عدد الموظفين', 'Employees'),
                            '${_run!.totalEmployees}',
                            Icons.groups_rounded,
                            unit: _tr('موظف', 'employees'),
                            blue: true,
                          ),
                        ];
                        if (c.maxWidth < 700) {
                          return Column(
                            children: [
                              for (final card in cards)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: card,
                                ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            for (var i = 0; i < cards.length; i++) ...[
                              if (i > 0) const SizedBox(width: 12),
                              Expanded(child: cards[i]),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _tr('تفاصيل الرواتب', 'Payroll details'),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_items.isEmpty)
                      AppEmptyState(
                        title: _tr(
                          'لا توجد بنود في هذا المسير',
                          'This payroll has no salary items',
                        ),
                      )
                    else
                      FinancePayrollTable(items: _items),
                    if (!_complete && _pending)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _tr(
                            'بنود المسير لا تطابق الإجمالي المسجل. حدّث البيانات أو أعده للموارد البشرية للمراجعة.',
                            'Salary items do not match the recorded totals. Reload or return to HR for review.',
                          ),
                          style: const TextStyle(color: Color(0xFFCE3F48)),
                        ),
                      ),
                    if (_dirty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _tr(
                            'اضغط «عرض الرواتب» لتطبيق الفترة قبل اتخاذ القرار.',
                            'Apply the dates with Show payroll before making a decision.',
                          ),
                          style: const TextStyle(color: Color(0xFFE77B28)),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _tr('ملاحظات المراجعة', 'Review notes'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: _notesKey,
                      controller: _notes,
                      readOnly: !_pending || _busy,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 500,
                      style: const TextStyle(fontSize: 15, color: financeNavy),
                      onChanged: (_) {
                        _remember();
                        if (_reasonRequired) {
                          setState(() {
                            _reasonRequired = false;
                          });
                        }
                      },
                      decoration: _input(
                        hint: _tr(
                          'أضف ملاحظاتك هنا …',
                          'Add your review notes …',
                        ),
                        error: _reasonRequired
                            ? _tr(
                                'اكتب سبب الرفض في ملاحظات المراجعة.',
                                'Enter a rejection reason in the review notes.',
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_pending)
                      LayoutBuilder(
                        builder: (context, c) {
                          final send = FilledButton.icon(
                            key: const ValueKey('finance-approve'),
                            onPressed: _busy || _dirty || !_complete
                                ? null
                                : () => _decision(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: financePurple,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            icon: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.near_me,
                                    textDirection: TextDirection.ltr,
                                    size: 21,
                                  ),
                            label: Text(
                              _tr(
                                'إرسال لاعتماد الإدارة',
                                'Send for management approval',
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                          final reject = OutlinedButton.icon(
                            key: const ValueKey('finance-reject'),
                            onPressed: _busy || _dirty
                                ? null
                                : () => _decision(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF3D45),
                              side: const BorderSide(color: Color(0xFFFF636A)),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            icon: const Icon(
                              Icons.lock_person_outlined,
                              size: 20,
                            ),
                            label: Text(
                              _tr('رفض مع سبب', 'Reject with reason'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                          if (c.maxWidth < 650) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                send,
                                const SizedBox(height: 10),
                                reject,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(flex: 2, child: send),
                              const SizedBox(width: 12),
                              Expanded(child: reject),
                            ],
                          );
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1E8FC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _status(_run),
                              style: const TextStyle(
                                color: financeNavy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _nextStep,
                              style: const TextStyle(
                                color: Color(0xFF77709A),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton.icon(
                                key: const ValueKey('finance-refresh-status'),
                                onPressed: _busy || _loading
                                    ? null
                                    : () => _load(preferred: _run!.id),
                                icon: const Icon(Icons.refresh, size: 18),
                                label: Text(
                                  _tr(
                                    'تحديث حالة المسير',
                                    'Refresh payroll status',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_run!.status == 'approved' &&
                        widget.onDisbursement != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: FilledButton.icon(
                          onPressed: () => widget.onDisbursement!(_run!.id),
                          icon: const Icon(Icons.payments_outlined),
                          label: Text(
                            _tr(
                              'متابعة صرف المسير',
                              'Manage payroll disbursement',
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
