import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import 'cubit/departments_cubit.dart';
import 'sections/departments_table_section.dart';

class DepartmentsPage extends StatelessWidget {
  const DepartmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DepartmentsCubit(AppDI.departmentsRepo)..load(),
      child: const DepartmentsTableSection(),
    );
  }
}
