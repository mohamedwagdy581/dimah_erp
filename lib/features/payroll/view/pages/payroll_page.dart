import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../cubit/payroll_cubit.dart';
import '../sections/payroll_table_section.dart';

class PayrollPage extends StatelessWidget {
  const PayrollPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PayrollCubit(AppDI.payrollRepo)..load(),
      child: const PayrollTableSection(),
    );
  }
}
