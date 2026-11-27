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
    this.publicBaseUrl = '',
    this.androidPackageName = 'com.turnia.app',
    this.privacyPolicyUrl =
        'https://agendapro-api-469f.onrender.com/privacidad',
    this.termsUrl = 'https://agendapro-api-469f.onrender.com/terminos',
    this.admobBannerUnitId = defaultTestBannerUnitId,
    this.googleServerClientId = '',
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
      publicBaseUrl: const String.fromEnvironment('PUBLIC_BASE_URL'),
      androidPackageName: const String.fromEnvironment(
        'APP_PACKAGE_NAME',
        defaultValue: 'com.turnia.app',
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
      googleServerClientId: const String.fromEnvironment(
        'GOOGLE_WEB_CLIENT_ID',
      ),
    );
  }

  final AppFlavor flavor;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String apiBaseUrl;

  /// Base de las páginas públicas que se comparten con los clientes.
  ///
  /// Vacía significa "el mismo host que la API". El día que haya dominio
  /// propio basta con definir `PUBLIC_BASE_URL` al compilar: el enlace que
  /// comparte el negocio y el que abre el cliente salen de aquí.
  final String publicBaseUrl;

  /// Host público sin barra final, listo para concatenar `/r/{slug}`.
  String get publicBase {
    final value = publicBaseUrl.trim().isNotEmpty ? publicBaseUrl : apiBaseUrl;
    return value.trim().replaceAll(RegExp(r'/+$'), '');
  }

  /// Páginas legales públicas servidas por el backend.
  final String privacyPolicyUrl;
  final String termsUrl;

  /// Bloque de anuncios del plan Gratis.
  final String admobBannerUnitId;

  /// Client ID **Web** del proyecto de Google Cloud.
  ///
  /// `google_sign_in` lo usa como `serverClientId` para obtener el idToken que
  /// Supabase valida. El cliente Android no sirve aquí: Supabase compara la
  /// audiencia del token contra este valor.
  final String googleServerClientId;

  /// Sin Client ID Web el botón de Google no se muestra: pulsarlo solo daría
  /// un error de configuración al usuario.
  bool get isGoogleSignInConfigured =>
      googleServerClientId.trim().isNotEmpty;

  /// applicationId de Android (necesario para el enlace de gestión de suscripción).
  final String androidPackageName;

  bool get isDev => flavor == AppFlavor.dev;

  /// Verdadero cuando la app puede inicializar Supabase.
  bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}
