import 'package:flutter/material.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../view/sections/sidebar_section.dart';
import '../view/sections/home_body_section.dart';
import '../../../core/ui/app_breakpoints.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  final ValueNotifier<bool> _collapsed = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _collapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(MediaQuery.sizeOf(context).width);

    return ValueListenableBuilder<bool>(
      valueListenable: _collapsed,
      builder: (context, isCollapsed, _) {
        final sidebarCollapsed = isMobile ? false : isCollapsed;

        return AppScaffold(
          title: AppLocalizations.of(context)!.homeTitle,
          isCollapsed: isCollapsed,
          onToggle: () => _collapsed.value = !_collapsed.value,
          sidebar: SidebarSection(
            isCollapsed: sidebarCollapsed,
            onToggle: () => _collapsed.value = !_collapsed.value,
            role: 'admin',
            email: 'email',
            showToggle: !isMobile,
            onNavigate: isMobile
                ? () => Navigator.of(context).maybePop()
                : null,
          ),
          body: const HomeBodySection(),
        );
      },
    );
  }
}
