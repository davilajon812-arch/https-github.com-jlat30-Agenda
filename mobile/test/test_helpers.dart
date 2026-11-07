import 'package:agenda_pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Envuelve un widget con las localizaciones reales de la app.
Widget wrapWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

/// Localizaciones en español para pruebas.
AppLocalizations spanishLocalizations() {
  return lookupAppLocalizations(const Locale('es'));
}
