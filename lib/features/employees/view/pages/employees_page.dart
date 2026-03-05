import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/session/session_cubit.dart';
import '../cubit/employees_cubit.dart';
import '../sections/employees_table_section.dart';

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, session) {
        String? role;
        String? employeeId;
        if (session is SessionReady) {
          role = session.user.role;
          employeeId = session.user.employeeId;
        }
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
