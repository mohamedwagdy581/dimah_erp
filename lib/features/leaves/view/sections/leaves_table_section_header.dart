import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/leaves_cubit.dart';
import '../cubit/leaves_state.dart';
import 'leaves_create_action.dart';
import 'leaves_filters.dart';

class LeavesTableSectionHeader extends StatelessWidget {
  const LeavesTableSectionHeader({
    super.key,
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
            LeavesSearchField(cubit: cubit),
            LeavesStatusFilter(cubit: cubit, state: state),
            LeavesTypeFilter(cubit: cubit, state: state),
            LeavesDateFilterButton(
              value: state.startDate,
              emptyLabel: t.startFrom,
              icon: Icons.event,
              onPicked: cubit.startDateChanged,
            ),
            LeavesDateFilterButton(
              value: state.endDate,
              emptyLabel: t.endTo,
              icon: Icons.event_available,
              onPicked: cubit.endDateChanged,
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
            LeavesCreateAction(
              cubit: cubit,
              employeeId: employeeId,
            ),
          ],
        ),
      ],
    );
  }
}
