/// Entorno de compilación de la app.
enum AppFlavor {
  /// Desarrollo: apunta a proyectos de Supabase de prueba.
  dev('dev'),

  /// Producción: build que se publica en Google Play.
  prod('prod');

  const AppFlavor(this.label);

  /// Nombre usado en `--dart-define=APP_FLAVOR=...`.
  final String label;

  static AppFlavor fromName(String name) {
    return AppFlavor.values.firstWhere(
      (flavor) => flavor.label == name,
      orElse: () => AppFlavor.dev,
    );
  }
}

/// Configuración inyectada al compilar la app.
///
/// Los valores llegan por `--dart-define` (ver README) o por archivo
/// `.env` convertido a `--dart-define-from-file`.
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.apiBaseUrl,
  });

  factory AppConfig.fromEnvironment({AppFlavor? defaultFlavor}) {
    return AppConfig(
      flavor: defaultFlavor ??
          AppFlavor.fromName(
            const String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev'),
          ),
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8000',
      ),
    );
  }

  final AppFlavor flavor;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String apiBaseUrl;

  bool get isDev => flavor == AppFlavor.dev;

  /// Verdadero cuando la app puede inicializar Supabase.
  bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}
