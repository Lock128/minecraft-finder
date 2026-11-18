import 'package:cupertino_ui/cupertino_ui.dart' as cupertino_ui;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

import 'app_localizations.dart';

/// Localization delegates for the app.
///
/// Use this instead of `AppLocalizations.localizationsDelegates`. The generated
/// list registers the Material and Cupertino delegates from
/// `flutter_localizations`, but the widgets now come from `material_ui` and
/// `cupertino_ui`. Those packages look up their own localization classes, so
/// the old delegates leave every locale except English without Material and
/// Cupertino strings.
///
/// This file is hand-written. `flutter gen-l10n` does not overwrite it.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  cupertino_ui.GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];
