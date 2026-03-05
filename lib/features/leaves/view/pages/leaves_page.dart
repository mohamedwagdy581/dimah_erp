import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../cubit/leaves_cubit.dart';
import '../sections/leaves_table_section.dart';

class LeavesPage extends StatelessWidget {
  const LeavesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LeavesCubit(AppDI.leavesRepo)..load(),
      child: const LeavesTableSection(),
    );
  }
}
