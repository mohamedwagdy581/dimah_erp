import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';
import '../widgets/attendance_correction_dialog.dart';
import '../widgets/attendance_form_dialog.dart';
import '../widgets/attendance_import_dialog.dart';
import '../widgets/attendance_pagination_bar.dart';
import '../widgets/attendance_table.dart';

class AttendanceTableSection extends StatelessWidget {
  const AttendanceTableSection({super.key, this.showCreate = true});

  final bool showCreate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        final cubit = context.read<AttendanceCubit>();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(cubit: cubit, state: state, showCreate: showCreate),
              const SizedBox(height: 12),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: AttendanceTable(
                  items: state.items,
                  onRequestCorrection: (record) async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => BlocProvider.value(
                        value: context.read<AttendanceCubit>(),
                        child: AttendanceCorrectionDialog(record: record),
                      ),
                    );
                    if (ok == true && context.mounted) {
                      cubit.load();
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              AttendancePaginationBar(
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

class _Header extends StatelessWidget {
  const _Header({
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
                DropdownMenuItem(value: 'present', child: Text(t.attendancePresent)),
                DropdownMenuItem(value: 'late', child: Text(t.attendanceLate)),
                DropdownMenuItem(value: 'absent', child: Text(t.attendanceAbsent)),
                DropdownMenuItem(value: 'on_leave', child: Text(t.attendanceOnLeave)),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () async {
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
              },
              icon: const Icon(Icons.event),
              label: Text(
                state.date == null
                    ? t.filterDate
                    : '${state.date!.year.toString().padLeft(4, '0')}-'
                        '${state.date!.month.toString().padLeft(2, '0')}-'
                        '${state.date!.day.toString().padLeft(2, '0')}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => cubit.toggleSort('date'),
              icon: const Icon(Icons.schedule),
              label: Text(
                state.sortBy == 'date'
                    ? (state.ascending ? t.dateAsc : t.dateDesc)
                    : t.sortDate,
              ),
            ),
            if (showCreate)
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => BlocProvider.value(
                      value: context.read<AttendanceCubit>(),
                      child: const AttendanceImportDialog(),
                    ),
                  );
                  if (ok == true && context.mounted) {
                    cubit.load(resetPage: true);
                  }
                },
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(t.importCsv),
              ),
            if (showCreate)
              ElevatedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => BlocProvider.value(
                      value: context.read<AttendanceCubit>(),
                      child: const AttendanceFormDialog(),
                    ),
                  );
                  if (ok == true && context.mounted) {
                    cubit.load(resetPage: true);
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(t.addAttendance),
              ),
          ],
        ),
      ],
    );
  }
}
