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
    this.androidPackageName = 'com.agendapro.agenda_pro',
    this.privacyPolicyUrl =
        'https://agendapro-api-469f.onrender.com/privacidad',
    this.termsUrl = 'https://agendapro-api-469f.onrender.com/terminos',
    this.admobBannerUnitId = defaultTestBannerUnitId,
  });

  /// Bloque de anuncios de prueba de Google (nunca genera ingresos).
  static const defaultTestBannerUnitId = 'ca-app-pub-3940256099942544/6300978111';

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
        defaultValue: 'http://10.0.2.2:8000',
      ),
      androidPackageName: const String.fromEnvironment(
        'APP_PACKAGE_NAME',
        defaultValue: 'com.agendapro.agenda_pro',
      ),
      privacyPolicyUrl: const String.fromEnvironment(
        'PRIVACY_POLICY_URL',
        defaultValue: 'https://agendapro-api-469f.onrender.com/privacidad',
      ),
      termsUrl: const String.fromEnvironment(
        'TERMS_URL',
        defaultValue: 'https://agendapro-api-469f.onrender.com/terminos',
      ),
      admobBannerUnitId: const String.fromEnvironment(
        'ADMOB_BANNER_UNIT_ID',
        defaultValue: defaultTestBannerUnitId,
      ),
    );
  }

  final AppFlavor flavor;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String apiBaseUrl;

  /// Páginas legales públicas servidas por el backend.
  final String privacyPolicyUrl;
  final String termsUrl;

  /// Bloque de anuncios del plan Gratis.
  final String admobBannerUnitId;

  /// applicationId de Android (necesario para el enlace de gestión de suscripción).
  final String androidPackageName;

  bool get isDev => flavor == AppFlavor.dev;

  /// Verdadero cuando la app puede inicializar Supabase.
  bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}
