import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/app_di.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../approvals/view/cubit/approvals_cubit.dart';
import '../../../../approvals/view/sections/approvals_table_section.dart';
import '../../../../attendance/view/cubit/attendance_cubit.dart';
import '../../../../attendance/view/sections/attendance_table_section.dart';
import '../../../../leaves/view/cubit/leaves_cubit.dart';
import '../../../../leaves/view/sections/leaves_table_section.dart';
import '../../sections/my_tasks_section.dart';

class EmployeePortalTabs extends StatelessWidget {
  const EmployeePortalTabs({super.key, required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Expanded(
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: t.myTasks),
              Tab(text: t.myAttendance),
              Tab(text: t.myLeaves),
              Tab(text: t.myRequests),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                MyTasksSection(employeeId: employeeId),
                BlocProvider(
                  create: (_) => AttendanceCubit(AppDI.attendanceRepo, employeeId: employeeId)..load(),
                  child: const AttendanceTableSection(showCreate: false),
                ),
                BlocProvider(
                  create: (_) => LeavesCubit(AppDI.leavesRepo, employeeId: employeeId)..load(),
                  child: LeavesTableSection(employeeId: employeeId),
                ),
                BlocProvider(
                  create: (_) => ApprovalsCubit(AppDI.approvalsRepo, employeeId: employeeId)..load(),
                  child: const ApprovalsTableSection(readOnly: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
