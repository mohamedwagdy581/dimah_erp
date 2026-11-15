import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../cubit/job_titles_cubit.dart';
import '../sections/job_titles_table_section.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../departments/view/hr_organization_page.dart';

class JobTitlesPage extends StatelessWidget {
  const JobTitlesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    if (session is SessionReady &&
        ['hr', 'admin'].contains(session.user.role)) {
      return const HrOrganizationPage(initialTab: 1);
    }
    return BlocProvider(
      create: (_) => JobTitlesCubit(AppDI.jobTitlesRepo)..load(),
      child: const JobTitlesTableSection(),
    );
  }
}
