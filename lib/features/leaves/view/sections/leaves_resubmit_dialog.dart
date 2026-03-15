import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/leave_request.dart';
import '../cubit/leaves_cubit.dart';
import '../widgets/leaves_form_dialog.dart';

Future<void> openLeaveResubmitDialog(
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
