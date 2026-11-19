import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/approvals_cubit.dart';
import '../cubit/approvals_state.dart';

class ApprovalsTableSectionHeader extends StatelessWidget {
  const ApprovalsTableSectionHeader({
    super.key,
    required this.cubit,
    required this.state,
  });

  final ApprovalsCubit cubit;
  final ApprovalsState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0E5FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                size: 24,
                color: Color(0xFF8659BB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.menuApprovals,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF242052),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'مراجعة الطلبات ومتابعة قرارات الاعتماد'
                        : 'Review requests and track approval decisions',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF777194),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: state.loading ? null : cubit.load,
              tooltip: t.refresh,
              icon: const Icon(Icons.refresh, color: Color(0xFF8659BB)),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFAFF),
            border: Border.all(color: const Color(0xFFE5DDF2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('approval-status-${state.status}'),
                  decoration: InputDecoration(
                    labelText: t.status,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  isExpanded: true,
                  initialValue: state.status,
                  onChanged: cubit.statusFilterChanged,
                  items: [
                    DropdownMenuItem(value: null, child: Text(t.all)),
                    DropdownMenuItem(
                      value: 'pending_assigned',
                      child: Text(t.assignedToMe),
                    ),
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
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('approval-type-${state.requestType}'),
                  decoration: InputDecoration(
                    labelText: t.type,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  isExpanded: true,
                  initialValue: state.requestType,
                  onChanged: cubit.typeFilterChanged,
                  items: [
                    DropdownMenuItem(value: null, child: Text(t.allTypes)),
                    DropdownMenuItem(value: 'leave', child: Text(t.leave)),
                    DropdownMenuItem(
                      value: 'early_exit',
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'إذن خروج مبكر'
                            : 'Early Exit Permission',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'attendance_correction',
                      child: Text(t.menuAttendance),
                    ),
                    DropdownMenuItem(
                      value: 'payroll_run',
                      child: Text(t.menuPayroll),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => cubit.toggleSort('created_at'),
                icon: const Icon(Icons.schedule),
                label: Text(
                  state.sortBy == 'created_at'
                      ? (state.ascending ? t.createdAsc : t.createdDesc)
                      : t.sortCreated,
                ),
              ),
              TextButton.icon(
                onPressed: state.loading ? null : cubit.resetFilters,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'مسح الفلاتر'
                      : 'Clear filters',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
