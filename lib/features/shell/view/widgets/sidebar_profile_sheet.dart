import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../core/settings/app_settings_state.dart';
import '../../../../l10n/app_localizations.dart';

class SidebarProfileSheet extends StatelessWidget {
  const SidebarProfileSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (context, settings) {
          final isDark = settings.themeMode == ThemeMode.dark;
          final isArabic = settings.locale.languageCode == 'ar';
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(t.myProfile),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(t.changePassword),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/change-password');
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: Text(t.darkMode),
                value: isDark,
                onChanged: (_) => context.read<AppSettingsCubit>().toggleTheme(),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.language_outlined),
                title: Text('${t.language}: ${isArabic ? t.languageArabic : t.languageEnglish}'),
                value: isArabic,
                onChanged: (_) => context.read<AppSettingsCubit>().toggleLanguage(),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(t.logout),
                onTap: () async {
                  Navigator.pop(context);
                  await Supabase.instance.client.auth.signOut();
                },
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}
