// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'AgendaPro';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonLoading => 'Cargando...';

  @override
  String get commonSoon => 'Próximamente';

  @override
  String get authSignInTitle => 'Bienvenido de nuevo';

  @override
  String get authSignInSubtitle => 'Inicia sesión para administrar tu agenda.';

  @override
  String get authEmail => 'Correo electrónico';

  @override
  String get authPassword => 'Contraseña';

  @override
  String get authSignIn => 'Entrar';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authNoAccount => '¿No tienes cuenta?';

  @override
  String get authCreateAccount => 'Crear cuenta';

  @override
  String get authRegisterTitle => 'Crea tu cuenta';

  @override
  String get authRegisterSubtitle =>
      'Empieza a organizar las citas de tu negocio.';

  @override
  String get authFullName => 'Nombre completo';

  @override
  String get authPhoneOptional => 'Teléfono (opcional)';

  @override
  String get authRegister => 'Registrarme';

  @override
  String get authHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get authResetTitle => 'Recuperar contraseña';

  @override
  String get authResetSubtitle =>
      'Te enviaremos un enlace para restablecer tu contraseña.';

  @override
  String get authSendResetLink => 'Enviar enlace';

  @override
  String get authResetSent =>
      'Revisa tu correo: enviamos un enlace para restablecer la contraseña.';

  @override
  String get authConfirmEmailSent =>
      'Te enviamos un correo para confirmar tu cuenta. Confírmalo y vuelve a entrar.';

  @override
  String get validationRequired => 'Este campo es obligatorio';

  @override
  String get validationEmail => 'Ingresa un correo válido';

  @override
  String get validationPasswordLength =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get validationNameLength =>
      'El nombre debe tener al menos 3 caracteres';

  @override
  String get errorGeneric => 'Ocurrió un error. Intenta de nuevo.';

  @override
  String get errorInvalidCredentials => 'Correo o contraseña incorrectos.';

  @override
  String get errorEmailNotConfirmed =>
      'Debes confirmar tu correo antes de entrar.';

  @override
  String get errorEmailInUse => 'Ese correo ya está registrado.';

  @override
  String get errorNetwork => 'Sin conexión. Revisa tu red e intenta otra vez.';

  @override
  String get errorWeakPassword => 'La contraseña es demasiado débil.';

  @override
  String get onboardingTitle => 'Cuéntanos de tu negocio';

  @override
  String get onboardingSubtitle => 'Con estos datos armamos tu agenda.';

  @override
  String get onboardingBusinessName => 'Nombre del negocio';

  @override
  String get onboardingIndustry => 'Rubro';

  @override
  String get onboardingCountry => 'País';

  @override
  String get onboardingCurrency => 'Moneda';

  @override
  String get onboardingTimezone => 'Zona horaria';

  @override
  String get onboardingCreate => 'Crear negocio';

  @override
  String get onboardingNameRequired => 'Escribe el nombre de tu negocio';

  @override
  String get industryBarberia => 'Barbería';

  @override
  String get industrySalon => 'Salón de belleza';

  @override
  String get industryTaller => 'Taller mecánico';

  @override
  String get industryVeterinaria => 'Veterinaria';

  @override
  String get industryGimnasio => 'Gimnasio';

  @override
  String get industryAcademia => 'Academia';

  @override
  String get industryFotografia => 'Fotografía';

  @override
  String get industryOtro => 'Otro';

  @override
  String get navAppointments => 'Agenda';

  @override
  String get navClients => 'Clientes';

  @override
  String get navPlan => 'Plan';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get homeTodayEmpty => 'Tu agenda del día se verá aquí.';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSpanish => 'Español';

  @override
  String get settingsLanguageEnglish => 'Inglés';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get settingsBusiness => 'Negocio';

  @override
  String get billingCurrentPlan => 'Plan actual';

  @override
  String get billingPlanFree => 'Gratis';

  @override
  String get billingSoon =>
      'Los planes de pago estarán disponibles en la Fase 3.';

  @override
  String get placeholderPhaseTwo => 'Esta sección se habilita en la Fase 2.';

  @override
  String get configMissingTitle => 'Falta configuración';

  @override
  String get configMissingMessage =>
      'Define SUPABASE_URL y SUPABASE_ANON_KEY al compilar la app (ver README).';
}
