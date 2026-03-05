// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class SidebarUserCard extends StatelessWidget {
  const SidebarUserCard({
    super.key,
    required this.sidebarWidth,
    required this.email,
    required this.role,
    required this.onTap,
  });

  final double sidebarWidth;
  final String email;
  final String role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ✅ نفس معيار الـ SidebarSection
    final small = sidebarWidth < 160;

    // ✅ ClipRect يمنع أي overflow warning أثناء الأنيميشن
    return ClipRect(
      child: small
          ? Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(.6),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 18,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            )
          : InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(.6),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.person, color: cs.onPrimaryContainer),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: cs.onSurface),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _roleLabel(context, role),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withOpacity(.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.more_vert,
                        color: cs.onSurface.withOpacity(.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _roleLabel(BuildContext context, String role) {
    final t = AppLocalizations.of(context)!;
    switch (role) {
      case 'admin':
        return t.roleAdmin;
      case 'hr':
        return t.roleHr;
      case 'manager':
        return t.roleManager;
      case 'accountant':
        return t.roleAccountant;
      case 'employee':
        return t.roleEmployee;
      default:
        return role;
    }
  }
}
