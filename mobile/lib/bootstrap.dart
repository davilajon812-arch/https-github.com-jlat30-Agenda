import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/providers/app_providers.dart';
import 'l10n/app_localizations.dart';

/// Punto de arranque: valida la configuración e inicializa Supabase.
Future<void> bootstrap({AppConfig? config}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final appConfig = config ?? AppConfig.fromEnvironment();

  if (!appConfig.isSupabaseConfigured) {
    runApp(_MissingConfigurationApp(config: appConfig));
    return;
  }

  await Supabase.initialize(
    url: appConfig.supabaseUrl,
    publishableKey: appConfig.supabaseAnonKey,
    debug: appConfig.isDev,
  );

  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(appConfig),
        supabaseClientProvider.overrideWithValue(Supabase.instance.client),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const AgendaProApp(),
    ),
  );
}

class _MissingConfigurationApp extends StatelessWidget {
  const _MissingConfigurationApp({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.settings_suggest_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      l10n.configMissingTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.configMissingMessage,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
