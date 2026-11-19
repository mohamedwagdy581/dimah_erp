import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/routing/app_router.dart';
import '../core/settings/app_settings_cubit.dart';
import '../core/settings/app_settings_state.dart';
import '../core/ui/app_theme.dart';
import '../l10n/app_localization_delegates.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppSettingsCubit(),
      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (context, settings) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Dimah ERP SYS',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            locale: settings.locale,
            localizationsDelegates: appLocalizationDelegates,
            supportedLocales: const [Locale('en'), Locale('ar')],
            routerConfig: AppRouter.router,
            // Keep legacy widgets in third-party packages supplied with theme
            // and localization data while those packages migrate.
            // ignore: deprecated_member_use
            builder: (context, child) => MaterialUiCompatibilityBridge(
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
