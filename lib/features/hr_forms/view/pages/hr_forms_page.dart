import 'package:flutter/material.dart';

import '../../domain/models/hr_form_template_def.dart';
import '../widgets/hr_form_card.dart';
import '../widgets/hr_forms_header.dart';

class HrFormsPage extends StatelessWidget {
  const HrFormsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                final count = width > 1100 ? 3 : width > 700 ? 2 : 1;
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.28,
                  ),
                  itemCount: hrFormTemplates.length,
                  itemBuilder: (_, index) => HrFormCard(template: hrFormTemplates[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
