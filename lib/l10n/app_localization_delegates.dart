import 'package:material_ui/material_ui.dart';

import 'app_localizations.dart';

/// App strings and design delegates for the standalone Material widgets.
const appLocalizationDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];
