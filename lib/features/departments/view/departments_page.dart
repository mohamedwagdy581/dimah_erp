import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/app_di.dart';
import 'cubit/departments_cubit.dart';
import 'sections/departments_table_section.dart';
import '../../../core/session/session_cubit.dart';
import 'hr_organization_page.dart';

class DepartmentsPage extends StatelessWidget {
  const DepartmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    if (session is SessionReady &&
        ['hr', 'admin'].contains(session.user.role)) {
      return const HrOrganizationPage();
    }
    return BlocProvider(
      create: (_) => DepartmentsCubit(AppDI.departmentsRepo)..load(),
      child: const DepartmentsTableSection(),
    );
  }
}
