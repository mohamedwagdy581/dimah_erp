import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/app_di.dart';
import '../cubit/journal_cubit.dart';
import '../sections/journal_table_section.dart';
import '../widgets/journal_draft_workspace.dart';

class JournalPage extends StatelessWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (GoRouterState.of(context).uri.queryParameters['new'] == '1') {
      return JournalDraftWorkspace(
        accountsRepo: AppDI.accountsRepo,
        journalRepo: AppDI.journalRepo,
        onSaved: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'تم حفظ القيد كمسودة.'
                    : 'Journal saved as a draft.',
              ),
            ),
          );
          context.go('/journal');
        },
        onCancel: () => context.go('/journal'),
      );
    }
    return BlocProvider(
      create: (_) => JournalCubit(AppDI.journalRepo)..load(),
      child: const JournalTableSection(),
    );
  }
}
