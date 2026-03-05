import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../cubit/employee_docs_cubit.dart';
import '../sections/employee_docs_table_section.dart';

class EmployeeDocsPage extends StatelessWidget {
  const EmployeeDocsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmployeeDocsCubit(AppDI.employeeDocsRepo)..load(),
      child: const EmployeeDocsTableSection(),
    );
  }
}
