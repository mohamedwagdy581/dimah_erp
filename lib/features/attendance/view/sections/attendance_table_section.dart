import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';
import '../widgets/attendance_pagination_bar.dart';
import '../widgets/attendance_table.dart';
import 'attendance_correction_dialog_launcher.dart';
import 'attendance_table_section_header.dart';

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
              AttendanceTableSectionHeader(
                cubit: cubit,
                state: state,
                showCreate: showCreate,
              ),
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
                  onRequestCorrection: (record) =>
                      openAttendanceCorrectionDialog(context, record),
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
