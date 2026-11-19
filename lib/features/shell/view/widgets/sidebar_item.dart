import 'package:material_ui/material_ui.dart';

class SidebarItem extends StatelessWidget {
  const SidebarItem({
    super.key,
    required this.isCollapsed,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.active,
    this.badgeCount = 0,
    this.employeeStyle = false,
    this.showActiveIndicator = false,
  });

  final bool isCollapsed;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final int badgeCount;
  final bool employeeStyle;
  final bool showActiveIndicator;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = active
        ? (employeeStyle
              ? Colors.white.withValues(alpha: .16)
              : cs.primaryContainer)
        : Colors.transparent;
    final fg = employeeStyle
        ? Colors.white
        : (active ? cs.onPrimaryContainer : cs.onSurface);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 22, color: fg),
                    if (badgeCount > 0 && (!employeeStyle || isCollapsed))
                      Positioned(
                        right: -8,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: isCollapsed
                        ? const SizedBox.shrink()
                        : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  key: ValueKey(label),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: fg),
                                ),
                              ),
                              if (badgeCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    badgeCount > 99 ? '99+' : '$badgeCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            if (showActiveIndicator && active && !isCollapsed)
              PositionedDirectional(
                end: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 3,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
