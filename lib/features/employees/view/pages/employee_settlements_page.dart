import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../cubit/settlements_cubit.dart';
import '../sections/settlements_table_section.dart';

class EmployeeSettlementsPage extends StatelessWidget {
  const EmployeeSettlementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettlementsCubit(AppDI.employeesRepo)..load(),
      child: const SettlementsTableSection(),
    );
  }
}
