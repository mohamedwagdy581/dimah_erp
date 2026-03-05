import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class SidebarToggleButton extends StatelessWidget {
  const SidebarToggleButton({
    super.key,
    required this.isCollapsed,
    required this.onPressed,
  });

  final bool isCollapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCollapsed ? Alignment.center : Alignment.centerRight,
      child: IconButton(
        onPressed: onPressed,
        tooltip: isCollapsed
            ? AppLocalizations.of(context)!.expand
            : AppLocalizations.of(context)!.collapse,
        icon: AnimatedRotation(
          turns: isCollapsed ? 0.0 : 0.5,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: const Icon(Icons.chevron_left),
        ),
      ),
    );
  }
}
