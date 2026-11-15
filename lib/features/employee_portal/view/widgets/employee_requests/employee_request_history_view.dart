import 'package:flutter/material.dart';
import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../approvals/domain/models/approval_request.dart';
import '../../cubit/employee_request_history_cubit.dart';
import 'request_history_details.dart';
import 'request_history_labels.dart';
import 'employee_leave_balances.dart';

class EmployeeRequestHistoryView extends StatefulWidget {
  const EmployeeRequestHistoryView({
    super.key,
    required this.onLeave,
    required this.onAttendance,
    required this.onResubmit,
    required this.onAttachment,
    this.showBalanceSummary = false,
  });
  final VoidCallback onLeave;
  final VoidCallback onAttendance;
  final Future<void> Function(ApprovalRequest) onResubmit;
  final ValueChanged<String> onAttachment;
  final bool showBalanceSummary;
  @override
  State<EmployeeRequestHistoryView> createState() =>
      _EmployeeRequestHistoryViewState();
}

class _EmployeeRequestHistoryViewState
    extends State<EmployeeRequestHistoryView> {
  final _search = TextEditingController();
  final _detailsKey = GlobalKey();
  String _type = 'all';
  String _status = 'all';
  String? _selectedId;
  int _page = 0;
  bool _busy = false;
  static const _pageSize = 10;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _resubmit(ApprovalRequest request) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onResubmit(request);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تعذّر إعادة تقديم الطلب؛ حاول مجددًا'
                  : 'Unable to resubmit. Try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<EmployeeRequestHistoryCubit, EmployeeRequestHistoryState>(
    builder: (context, state) {
      final t = AppLocalizations.of(context)!;
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      final cs = Theme.of(context).colorScheme;
      final query = _search.text.trim().toLowerCase();
      final filtered = state.items
          .where(
            (r) =>
                (_type == 'all' || r.requestType == _type) &&
                (_status == 'all' || r.status == _status) &&
                (query.isEmpty ||
                    '${r.id} ${historyType(t, r.requestType, ar)} ${r.payload?.values.join(' ')} ${r.rejectReason ?? ''} ${historyStatus(t, r.status)}'
                        .toLowerCase()
                        .contains(query)),
          )
          .toList();
      final pages = (filtered.length / _pageSize).ceil().clamp(1, 1000000);
      final page = _page.clamp(0, pages - 1);
      final visible = filtered.skip(page * _pageSize).take(_pageSize).toList();
      final selected =
          filtered.where((r) => r.id == _selectedId).firstOrNull ??
          visible.firstOrNull;
      final history = context.read<EmployeeRequestHistoryCubit>();
      InputDecoration input(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? cs.surfaceContainerLow
            : const Color(0xFFF7F8FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: .5),
          ),
        ),
      );
      final search = TextField(
        key: const ValueKey('request-history-search'),
        controller: _search,
        onChanged: (_) => setState(() => _page = 0),
        decoration: input(
          ar ? 'البحث في طلباتي…' : 'Search my requests…',
        ).copyWith(prefixIcon: const Icon(Icons.search)),
      );
      final type = DropdownButtonFormField<String>(
        key: ValueKey('history-type-$_type'),
        initialValue: _type,
        isExpanded: true,
        decoration: input(ar ? 'نوع الطلب' : 'Request type'),
        items: [
          DropdownMenuItem(value: 'all', child: Text(t.all)),
          for (final value in {
            'leave',
            'attendance_correction',
            ...state.items.map((r) => r.requestType),
          })
            DropdownMenuItem(
              value: value,
              child: Text(historyType(t, value, ar)),
            ),
        ],
        onChanged: (value) => setState(() {
          _type = value ?? 'all';
          _page = 0;
        }),
      );
      final status = DropdownButtonFormField<String>(
        key: ValueKey('history-status-$_status'),
        initialValue: _status,
        isExpanded: true,
        decoration: input(t.status),
        items: [
          DropdownMenuItem(value: 'all', child: Text(t.all)),
          for (final value in ['pending', 'approved', 'rejected'])
            DropdownMenuItem(
              value: value,
              child: Text(historyStatus(t, value)),
            ),
        ],
        onChanged: (value) => setState(() {
          _status = value ?? 'all';
          _page = 0;
        }),
      );
      final reset = TextButton.icon(
        onPressed: () => setState(() {
          _search.clear();
          _status = 'all';
          _type = 'all';
          _page = 0;
        }),
        icon: const Icon(Icons.refresh, size: 18),
        label: Text(ar ? 'إعادة تعيين' : 'Reset'),
      );
      final list = HistoryPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  key: const ValueKey('employee-request-back-to-form'),
                  onPressed: _busy ? null : widget.onLeave,
                  icon: const Icon(Icons.add),
                  label: Text(t.addLeave),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : widget.onAttendance,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(ar ? 'طلب تصحيح حضور' : 'Attendance correction'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: state.loading ? null : history.load,
                  tooltip: t.refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth >= 750
                  ? Row(
                      children: [
                        Expanded(flex: 3, child: search),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: type),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: status),
                        reset,
                      ],
                    )
                  : Column(
                      children: [
                        search,
                        const SizedBox(height: 16),
                        type,
                        const SizedBox(height: 16),
                        status,
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: reset,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 22),
            if (state.loading) const AppLoadingState(),
            if (state.error != null)
              AppFailureState(error: state.error, onRetry: history.load)
            else if (!state.loading && filtered.isEmpty)
              AppEmptyState(
                filtered:
                    _search.text.trim().isNotEmpty ||
                    _status != 'all' ||
                    _type != 'all',
                onClear:
                    _search.text.trim().isNotEmpty ||
                        _status != 'all' ||
                        _type != 'all'
                    ? () => setState(() {
                        _search.clear();
                        _status = 'all';
                        _type = 'all';
                        _page = 0;
                      })
                    : null,
              ),
            if (!state.loading && state.error == null && filtered.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide =
                      constraints.maxWidth >=
                      700 * (MediaQuery.textScalerOf(context).scale(14) / 14);
                  final headers = [
                    '#',
                    ar ? 'نوع الطلب' : 'Request type',
                    ar ? 'تاريخ التقديم' : 'Submitted',
                    ar ? 'الفترة / تاريخ الحضور' : 'Period / attendance date',
                    t.status,
                    ar ? 'الإجراءات' : 'Actions',
                  ];
                  Widget cell(int index, Widget child) => Expanded(
                    flex: index == 0
                        ? 1
                        : index == 3
                        ? 4
                        : 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Align(alignment: Alignment.center, child: child),
                    ),
                  );
                  Widget badge(ApprovalRequest r) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: historyStatusColor(
                        r.status,
                      ).withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          historyStatusIcon(r.status),
                          size: 18,
                          color: historyStatusColor(r.status),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            historyStatus(t, r.status),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: historyStatusColor(r.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  return Column(
                    children: [
                      if (wide)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              for (var i = 0; i < headers.length; i++)
                                cell(
                                  i,
                                  Text(
                                    headers[i],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      for (var i = 0; i < visible.length; i++)
                        Builder(
                          builder: (context) {
                            final r = visible[i];
                            final button = OutlinedButton.icon(
                              key: ValueKey('history-details-${r.id}'),
                              onPressed: () {
                                setState(() => _selectedId = r.id);
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  final detailsContext =
                                      _detailsKey.currentContext;
                                  if (detailsContext != null) {
                                    Scrollable.ensureVisible(
                                      detailsContext,
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                    );
                                  }
                                });
                              },
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: Text(
                                ar ? 'عرض التفاصيل' : 'View details',
                                style: const TextStyle(fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: cs.primary.withValues(alpha: .6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                            final typeColor =
                                r.requestType == 'attendance_correction'
                                ? const Color(0xFF1677FF)
                                : cs.primary;
                            final typeLabel = Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    r.requestType == 'attendance_correction'
                                        ? Icons.schedule
                                        : Icons.calendar_month,
                                    size: 18,
                                    color: typeColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      historyType(t, r.requestType, ar),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: typeColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            final date = Text(
                              '${historyDate(r.createdAt)}\n${historyTime(r.createdAt)}',
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, height: 1.6),
                            );
                            final period = Text(
                              historyPeriod(r),
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, height: 1.6),
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: selected?.id == r.id
                                    ? cs.primary.withValues(alpha: .06)
                                    : Colors.transparent,
                                border: Border(
                                  bottom: BorderSide(
                                    color: cs.outlineVariant.withValues(
                                      alpha: .3,
                                    ),
                                  ),
                                ),
                              ),
                              child: wide
                                  ? Row(
                                      children: [
                                        cell(
                                          0,
                                          Text('${page * _pageSize + i + 1}'),
                                        ),
                                        cell(1, typeLabel),
                                        cell(2, date),
                                        cell(3, period),
                                        cell(4, badge(r)),
                                        cell(5, button),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: typeLabel),
                                            const SizedBox(width: 8),
                                            Flexible(child: badge(r)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        date,
                                        const SizedBox(height: 10),
                                        period,
                                        const SizedBox(height: 14),
                                        button,
                                      ],
                                    ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              textDirection: TextDirection.ltr,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                IconButton(
                  tooltip: ar ? 'الصفحة السابقة' : 'Previous page',
                  onPressed: page > 0
                      ? () => setState(() => _page = page - 1)
                      : null,
                  icon: const Icon(
                    Icons.chevron_left,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                Text(
                  '${page + 1} / $pages • ${filtered.length}',
                  style: const TextStyle(fontSize: 14),
                ),
                IconButton(
                  tooltip: ar ? 'الصفحة التالية' : 'Next page',
                  onPressed: page + 1 < pages
                      ? () => setState(() => _page = page + 1)
                      : null,
                  icon: const Icon(
                    Icons.chevron_right,
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      final details = KeyedSubtree(
        key: _detailsKey,
        child: selected == null
            ? HistoryPanel(
                child: Text(
                  ar
                      ? 'اختر طلبًا لعرض تفاصيله'
                      : 'Select a request to view details',
                  textAlign: TextAlign.center,
                ),
              )
            : RequestHistoryDetails(
                request: selected,
                busy: _busy,
                onResubmit: () => _resubmit(selected),
                onAttachment: widget.onAttachment,
              ),
      );
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.showBalanceSummary) ...[
            const EmployeeLeaveBalances(),
            const SizedBox(height: 22),
          ],
          Text(
            t.myRequests,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            ar
                ? 'متابعة طلبات الإجازة وتصحيح الحضور'
                : 'Track leave and attendance correction requests',
            style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxWidth >=
                    1150 * (MediaQuery.textScalerOf(context).scale(14) / 14)
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: details),
                      const SizedBox(width: 18),
                      Expanded(flex: 4, child: list),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [list, const SizedBox(height: 18), details],
                  ),
          ),
        ],
      );
    },
  );
}
