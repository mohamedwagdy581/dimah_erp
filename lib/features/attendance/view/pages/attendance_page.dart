import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../cubit/attendance_cubit.dart';
import '../sections/attendance_table_section.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AttendanceCubit(AppDI.attendanceRepo)..load(),
      child: const AttendanceTableSection(),
    );
  }
}
