import 'package:flutter/material.dart';
import 'package:erp_sys/core/ui/app_data_state.dart';
import '../../domain/models/payroll_item.dart';
import '../../domain/models/payroll_run.dart';
import '../../domain/repos/payroll_repo.dart';
import 'payroll_format.dart';
import 'payroll_run_items_table.dart';

class PayrollPreparationView extends StatefulWidget {
  const PayrollPreparationView({
    super.key,
    required this.repo,
    required this.onHistory,
    required this.onSubmitted,
    this.savedRun,
  });
  final PayrollRepo repo;
  final VoidCallback onHistory;
  final ValueChanged<String> onSubmitted;
  final PayrollRun? savedRun;
  @override
  State<PayrollPreparationView> createState() => _PayrollPreparationViewState();
}

class _PayrollPreparationViewState extends State<PayrollPreparationView> {
  late DateTime _start;
  late DateTime _end;
  List<PayrollItem> _items = [];
  String? _runId;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = widget.savedRun?.periodStart ?? DateTime(now.year, now.month, 1);
    _end = widget.savedRun?.periodEnd ?? DateTime(now.year, now.month + 1, 0);
    _runId = widget.savedRun?.id;
    _load();
  }

  Future<void> _load() async {
    try {
      final items = _runId == null
          ? await widget.repo.fetchPreparationItems()
          : await widget.repo.fetchRunItems(runId: _runId!);
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _pick(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_end.isBefore(_start)) {
          _end = DateTime(picked.year, picked.month + 1, 0);
        }
      } else {
        _end = picked;
        if (_start.isAfter(_end)) {
          _start = DateTime(picked.year, picked.month, 1);
        }
      }
    });
  }

  Future<void> _save(bool submit) async {
    if (_busy || _loading || _error != null || _items.isEmpty) return;
    setState(() {
      _busy = true;
    });
    try {
      final id =
          _runId ??
          await widget.repo.createRun(periodStart: _start, periodEnd: _end);
      // Preserve the ID even if fetching the saved items or submitting fails.
      // A retry must never create a second run.
      if (mounted) {
        setState(() {
          _runId = id;
        });
      }
      final saved = await widget.repo.fetchRunItems(runId: id);
      if (mounted) {
        setState(() {
          _items = saved;
        });
      }
      if (submit) {
        if (saved.isEmpty) {
          throw StateError('Cannot submit an empty payroll run');
        }
        await widget.repo.submitToFinanceManager(runId: id);
        if (mounted) widget.onSubmitted(id);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_ar ? 'تم حفظ المسودة' : 'Draft saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        final missingService =
            e.toString().contains('PGRST202') || e.toString().contains('42883');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              missingService
                  ? tr(
                      'خدمة إرسال الرواتب تحتاج تحديثًا من مسؤول النظام. المسير محفوظ ويمكن إعادة المحاولة بعد التحديث.',
                      'Payroll submission service needs an administrator update. Your draft is saved; retry after the update.',
                    )
                  : tr(
                      'تعذّر حفظ أو إرسال المسير. تحقق من الاتصال وحالة المسير ثم أعد المحاولة.',
                      'Could not save or submit payroll. Check your connection and payroll status, then retry.',
                    ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String ar, String en) => _ar ? ar : en;
  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF21194E);
    const purple = Color(0xFF8654BC);
    const border = Color(0xFFECE6F4);
    num sum(num Function(PayrollItem) field) =>
        _items.fold<num>(0, (s, i) => s + field(i));
    final values = [
      sum((i) => i.basicSalary),
      sum((i) => i.housingAllowance),
      sum((i) => i.transportAllowance),
      sum((i) => i.otherAllowance),
      sum((i) => i.total),
    ];
    Widget dateField(bool start) => SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tr(
                  start ? 'من تاريخ' : 'إلى تاريخ',
                  start ? 'From date' : 'To date',
                ),
                style: const TextStyle(fontSize: 13, color: ink),
              ),
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 5),
          OutlinedButton(
            onPressed: _busy || _runId != null ? null : () => _pick(start),
            style: OutlinedButton.styleFrom(
              foregroundColor: ink,
              side: const BorderSide(color: border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              minimumSize: const Size(double.infinity, 42),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    payrollDate(start ? _start : _end),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const Icon(Icons.calendar_month_outlined, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
    final enabled = !_loading && !_busy && _error == null && _items.isNotEmpty;
    final actions = Wrap(
      textDirection: TextDirection.ltr,
      spacing: 12,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 220,
          height: 44,
          child: OutlinedButton.icon(
            key: const ValueKey('payroll-save'),
            onPressed: enabled ? () => _save(false) : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: purple,
              side: const BorderSide(color: Color(0xFFBD96EC)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(
              tr('حفظ كمسودة', 'Save draft'),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        SizedBox(
          width: (MediaQuery.sizeOf(context).width - 74)
              .clamp(180, 340)
              .toDouble(),
          height: 44,
          child: FilledButton.icon(
            key: const ValueKey('payroll-submit'),
            onPressed: enabled ? () => _save(true) : null,
            style: FilledButton.styleFrom(
              backgroundColor: purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            icon: Transform.rotate(
              angle: -0.7853981633974483,
              child: const Icon(
                Icons.send_sharp,
                size: 20,
                textDirection: TextDirection.ltr,
              ),
            ),
            label: Text(
              tr('إرسال للمراجعة المالية', 'Send to finance review'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E3FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    color: purple,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('تجهيز مسير الرواتب', 'Prepare payroll'),
                        style: const TextStyle(
                          fontSize: 26,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(
                          'إعداد مسير رواتب ${MaterialLocalizations.of(context).formatMonthYear(_start)}',
                          'Prepare payroll for the selected period',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF696381),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _busy ? null : widget.onHistory,
                  tooltip: tr('المسيرات السابقة', 'Previous payroll runs'),
                  icon: const Icon(Icons.history_rounded, color: purple),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, c) {
                final dates = Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [dateField(true), dateField(false)],
                );
                final badge = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECD5),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    widget.savedRun?.status.startsWith('rejected') == true
                        ? tr('مرفوض', 'Rejected')
                        : tr('مسودة', 'Draft'),
                    style: const TextStyle(
                      color: Color(0xFFF48B19),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
                return c.maxWidth >= 600
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: c.maxWidth >= 900 ? c.maxWidth * .38 : 0,
                          ),
                          Expanded(child: dates),
                          badge,
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [badge, const SizedBox(height: 10), dates],
                      );
              },
            ),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(color: purple),
            if (widget.savedRun?.rejectReason?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${tr('سبب الرفض', 'Rejection reason')}: ${widget.savedRun!.rejectReason}',
                  style: const TextStyle(color: Color(0xFFF04461)),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr('عناصر الرواتب', 'Payroll items'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppDataRegion(
                    loading: _loading,
                    error: _error,
                    onRetry: _load,
                    child: PayrollRunItemsTable(items: _items, compact: true),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, c) {
                      final labels = [
                        tr('إجمالي الموظفين', 'Employees'),
                        tr('إجمالي الرواتب الأساسية', 'Basic salaries'),
                        tr('إجمالي بدل السكن', 'Housing'),
                        tr('إجمالي بدل النقل', 'Transport'),
                        tr('إجمالي البدلات الأخرى', 'Other allowances'),
                        tr('الإجمالي الكلي', 'Grand total'),
                      ];
                      final cols = c.maxWidth >= 800
                          ? 6
                          : c.maxWidth >= 440
                          ? 3
                          : 2;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Wrap(
                          children: [
                            for (var i = 0; i < 6; i++)
                              SizedBox(
                                width: c.maxWidth / cols,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        labels[i],
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: purple,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        i == 0
                                            ? '${_items.length}'
                                            : payrollMoney(values[i - 1]),
                                        textDirection: TextDirection.ltr,
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w700,
                                          color: ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Align(alignment: Alignment.centerLeft, child: actions),
            const SizedBox(height: 10),
            Text(
              tr(
                'الأساسي والبدلات فقط؛ الخصومات والأوفر تايم لم تُحتسب.',
                'Basic salary and allowances only; deductions and overtime are not calculated.',
              ),
              style: const TextStyle(fontSize: 11, color: Color(0xFF77738C)),
            ),
          ],
        ),
      ),
    );
  }
}
