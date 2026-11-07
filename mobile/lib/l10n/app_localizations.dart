import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'AgendaPro'**
  String get appTitle;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get commonLoading;

  /// No description provided for @commonSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get commonSoon;

  /// No description provided for @authSignInTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de nuevo'**
  String get authSignInTitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para administrar tu agenda.'**
  String get authSignInSubtitle;

  /// No description provided for @authEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authPassword;

  /// No description provided for @authSignIn.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get authSignIn;

  /// No description provided for @authForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get authForgotPassword;

  /// No description provided for @authNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get authNoAccount;

  /// No description provided for @authCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get authCreateAccount;

  /// No description provided for @authRegisterTitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Empieza a organizar las citas de tu negocio.'**
  String get authRegisterSubtitle;

  /// No description provided for @authFullName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get authFullName;

  /// No description provided for @authPhoneOptional.
  ///
  /// In es, this message translates to:
  /// **'Teléfono (opcional)'**
  String get authPhoneOptional;

  /// No description provided for @authRegister.
  ///
  /// In es, this message translates to:
  /// **'Registrarme'**
  String get authRegister;

  /// No description provided for @authHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta?'**
  String get authHaveAccount;

  /// No description provided for @authResetTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get authResetTitle;

  /// No description provided for @authResetSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te enviaremos un enlace para restablecer tu contraseña.'**
  String get authResetSubtitle;

  /// No description provided for @authSendResetLink.
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace'**
  String get authSendResetLink;

  /// No description provided for @authResetSent.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu correo: enviamos un enlace para restablecer la contraseña.'**
  String get authResetSent;

  /// No description provided for @authConfirmEmailSent.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un correo para confirmar tu cuenta. Confírmalo y vuelve a entrar.'**
  String get authConfirmEmailSent;

  /// No description provided for @validationRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get validationRequired;

  /// No description provided for @validationEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo válido'**
  String get validationEmail;

  /// No description provided for @validationPasswordLength.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 8 caracteres'**
  String get validationPasswordLength;

  /// No description provided for @validationNameLength.
  ///
  /// In es, this message translates to:
  /// **'El nombre debe tener al menos 3 caracteres'**
  String get validationNameLength;

  /// No description provided for @errorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error. Intenta de nuevo.'**
  String get errorGeneric;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailNotConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Debes confirmar tu correo antes de entrar.'**
  String get errorEmailNotConfirmed;

  /// No description provided for @errorEmailInUse.
  ///
  /// In es, this message translates to:
  /// **'Ese correo ya está registrado.'**
  String get errorEmailInUse;

  /// No description provided for @errorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu red e intenta otra vez.'**
  String get errorNetwork;

  /// No description provided for @errorWeakPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es demasiado débil.'**
  String get errorWeakPassword;

  /// No description provided for @onboardingTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos de tu negocio'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Con estos datos armamos tu agenda.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingBusinessName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del negocio'**
  String get onboardingBusinessName;

  /// No description provided for @onboardingIndustry.
  ///
  /// In es, this message translates to:
  /// **'Rubro'**
  String get onboardingIndustry;

  /// No description provided for @onboardingCountry.
  ///
  /// In es, this message translates to:
  /// **'País'**
  String get onboardingCountry;

  /// No description provided for @onboardingCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get onboardingCurrency;

  /// No description provided for @onboardingTimezone.
  ///
  /// In es, this message translates to:
  /// **'Zona horaria'**
  String get onboardingTimezone;

  /// No description provided for @onboardingCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear negocio'**
  String get onboardingCreate;

  /// No description provided for @onboardingNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre de tu negocio'**
  String get onboardingNameRequired;

  /// No description provided for @industryBarberia.
  ///
  /// In es, this message translates to:
  /// **'Barbería'**
  String get industryBarberia;

  /// No description provided for @industrySalon.
  ///
  /// In es, this message translates to:
  /// **'Salón de belleza'**
  String get industrySalon;

  /// No description provided for @industryTaller.
  ///
  /// In es, this message translates to:
  /// **'Taller mecánico'**
  String get industryTaller;

  /// No description provided for @industryVeterinaria.
  ///
  /// In es, this message translates to:
  /// **'Veterinaria'**
  String get industryVeterinaria;

  /// No description provided for @industryGimnasio.
  ///
  /// In es, this message translates to:
  /// **'Gimnasio'**
  String get industryGimnasio;

  /// No description provided for @industryAcademia.
  ///
  /// In es, this message translates to:
  /// **'Academia'**
  String get industryAcademia;

  /// No description provided for @industryFotografia.
  ///
  /// In es, this message translates to:
  /// **'Fotografía'**
  String get industryFotografia;

  /// No description provided for @industryOtro.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get industryOtro;

  /// No description provided for @navAppointments.
  ///
  /// In es, this message translates to:
  /// **'Agenda'**
  String get navAppointments;

  /// No description provided for @navClients.
  ///
  /// In es, this message translates to:
  /// **'Clientes'**
  String get navClients;

  /// No description provided for @navPlan.
  ///
  /// In es, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// No description provided for @navSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @homeTodayEmpty.
  ///
  /// In es, this message translates to:
  /// **'Tu agenda del día se verá aquí.'**
  String get homeTodayEmpty;

  /// No description provided for @settingsAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get settingsLanguageSpanish;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get settingsAccount;

  /// No description provided for @settingsSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsSignOut;

  /// No description provided for @settingsBusiness.
  ///
  /// In es, this message translates to:
  /// **'Negocio'**
  String get settingsBusiness;

  /// No description provided for @billingCurrentPlan.
  ///
  /// In es, this message translates to:
  /// **'Plan actual'**
  String get billingCurrentPlan;

  /// No description provided for @billingPlanFree.
  ///
  /// In es, this message translates to:
  /// **'Gratis'**
  String get billingPlanFree;

  /// No description provided for @billingSoon.
  ///
  /// In es, this message translates to:
  /// **'Los planes de pago estarán disponibles en la Fase 3.'**
  String get billingSoon;

  /// No description provided for @placeholderPhaseTwo.
  ///
  /// In es, this message translates to:
  /// **'Esta sección se habilita en la Fase 2.'**
  String get placeholderPhaseTwo;

  /// No description provided for @configMissingTitle.
  ///
  /// In es, this message translates to:
  /// **'Falta configuración'**
  String get configMissingTitle;

  /// No description provided for @configMissingMessage.
  ///
  /// In es, this message translates to:
  /// **'Define SUPABASE_URL y SUPABASE_ANON_KEY al compilar la app (ver README).'**
  String get configMissingMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
