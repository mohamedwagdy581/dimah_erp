import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/leave_request.dart';
import '../cubit/leaves_cubit.dart';
import '../cubit/leaves_state.dart';
import '../widgets/leaves_form_dialog.dart';
import '../widgets/leaves_pagination_bar.dart';
import '../widgets/leaves_table.dart';

class LeavesTableSection extends StatelessWidget {
  const LeavesTableSection({super.key, this.employeeId});

  final String? employeeId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeavesCubit, LeavesState>(
      builder: (context, state) {
        final cubit = context.read<LeavesCubit>();
        final t = AppLocalizations.of(context)!;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(cubit: cubit, state: state, employeeId: employeeId),
              if (state.balances.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: state.balances.map((b) {
                    return _BalanceCard(
                      title: b.type.toUpperCase(),
                      entitlement: b.entitlement,
                      used: b.used,
                      remaining: b.remaining,
                      t: t,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: LeavesTable(
                  items: state.items,
                  onResubmit: employeeId == null
                      ? null
                      : (leave) => _openResubmitDialog(context, leave),
                ),
              ),
              const SizedBox(height: 12),
              LeavesPaginationBar(
                page: state.page,
                totalPages: state.totalPages,
                total: state.total,
                canPrev: state.canPrev,
                canNext: state.canNext,
                onPrev: cubit.prevPage,
                onNext: cubit.nextPage,
                pageSize: state.pageSize,
                onPageSizeChanged: cubit.setPageSize,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.title,
    required this.entitlement,
    required this.used,
    required this.remaining,
    required this.t,
  });

  final String title;
  final double entitlement;
  final double used;
  final double remaining;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final ok = remaining >= 0;
    return Container(
      width: 210,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(t.entitlementWithValue(entitlement.toStringAsFixed(0))),
          Text(t.usedWithValue(used.toStringAsFixed(0))),
          Text(
            t.remainingWithValue(remaining.toStringAsFixed(0)),
            style: TextStyle(
              color: ok ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.cubit,
    required this.state,
    required this.employeeId,
  });

  final LeavesCubit cubit;
  final LeavesState state;
  final String? employeeId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.menuLeaves,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                onChanged: cubit.searchChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: t.searchEmployeeHint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            DropdownButton<String?>(
              value: state.status,
              onChanged: (v) => cubit.statusFilterChanged(v),
              items: [
                DropdownMenuItem(value: null, child: Text(t.all)),
                DropdownMenuItem(value: 'pending', child: Text(t.statusPending)),
                DropdownMenuItem(value: 'approved', child: Text(t.statusApproved)),
                DropdownMenuItem(value: 'rejected', child: Text(t.statusRejected)),
              ],
            ),
            DropdownButton<String?>(
              value: state.type,
              onChanged: (v) => cubit.typeFilterChanged(v),
              items: [
                DropdownMenuItem(value: null, child: Text(t.allTypes)),
                DropdownMenuItem(value: 'annual', child: Text(t.leaveTypeAnnual)),
                DropdownMenuItem(value: 'sick', child: Text(t.leaveTypeSick)),
                DropdownMenuItem(value: 'unpaid', child: Text(t.leaveTypeUnpaid)),
                DropdownMenuItem(value: 'other', child: Text(t.leaveTypeOther)),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.startDate ?? now,
                  firstDate: DateTime(now.year - 1, 1, 1),
                  lastDate: DateTime(now.year + 2, 12, 31),
                );
                if (picked != null) {
                  cubit.startDateChanged(picked);
                }
              },
              icon: const Icon(Icons.event),
              label: Text(
                state.startDate == null
                    ? t.startFrom
                    : '${state.startDate!.year.toString().padLeft(4, '0')}-'
                        '${state.startDate!.month.toString().padLeft(2, '0')}-'
                        '${state.startDate!.day.toString().padLeft(2, '0')}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.endDate ?? now,
                  firstDate: DateTime(now.year - 1, 1, 1),
                  lastDate: DateTime(now.year + 2, 12, 31),
                );
                if (picked != null) {
                  cubit.endDateChanged(picked);
                }
              },
              icon: const Icon(Icons.event_available),
              label: Text(
                state.endDate == null
                    ? t.endTo
                    : '${state.endDate!.year.toString().padLeft(4, '0')}-'
                        '${state.endDate!.month.toString().padLeft(2, '0')}-'
                        '${state.endDate!.day.toString().padLeft(2, '0')}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => cubit.toggleSort('start_date'),
              icon: const Icon(Icons.schedule),
              label: Text(
                state.sortBy == 'start_date'
                    ? (state.ascending ? t.startAsc : t.startDesc)
                    : t.sortStart,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: context.read<LeavesCubit>(),
                    child: LeavesFormDialog(employeeId: employeeId),
                  ),
                );
                if (ok == true && context.mounted) {
                  cubit.load(resetPage: true);
                }
              },
              icon: const Icon(Icons.add),
              label: Text(t.addLeave),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _openResubmitDialog(
  BuildContext context,
  LeaveRequest leave,
) async {
  final cubit = context.read<LeavesCubit>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: LeavesFormDialog(
        employeeId: leave.employeeId,
        initialLeave: leave,
      ),
    ),
  );
  if (ok == true && context.mounted) {
    cubit.load(resetPage: true);
  }
}
