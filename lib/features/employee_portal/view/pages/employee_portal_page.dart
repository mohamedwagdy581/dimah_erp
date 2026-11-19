import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/session/session_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/employee_portal/employee_portal_summary.dart';
import '../widgets/employee_portal/employee_portal_tabs.dart';
import '../sections/my_tasks_section.dart';
import '../sections/employee_requests_section.dart';
import '../../../../core/di/app_di.dart';
import '../cubit/employee_attendance_cubit.dart';
import '../widgets/employee_attendance_view.dart';

class EmployeePortalPage extends StatelessWidget {
  const EmployeePortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        if (state is SessionLoading) {
          return const AppLoadingState();
        }
        if (state is SessionUnauthed) {
          return Center(child: Text(t.sessionMissing));
        }

        final user = (state as SessionReady).user;
        final employeeId = user.employeeId;
        if (employeeId == null) {
          return Center(child: Text(t.employeeProfileNotLinked));
        }

        final tab = GoRouterState.of(context).uri.queryParameters['tab'];
        if (user.role == 'employee' && tab == 'attendance') {
          return BlocProvider(
            key: ValueKey(employeeId),
            create: (_) => EmployeeAttendanceCubit(
              AppDI.employeeAttendanceRepo,
              employeeId: employeeId,
            )..load(),
            child: EmployeeAttendanceView(
              onRequests: () => context.go('/my?tab=requests'),
            ),
          );
        }
        if (user.role == 'employee' && (tab == 'requests' || tab == 'leaves')) {
          return EmployeeRequestsSection(
            key: ValueKey(employeeId),
            employeeId: employeeId,
          );
        }
        if (user.role == 'employee' && (tab == null || tab == 'tasks')) {
          return MyTasksSection(
            key: ValueKey(employeeId),
            employeeId: employeeId,
            employeeDesign: true,
          );
        }

        return DefaultTabController(
          key: ValueKey(GoRouterState.of(context).uri.queryParameters['tab']),
          initialIndex: switch (GoRouterState.of(
            context,
          ).uri.queryParameters['tab']) {
            'attendance' => 1,
            'leaves' => 2,
            'requests' => user.role == 'employee' ? 2 : 3,
            _ => 0,
          },
          length: user.role == 'employee' ? 3 : 4,
          child: Column(
            children: [
              EmployeePortalSummary(employeeId: employeeId),
              EmployeePortalTabs(
                employeeId: employeeId,
                employeeDesign: user.role == 'employee',
              ),
            ],
          ),
        );
      },
    );
  }
}
