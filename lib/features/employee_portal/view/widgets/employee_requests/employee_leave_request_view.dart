import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/safe_file_picker.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../cubit/employee_leave_request_cubit.dart';
import 'employee_leave_balances.dart';

int leaveRequestDays(DateTime start, DateTime end) =>
    DateTime.utc(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
    1;

class EmployeeLeaveRequestView extends StatefulWidget {
  const EmployeeLeaveRequestView({
    super.key,
    required this.onHistory,
    this.showBalanceSummary = false,
  });
  final VoidCallback onHistory;
  final bool showBalanceSummary;
  @override
  State<EmployeeLeaveRequestView> createState() =>
      _EmployeeLeaveRequestViewState();
}

class _EmployeeLeaveRequestViewState extends State<EmployeeLeaveRequestView> {
  final _form = GlobalKey<FormState>();
  final _notes = TextEditingController();
  String _type = 'annual';
  DateTime? _start;
  DateTime? _end;
  XFile? _file;
  bool _picking = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _reset() {
    _form.currentState?.reset();
    setState(() {
      _type = 'annual';
      _start = null;
      _end = null;
      _file = null;
      _notes.clear();
    });
    context.read<EmployeeLeaveRequestCubit>()
      ..newRequest()
      ..loadBalance();
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end ?? _start) ?? now,
      firstDate: start
          ? DateTime(now.year - 1)
          : _start ?? DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_end != null && _end!.isBefore(picked)) _end = null;
      } else {
        _end = picked;
      }
    });
    if (start) {
      await context.read<EmployeeLeaveRequestCubit>().loadBalance(
        year: picked.year,
      );
    }
  }

  Future<void> _pickFile() async {
    if (_picking) return;
    setState(() => _picking = true);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    try {
      final file = await SafeFilePicker.openSingle(
        context: context,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'PDF', extensions: ['pdf']),
        ],
      );
      if (file == null) return;
      if (!file.name.toLowerCase().endsWith('.pdf') ||
          await file.length() > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ar
                    ? 'اختر ملف PDF لا يتجاوز 10 ميجابايت'
                    : 'Choose a PDF no larger than 10 MB',
              ),
            ),
          );
        }
        return;
      }
      if (mounted) setState(() => _file = file);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar
                  ? 'تعذّر اختيار الملف؛ حاول مجددًا'
                  : 'Unable to select the file. Try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<EmployeeLeaveRequestCubit, EmployeeLeaveRequestState>(
    builder: (context, state) {
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      final t = AppLocalizations.of(context)!;
      final cs = Theme.of(context).colorScheme;
      final cubit = context.read<EmployeeLeaveRequestCubit>();
      final busy = state.saving || _picking;
      final selected = state.balances
          .where((balance) => balance.type == _type)
          .firstOrNull;
      String number(double value) => value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
      Widget label(String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '$text${required ? ' *' : ''}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );
      InputDecoration decoration() => InputDecoration(
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? cs.surfaceContainerLow
            : const Color(0xFFFAFBFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: .5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: .5),
          ),
        ),
      );
      Widget dateField(bool start) {
        final date = start ? _start : _end;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label(start ? t.startDate : t.endDate, required: true),
            TextFormField(
              key: ValueKey(
                'leave-${start ? 'start' : 'end'}-${date?.toIso8601String()}',
              ),
              readOnly: true,
              enabled: !busy,
              initialValue: date == null
                  ? ''
                  : '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}',
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              decoration: decoration().copyWith(
                hintText: ar ? 'اختر التاريخ' : 'Select date',
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
              ),
              onTap: () => _pickDate(start),
              validator: (_) => date == null
                  ? (ar ? 'اختر التاريخ' : 'Select a date')
                  : !start && _start != null && date.isBefore(_start!)
                  ? (ar
                        ? 'تاريخ النهاية يسبق البداية'
                        : 'End date precedes start date')
                  : null,
            ),
          ],
        );
      }

      final balance = Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: .4)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primary.withValues(alpha: .1),
              child: Icon(Icons.calendar_month, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ar ? 'رصيد الإجازات' : 'Leave balance',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (state.loading)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    Text(
                      state.balanceError != null || selected == null
                          ? '—'
                          : number(selected.remaining),
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  Text(
                    state.loading
                        ? (ar ? 'جارٍ التحميل' : 'Loading')
                        : state.balanceError != null
                        ? (ar ? 'تعذّر تحميل الرصيد' : 'Balance unavailable')
                        : selected == null
                        ? (ar
                              ? 'لا يوجد رصيد لهذا النوع'
                              : 'No balance for this type')
                        : (ar
                              ? 'من ${number(selected.entitlement)} يوم'
                              : 'of ${number(selected.entitlement)} days'),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  if (state.balanceError != null)
                    TextButton(
                      onPressed: () => cubit.loadBalance(year: _start?.year),
                      child: Text(t.retry),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
      final fields = Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ar ? 'بيانات الطلب' : 'Request details',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final type = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label(ar ? 'نوع الإجازة' : 'Leave type', required: true),
                    DropdownButtonFormField<String>(
                      key: ValueKey('employee-leave-type-$_type'),
                      initialValue: _type,
                      isExpanded: true,
                      decoration: decoration(),
                      items: [
                        DropdownMenuItem(
                          value: 'annual',
                          child: Text(t.leaveTypeAnnual),
                        ),
                        DropdownMenuItem(
                          value: 'sick',
                          child: Text(t.leaveTypeSick),
                        ),
                        DropdownMenuItem(
                          value: 'unpaid',
                          child: Text(t.leaveTypeUnpaid),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text(t.leaveTypeOther),
                        ),
                      ],
                      onChanged: busy
                          ? null
                          : (value) =>
                                setState(() => _type = value ?? 'annual'),
                    ),
                  ],
                );
                if (widget.showBalanceSummary) {
                  return type;
                }
                return constraints.maxWidth >= 600
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: type),
                          const SizedBox(width: 18),
                          balance,
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [type, const SizedBox(height: 16), balance],
                      );
              },
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth >= 450
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: dateField(true)),
                        const SizedBox(width: 16),
                        Expanded(child: dateField(false)),
                      ],
                    )
                  : Column(
                      children: [
                        dateField(true),
                        const SizedBox(height: 16),
                        dateField(false),
                      ],
                    ),
            ),
            if (_start != null && _end != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  ar
                      ? 'مدة الإجازة: ${leaveRequestDays(_start!, _end!)} يوم'
                      : 'Leave duration: ${leaveRequestDays(_start!, _end!)} days',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            label(ar ? 'سبب الإجازة' : 'Leave reason', required: true),
            TextFormField(
              key: const ValueKey('employee-leave-reason'),
              controller: _notes,
              enabled: !busy,
              maxLines: 3,
              maxLength: 500,
              decoration: decoration(),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? (ar ? 'اكتب سبب الإجازة' : 'Enter a reason for your leave')
                  : null,
            ),
            const SizedBox(height: 8),
            label(ar ? 'مرفقات (اختياري)' : 'Attachment (optional)'),
            OutlinedButton(
              onPressed: busy ? null : _pickFile,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  const Icon(Icons.upload_file_outlined, size: 30),
                  const SizedBox(height: 8),
                  Text(
                    _file?.name ?? (ar ? 'إضافة مرفق' : 'Add attachment'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    ar
                        ? 'اختر ملف PDF حتى 10 ميجابايت'
                        : 'Choose a PDF up to 10 MB',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (_file != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: busy ? null : () => setState(() => _file = null),
                  child: Text(
                    ar ? 'إزالة الملف المختار' : 'Remove selected file',
                  ),
                ),
              ),
            if (state.submitError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  t.saveFailed(state.submitError!),
                  style: TextStyle(color: cs.error),
                ),
              ),
            if (busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('employee-leave-submit'),
                    onPressed: busy
                        ? null
                        : () {
                            if (_form.currentState!.validate()) {
                              cubit.submit(
                                type: _type,
                                start: _start!,
                                end: _end!,
                                notes: _notes.text,
                                attachment: _file,
                              );
                            }
                          },
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: Text(
                      state.saving
                          ? t.saving
                          : (ar ? 'إرسال الطلب' : 'Submit request'),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : _reset,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(t.cancel),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      final steps = _RequestPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ar ? 'مراحل الطلب' : 'Request stages',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            for (final step in [
              (
                Icons.send,
                ar ? 'إرسال الطلب' : 'Submit request',
                ar
                    ? 'إرسال الطلب إلى مسار الموافقات'
                    : 'Send to the approval workflow',
              ),
              (
                Icons.search,
                ar ? 'مراجعة' : 'Review',
                ar
                    ? 'تراجع الجهة المختصة الطلب حسب المسار الحالي'
                    : 'The relevant approver reviews your request',
              ),
              (
                Icons.check,
                ar ? 'قرار' : 'Decision',
                ar
                    ? 'تابع النتيجة من سجل الطلبات'
                    : 'Follow the result in request history',
              ),
            ])
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      step.$1 == (state.submitted ? Icons.search : Icons.send)
                      ? cs.primary.withValues(alpha: .1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          step.$1 ==
                              (state.submitted ? Icons.search : Icons.send)
                          ? cs.primary
                          : cs.outlineVariant,
                      child: Icon(step.$1, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.$2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step.$3,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
      final content = _RequestPanel(
        child: state.submitted
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.check_circle, color: cs.primary, size: 56),
                  const SizedBox(height: 20),
                  Text(
                    ar
                        ? 'تم إرسال طلب الإجازة للمراجعة'
                        : 'Leave request submitted for review',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ar
                        ? 'يمكنك متابعة الحالة من سجل الطلبات'
                        : 'Track the status in request history',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: widget.onHistory,
                    child: Text(ar ? 'سجل الطلبات' : 'Request history'),
                  ),
                  TextButton(
                    onPressed: _reset,
                    child: Text(ar ? 'طلب جديد' : 'New request'),
                  ),
                ],
              )
            : fields,
      );
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.showBalanceSummary) ...[
            const EmployeeLeaveBalances(),
            const SizedBox(height: 22),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.flight_takeoff, size: 28, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ar ? 'طلب إجازة' : 'Leave request',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ar
                          ? 'قدّم طلب إجازة وتابع حالته'
                          : 'Submit a leave request and track its status',
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: busy ? null : widget.onHistory,
              icon: const Icon(Icons.history, size: 18),
              label: Text(ar ? 'سجل الطلبات' : 'Request history'),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxWidth >=
                    950 * (MediaQuery.textScalerOf(context).scale(14) / 14)
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: steps),
                      const SizedBox(width: 18),
                      Expanded(flex: 3, child: content),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [content, const SizedBox(height: 18), steps],
                  ),
          ),
        ],
      );
    },
  );
}

class _RequestPanel extends StatelessWidget {
  const _RequestPanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surface
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: .4),
      ),
    ),
    child: child,
  );
}
