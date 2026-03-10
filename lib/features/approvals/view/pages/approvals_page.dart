import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../cubit/approvals_cubit.dart';
import '../sections/approvals_table_section.dart';

class ApprovalsPage extends StatelessWidget {
  const ApprovalsPage({super.key, this.initialStatus, this.initialRequestType});

  final String? initialStatus;
  final String? initialRequestType;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApprovalsCubit(
        AppDI.approvalsRepo,
        initialStatus: initialStatus,
        initialRequestType: initialRequestType,
      )..load(),
      child: const ApprovalsTableSection(),
    );
  }
}
