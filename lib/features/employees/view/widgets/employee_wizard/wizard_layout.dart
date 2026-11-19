import 'package:material_ui/material_ui.dart';

const wizardPurple = Color(0xFF8654BC);
const wizardInk = Color(0xFF21194E);
const wizardBorder = Color(0xFFE8E2F4);

class WizardFieldsGrid extends StatelessWidget {
  const WizardFieldsGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 480 ? 2 : 1;
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 18,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );
}

class WizardLabeledField extends StatelessWidget {
  const WizardLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
  });
  final String label;
  final Widget child;
  final bool required;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: label),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        style: const TextStyle(
          fontSize: 13,
          color: wizardInk,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      child,
    ],
  );
}
