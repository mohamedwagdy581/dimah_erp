import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/ui/app_data_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../payroll/view/widgets/payroll_pagination_bar.dart';
import '../cubit/leaves_cubit.dart';
import '../cubit/leaves_state.dart';
import '../sections/leaves_create_action.dart';
import '../sections/leaves_filters.dart';
import 'leaves_table.dart';

class AdminLeavesWorkspace extends StatelessWidget {
  const AdminLeavesWorkspace({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<LeavesCubit, LeavesState>(
    builder: (context, state) {
      final cubit = context.read<LeavesCubit>();
      final t = AppLocalizations.of(context)!;
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      final filtered =
          state.search.trim().isNotEmpty ||
          state.status != null ||
          state.type != null ||
          state.startDate != null ||
          state.endDate != null;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5DDF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, box) {
                  final heading = Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1E6FC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.event_note_rounded,
                          color: Color(0xFF8659BB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.menuLeaves,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF21194E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ar
                                  ? 'متابعة إجازات الموظفين وحالة طلباتهم'
                                  : 'Track employee leave and request status',
                              style: const TextStyle(
                                color: Color(0xFF77709A),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                  final actions = Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      LeavesCreateAction(cubit: cubit, employeeId: null),
                      IconButton.outlined(
                        tooltip: ar ? 'تحديث' : 'Refresh',
                        onPressed: state.loading ? null : cubit.load,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  );
                  if (box.maxWidth < 650) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [heading, const SizedBox(height: 16), actions],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: heading),
                      const SizedBox(width: 16),
                      actions,
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFAFF),
                  border: Border.all(color: const Color(0xFFE5DDF2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    LeavesSearchField(cubit: cubit),
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: state.status ?? 'all',
                        key: ValueKey('leave-status-${state.status}'),
                        decoration: InputDecoration(labelText: t.status),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text(t.all)),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text(t.statusPending),
                          ),
                          DropdownMenuItem(
                            value: 'approved',
                            child: Text(t.statusApproved),
                          ),
                          DropdownMenuItem(
                            value: 'rejected',
                            child: Text(t.statusRejected),
                          ),
                        ],
                        onChanged: state.loading
                            ? null
                            : (value) => cubit.statusFilterChanged(
                                value == 'all' ? null : value,
                              ),
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: state.type ?? 'all',
                        key: ValueKey('leave-type-${state.type}'),
                        decoration: InputDecoration(labelText: t.type),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(t.allTypes),
                          ),
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
                        onChanged: state.loading
                            ? null
                            : (value) => cubit.typeFilterChanged(
                                value == 'all' ? null : value,
                              ),
                      ),
                    ),
                    LeavesDateFilterButton(
                      value: state.startDate,
                      emptyLabel: t.startFrom,
                      icon: Icons.calendar_today_outlined,
                      onPicked: cubit.startDateChanged,
                    ),
                    LeavesDateFilterButton(
                      value: state.endDate,
                      emptyLabel: t.endTo,
                      icon: Icons.calendar_month_outlined,
                      onPicked: cubit.endDateChanged,
                    ),
                    OutlinedButton.icon(
                      onPressed: state.loading
                          ? null
                          : () => cubit.toggleSort('start_date'),
                      icon: const Icon(Icons.schedule, size: 18),
                      label: Text(state.ascending ? t.startAsc : t.startDesc),
                    ),
                    TextButton.icon(
                      onPressed: state.loading ? null : cubit.resetFilters,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: Text(ar ? 'مسح الفلاتر' : 'Clear filters'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const ValueKey('leave-open-approvals'),
                  onPressed: () => context.go('/approvals'),
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: Text(
                    ar
                        ? 'مراجعة واعتماد الطلبات من شاشة الموافقات'
                        : 'Review and approve requests in Approvals',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 460,
                child: AppDataRegion(
                  loading: state.loading,
                  error: state.error,
                  empty: state.items.isEmpty,
                  filtered: filtered,
                  onClear: cubit.resetFilters,
                  onRetry: cubit.load,
                  child: LeavesTable(items: state.items, managementStyle: true),
                ),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: Color(0xFFE5DDF2)),
              const SizedBox(height: 14),
              PayrollPaginationBar(
                page: state.page,
                totalPages: state.totalPages,
                total: state.total,
                canPrev: !state.loading && state.canPrev,
                canNext: !state.loading && state.canNext,
                onPrev: cubit.prevPage,
                onNext: cubit.nextPage,
                pageSize: state.pageSize,
                onPageSizeChanged: cubit.setPageSize,
              ),
            ],
          ),
        ),
      );
    },
  );
}
