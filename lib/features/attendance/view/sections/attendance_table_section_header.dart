import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';
import 'attendance_create_actions.dart';

class AttendanceTableSectionHeader extends StatelessWidget {
  const AttendanceTableSectionHeader({
    super.key,
    required this.cubit,
    required this.state,
    required this.showCreate,
  });

  final AttendanceCubit cubit;
  final AttendanceState state;
  final bool showCreate;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.menuAttendance,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _AttendanceSearchField(cubit: cubit),
            _AttendanceStatusFilter(cubit: cubit, state: state),
            _AttendanceDateFilterButton(cubit: cubit, state: state),
            OutlinedButton.icon(
              onPressed: () => cubit.toggleSort('date'),
              icon: const Icon(Icons.schedule),
              label: Text(
                state.sortBy == 'date'
                    ? (state.ascending ? t.dateAsc : t.dateDesc)
                    : t.sortDate,
              ),
            ),
            if (showCreate) ImportAttendanceButton(cubit: cubit),
            if (showCreate) AddAttendanceButton(cubit: cubit),
          ],
        ),
      ],
    );
  }
}

class _AttendanceSearchField extends StatelessWidget {
  const _AttendanceSearchField({required this.cubit});

  final AttendanceCubit cubit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SizedBox(
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
    );
  }
}

class _AttendanceStatusFilter extends StatelessWidget {
  const _AttendanceStatusFilter({
    required this.cubit,
    required this.state,
  });

  final AttendanceCubit cubit;
  final AttendanceState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return DropdownButton<String?>(
      value: state.status,
      onChanged: cubit.statusFilterChanged,
      items: [
        DropdownMenuItem(value: null, child: Text(t.all)),
        DropdownMenuItem(value: 'present', child: Text(t.attendancePresent)),
        DropdownMenuItem(value: 'late', child: Text(t.attendanceLate)),
        DropdownMenuItem(value: 'absent', child: Text(t.attendanceAbsent)),
        DropdownMenuItem(value: 'on_leave', child: Text(t.attendanceOnLeave)),
      ],
    );
  }
}

class _AttendanceDateFilterButton extends StatelessWidget {
  const _AttendanceDateFilterButton({
    required this.cubit,
    required this.state,
  });

  final AttendanceCubit cubit;
  final AttendanceState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: () => _pickDate(context),
      icon: const Icon(Icons.event),
      label: Text(
        state.date == null ? t.filterDate : _formatDate(state.date!),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.date ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked != null) {
      cubit.dateFilterChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
