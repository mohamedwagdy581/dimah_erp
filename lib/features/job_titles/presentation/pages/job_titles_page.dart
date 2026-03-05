import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../cubit/job_titles_cubit.dart';
import '../sections/job_titles_table_section.dart';

class JobTitlesPage extends StatelessWidget {
  const JobTitlesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JobTitlesCubit(AppDI.jobTitlesRepo)..load(),
      child: const JobTitlesTableSection(),
    );
  }
}
