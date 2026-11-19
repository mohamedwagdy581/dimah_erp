import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/app_di.dart';
import '../../../core/session/session_cubit.dart';
import '../../../core/ui/employee_theme.dart';
import '../../approvals/domain/models/approval_request.dart';
import '../../employee_portal/view/widgets/employee_requests/request_history_labels.dart';
import '../../../l10n/app_localizations.dart';
import '../data/manager_requests_repo.dart';
import 'manager_requests_cubit.dart';

part 'manager_requests_details.dart';

class ManagerRequestsPage extends StatelessWidget {
  const ManagerRequestsPage({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<SessionCubit, SessionState>(
    builder: (context, session) {
      if (session is! SessionReady) {
        return const AppLoadingState();
      }
      if (!['manager', 'direct_manager'].contains(session.user.role)) {
        return const SizedBox.shrink();
      }
      return BlocProvider(
        create: (_) => ManagerRequestsCubit(
          SupabaseManagerRequestsRepo(
            Supabase.instance.client,
            AppDI.approvalsRepo,
          ),
        )..load(),
        child: const ManagerRequestsView(),
      );
    },
  );
}

class ManagerRequestsView extends StatefulWidget {
  const ManagerRequestsView({super.key});
  @override
  State<ManagerRequestsView> createState() => _ManagerRequestsViewState();
}

class _ManagerRequestsViewState extends State<ManagerRequestsView> {
  String _type = 'all', _status = 'all', _search = '';
  String? _selected;
  final _reason = TextEditingController();
  bool _reasonRequired = false;
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => ar ? a : e;
  void _filter(VoidCallback change) => setState(() {
    change();
    _selected = null;
    _reason.clear();
    _reasonRequired = false;
  });
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Widget panel(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: EmployeeTheme.primary.withValues(alpha: .15)),
    ),
    child: child,
  );

  Widget statusBadge(ApprovalRequest request) {
    final color = historyStatusColor(request.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        historyStatus(AppLocalizations.of(context)!, request.status),
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> decide(Map<String, dynamic> row, bool approve) async {
    if (!approve && _reason.text.trim().isEmpty) {
      setState(() => _reasonRequired = true);
      return;
    }
    final ok = await context.read<ManagerRequestsCubit>().decide(
      '${row['id']}',
      approve,
      _reason.text.trim(),
    );
    if (!mounted || !ok) return;
    setState(() {
      _reason.clear();
      _reasonRequired = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approve
              ? tr(
                  'تمت الموافقة وإحالة الطلب للموارد البشرية',
                  'Approved and forwarded to HR',
                )
              : tr('تم رفض الطلب', 'Request rejected'),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ManagerRequestsCubit, ManagerRequestsState>(
    builder: (context, state) {
      final busy = state.saving || state.loading;
      final t = AppLocalizations.of(context)!;
      if (state.loading && state.data.rows.isEmpty) {
        return const AppLoadingState();
      }
      final visible = state.data.rows.where((row) {
        final r = ApprovalRequest.fromMap(row);
        return (_type == 'all' || r.requestType == _type) &&
            (_status == 'all' ||
                (_status == 'assigned'
                    ? managerCanDecideRequest(row, state.data.role)
                    : r.status == _status)) &&
            '${r.employeeName} ${historyType(t, r.requestType, ar)} ${r.id} ${r.payload?['notes'] ?? r.payload?['reason'] ?? ''}'
                .toLowerCase()
                .contains(_search.toLowerCase().trim());
      }).toList();
      final selected =
          visible.where((r) => r['id'].toString() == _selected).firstOrNull ??
          visible.firstOrNull;
      final list = panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${tr('الطلبات الواردة', 'Incoming requests')} (${visible.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final item in [
                  ('all', tr('الكل', 'All')),
                  ('leave', tr('إجازات', 'Leave')),
                  ('attendance_correction', tr('تصحيح حضور', 'Attendance')),
                ]) ...[
                  if (item.$1 != 'all') const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          item.$2,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      selected: _type == item.$1,
                      showCheckmark: false,
                      selectedColor: EmployeeTheme.primary,
                      labelStyle: TextStyle(
                        color: _type == item.$1
                            ? Colors.white
                            : EmployeeTheme.dark,
                      ),
                      onSelected: busy
                          ? null
                          : (_) => _filter(() => _type = item.$1),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: !busy,
              onChanged: (v) => _filter(() => _search = v),
              decoration: InputDecoration(
                hintText: tr('ابحث في الطلبات…', 'Search requests…'),
                prefixIcon: const Icon(Icons.search, size: 21),
                filled: true,
                fillColor: EmployeeTheme.primary.withValues(alpha: .05),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _status,
              decoration: InputDecoration(
                labelText: tr('الحالة', 'Status'),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: EmployeeTheme.primary.withValues(alpha: .22),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: EmployeeTheme.primary.withValues(alpha: .22),
                  ),
                ),
              ),
              items: [
                for (final entry in [
                  ('all', tr('كل الحالات', 'All statuses')),
                  ('assigned', tr('بانتظار قراري', 'Awaiting my decision')),
                  ('pending', tr('معلقة', 'Pending')),
                  ('approved', tr('معتمدة', 'Approved')),
                  ('rejected', tr('مرفوضة', 'Rejected')),
                ])
                  DropdownMenuItem(value: entry.$1, child: Text(entry.$2)),
              ],
              onChanged: busy ? null : (v) => _filter(() => _status = v!),
            ),
            const SizedBox(height: 16),
            if (MediaQuery.sizeOf(context).width >= 600)
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      tr('الموظف', 'Employee'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      tr('نوع الطلب', 'Type'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      tr('الفترة', 'Period'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      tr('الحالة', 'Status'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  tr('لا توجد طلبات مطابقة', 'No matching requests'),
                  textAlign: TextAlign.center,
                ),
              ),
            for (final row in visible) _requestRow(row, selected == row, busy),
          ],
        ),
      );
      final details = selected == null
          ? panel(
              Padding(
                padding: const EdgeInsets.all(30),
                child: Text(
                  tr(
                    'اختر طلبًا لعرض التفاصيل',
                    'Select a request to view details',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _details(selected, state);
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_rounded,
                color: EmployeeTheme.primary,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr('طلبات الفريق', 'Team requests'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: tr('تحديث', 'Refresh'),
                onPressed: busy
                    ? null
                    : () {
                        _filter(() {});
                        context.read<ManagerRequestsCubit>().load();
                      },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.saving) const LinearProgressIndicator(),
          if (state.loading) const AppLoadingState(),
          if (state.failed)
            AppFailureState(
              error: state.error,
              onRetry: context.read<ManagerRequestsCubit>().load,
            ),
          if (state.saveFailed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                state.saveFailed
                    ? tr(
                        'تعذر حفظ القرار. حدّث الطلبات ثم حاول مرة أخرى.',
                        'Could not save decision. Refresh and try again.',
                      )
                    : tr(
                        'تعذر تحديث الطلبات. اضغط تحديث لإعادة المحاولة.',
                        'Could not refresh requests. Please retry.',
                      ),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (!state.loading && !state.failed)
            LayoutBuilder(
              builder: (_, box) => box.maxWidth < 1000
                  ? Column(
                      children: [list, const SizedBox(height: 16), details],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: list),
                        const SizedBox(width: 16),
                        Expanded(flex: 6, child: details),
                      ],
                    ),
            ),
        ],
      );
    },
  );

  Widget _requestRow(Map<String, dynamic> row, bool selected, bool busy) {
    final r = ApprovalRequest.fromMap(row);
    return Material(
      color: selected
          ? EmployeeTheme.primary.withValues(alpha: .09)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        key: ValueKey('team-request-${r.id}'),
        borderRadius: BorderRadius.circular(7),
        onTap: busy
            ? null
            : () => setState(() {
                _selected = r.id;
                _reason.clear();
                _reasonRequired = false;
              }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: EmployeeTheme.primary.withValues(alpha: .10),
              ),
            ),
          ),
          child: MediaQuery.sizeOf(context).width < 600
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.employeeName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        statusBadge(r),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      historyType(
                        AppLocalizations.of(context)!,
                        r.requestType,
                        ar,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: EmployeeTheme.dark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _period(r),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: EmployeeTheme.primary.withValues(
                              alpha: .16,
                            ),
                            child: Text(
                              r.employeeName
                                  .split(' ')
                                  .where((s) => s.isNotEmpty)
                                  .take(2)
                                  .map((s) => s.characters.first)
                                  .join(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: EmployeeTheme.dark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              r.employeeName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        historyType(
                          AppLocalizations.of(context)!,
                          r.requestType,
                          ar,
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        _period(r),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                    Expanded(flex: 2, child: Center(child: statusBadge(r))),
                  ],
                ),
        ),
      ),
    );
  }

  String _period(ApprovalRequest r) {
    if (r.requestType != 'attendance_correction') return historyPeriod(r);
    final p = r.payload ?? {};
    String clock(dynamic raw) {
      final d = DateTime.tryParse('$raw')?.toLocal();
      return d == null ? '—' : historyTime(d);
    }

    return '${historyDate(p['date'])}\n${clock(p['proposed_check_in'])} – ${clock(p['proposed_check_out'])}';
  }
}
