import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/app_di.dart';
import '../cubit/journal_cubit.dart';
import '../sections/journal_table_section.dart';

class JournalPage extends StatelessWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JournalCubit(AppDI.journalRepo)..load(),
      child: const JournalTableSection(),
    );
  }
}
