import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import 'hr_forms_workspace.dart';

import '../../domain/models/hr_form_template_def.dart';
import '../widgets/hr_form_card.dart';
import '../widgets/hr_forms_header.dart';

class HrFormsPage extends StatelessWidget {
  const HrFormsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    if (session is SessionReady &&
        ['hr', 'admin'].contains(session.user.role)) {
      return const HrFormsWorkspace();
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HrFormsHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final count = width > 1100
                    ? 3
                    : width > 700
                    ? 2
                    : 1;
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.28,
                  ),
                  itemCount: hrFormTemplates.length,
                  itemBuilder: (_, index) =>
                      HrFormCard(template: hrFormTemplates[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
