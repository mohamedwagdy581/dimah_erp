import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/session/session_cubit.dart';
import '../cubit/employees_cubit.dart';
import '../sections/employees_table_section.dart';
import 'hr_employees_page.dart';

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, session) {
        if (session is! SessionReady) {
          return const AppLoadingState();
        }
        if (session.user.role == 'hr' || session.user.role == 'admin') {
          return const HrEmployeesPage();
        }
        final role = session.user.role;
        final employeeId = session.user.employeeId;
        return BlocProvider(
          create: (_) => EmployeesCubit(
            AppDI.employeesRepo,
            actorRole: role,
            actorEmployeeId: employeeId,
          )..load(),
          child: EmployeesTableSection(
            canEdit: role == 'admin' || role == 'hr',
            canCreate: role == 'admin' || role == 'hr',
          ),
        );
      },
    );
  }
}
