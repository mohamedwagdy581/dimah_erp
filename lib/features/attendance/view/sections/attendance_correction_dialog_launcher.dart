import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/attendance_record.dart';
import '../cubit/attendance_cubit.dart';
import '../widgets/attendance_correction_dialog.dart';

Future<void> openAttendanceCorrectionDialog(
  BuildContext context,
  AttendanceRecord record,
) async {
  final cubit = context.read<AttendanceCubit>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: AttendanceCorrectionDialog(record: record),
    ),
  );
  if (ok == true && context.mounted) {
    cubit.load();
  }
}
