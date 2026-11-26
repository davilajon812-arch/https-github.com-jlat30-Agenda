import 'package:agenda_pro/core/config/app_config.dart';
import 'package:agenda_pro/core/providers/app_providers.dart';
import 'package:agenda_pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Envuelve un widget con las localizaciones reales de la app.
///
/// [config] permite probar pantallas que dependen de la configuración de
/// compilación (por ejemplo, el botón de Google); sin ella se usa
/// [testAppConfig].
Widget wrapWidget(
  Widget child, {
  AppConfig? config,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(config ?? testAppConfig()),
      ...overrides,
    ],
    child: MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

/// Configuración mínima para construir pantallas en pruebas.
AppConfig testAppConfig({String googleWebClientId = ''}) {
  return AppConfig(
    flavor: AppFlavor.dev,
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'test-anon-key',
    apiBaseUrl: 'http://localhost:8000',
    googleServerClientId: googleWebClientId,
  );
}

/// Localizaciones en español para pruebas.
AppLocalizations spanishLocalizations() {
  return lookupAppLocalizations(const Locale('es'));
}
