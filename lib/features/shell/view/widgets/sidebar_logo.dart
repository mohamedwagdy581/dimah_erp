import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class SidebarLogo extends StatelessWidget {
  const SidebarLogo({super.key, required this.isCollapsed});
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Image.asset(
            'assets/images/fullLogo.png',
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isCollapsed
                  ? const SizedBox.shrink()
                  : Text(
                      AppLocalizations.of(context)!.dimahErp,
                      key: const ValueKey('title'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
