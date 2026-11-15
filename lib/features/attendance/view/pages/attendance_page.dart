import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/session/session_cubit.dart';
import '../cubit/attendance_cubit.dart';
import '../sections/attendance_table_section.dart';
import 'hr_attendance_page.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AttendanceCubit(AppDI.attendanceRepo)..load(),
      child: Builder(
        builder: (context) {
          final session = context.watch<SessionCubit>().state;
          return session is SessionReady &&
                  ['hr', 'admin'].contains(session.user.role)
              ? const HrAttendancePage()
              : const AttendanceTableSection();
        },
      ),
    );
  }
}
