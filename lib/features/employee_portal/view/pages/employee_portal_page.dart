import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/session/session_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/employee_portal/employee_portal_summary.dart';
import '../widgets/employee_portal/employee_portal_tabs.dart';

class EmployeePortalPage extends StatelessWidget {
  const EmployeePortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        if (state is SessionLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is SessionUnauthed) {
          return Center(child: Text(t.sessionMissing));
        }

        final user = (state as SessionReady).user;
        final employeeId = user.employeeId;
        if (employeeId == null) {
          return Center(child: Text(t.employeeProfileNotLinked));
        }

        return DefaultTabController(
          length: 4,
          child: Column(
            children: [
              EmployeePortalSummary(employeeId: employeeId),
              EmployeePortalTabs(employeeId: employeeId),
            ],
          ),
        );
      },
    );
  }
}
