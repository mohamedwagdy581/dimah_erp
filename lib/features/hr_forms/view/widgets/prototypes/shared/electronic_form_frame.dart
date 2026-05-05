import 'package:flutter/material.dart';

import 'electronic_form_decorations.dart';
import 'electronic_form_theme.dart';

class ElectronicFormFrame extends StatelessWidget {
  const ElectronicFormFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.child,
    this.showDecoration = true,
    this.headerLogo,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget child;
  final bool showDecoration;
  final Widget? headerLogo;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: ElectronicFormDimensions.cardWidth,
      padding: const EdgeInsets.symmetric(
        horizontal: ElectronicFormDimensions.cardHorizontalPadding,
        vertical: ElectronicFormDimensions.cardVerticalPadding,
      ),
      decoration: ElectronicFormDecorations.cardDecoration,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showDecoration) const ElectronicHeaderDecoration(),
          if (headerLogo != null)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: ElectronicFormDimensions.headerLogoSize,
                  height: ElectronicFormDimensions.headerLogoSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(
                    ElectronicFormDimensions.headerLogoPadding,
                  ),
                  child: headerLogo,
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: ElectronicFormDimensions.headerTopSpacing),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: ElectronicFormTextStyles.title),
                        const SizedBox(
                          height: ElectronicFormDimensions.textSpacing,
                        ),
                        Text(
                          subtitle,
                          style: ElectronicFormTextStyles.subtitle,
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: ElectronicFormDimensions.actionSpacing,
                    runSpacing: ElectronicFormDimensions.actionSpacing,
                    children: actions,
                  ),
                ],
              ),
              const SizedBox(height: ElectronicFormDimensions.sectionSpacing),
              child,
              if (showDecoration)
                const SizedBox(height: ElectronicFormDimensions.sectionSpacing),
              if (showDecoration) const ElectronicFooterDecoration(),
            ],
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Center(child: card)],
    );
  }
}
