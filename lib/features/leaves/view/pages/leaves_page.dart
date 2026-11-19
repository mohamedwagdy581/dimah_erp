import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../cubit/leaves_cubit.dart';
import '../sections/leaves_table_section.dart';
import '../../../../core/session/session_cubit.dart';
import '../widgets/admin_leaves_workspace.dart';

class LeavesPage extends StatelessWidget {
  const LeavesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    return BlocProvider(
      create: (_) => LeavesCubit(AppDI.leavesRepo)..load(),
      child: session is SessionReady && session.user.role == 'admin'
          ? const AdminLeavesWorkspace()
          : const LeavesTableSection(),
    );
  }
}
