import 'package:flutter/material.dart';
import '../ui/app_breakpoints.dart';
import '../../l10n/app_localizations.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.isCollapsed,
    required this.onToggle,
    required this.sidebar,
    required this.body,
    this.actions = const [],
  });

  final String title;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final Widget sidebar;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isMobile = AppBreakpoints.isMobile(c.maxWidth);

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              if (!isMobile)
                IconButton(
                  tooltip: isCollapsed
                      ? AppLocalizations.of(context)!.expandSidebar
                      : AppLocalizations.of(context)!.collapseSidebar,
                  onPressed: onToggle,
                  icon: Icon(
                    isCollapsed
                        ? Icons.keyboard_double_arrow_right
                        : Icons.keyboard_double_arrow_left,
                  ),
                ),
              ...actions,
            ],
            leading: isMobile
                ? Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  )
                : null,
          ),
          drawer: isMobile ? Drawer(child: SafeArea(child: sidebar)) : null,
          body: isMobile
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: body,
                  ),
                )
              : Row(
                  children: [
                    sidebar,
                    Expanded(
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: body,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
