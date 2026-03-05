import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/app_di.dart';
import '../cubit/accounts_cubit.dart';
import '../sections/accounts_table_section.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountsCubit(AppDI.accountsRepo)..load(),
      child: const AccountsTableSection(),
    );
  }
}
