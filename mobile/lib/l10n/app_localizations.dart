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
  /// **'Citaly'**
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

  /// No description provided for @settingsPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get settingsPrivacy;

  /// No description provided for @settingsTerms.
  ///
  /// In es, this message translates to:
  /// **'Términos del servicio'**
  String get settingsTerms;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get settingsDeleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar tu cuenta?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán tu cuenta, tu negocio, tus clientes, servicios, empleados y todas las citas. Esta acción no se puede deshacer.'**
  String get deleteAccountMessage;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar definitivamente'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountSuccess.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta fue eliminada.'**
  String get deleteAccountSuccess;

  /// No description provided for @deleteAccountError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar la cuenta. Intenta de nuevo.'**
  String get deleteAccountError;

  /// No description provided for @businessManageTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi negocio'**
  String get businessManageTitle;

  /// No description provided for @businessNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del negocio'**
  String get businessNameLabel;

  /// No description provided for @businessPhoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono del negocio'**
  String get businessPhoneLabel;

  /// No description provided for @businessEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar datos'**
  String get businessEdit;

  /// No description provided for @businessEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos del negocio'**
  String get businessEditTitle;

  /// No description provided for @businessNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo negocio'**
  String get businessNewTitle;

  /// No description provided for @businessSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get businessSave;

  /// No description provided for @businessCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear negocio'**
  String get businessCreate;

  /// No description provided for @businessSwitch.
  ///
  /// In es, this message translates to:
  /// **'Tus negocios'**
  String get businessSwitch;

  /// No description provided for @businessSwitchHint.
  ///
  /// In es, this message translates to:
  /// **'Elige con qué negocio quieres trabajar.'**
  String get businessSwitchHint;

  /// No description provided for @businessAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar negocio'**
  String get businessAdd;

  /// No description provided for @businessAddProTitle.
  ///
  /// In es, this message translates to:
  /// **'Necesitas el plan Pro'**
  String get businessAddProTitle;

  /// No description provided for @businessAddProMessage.
  ///
  /// In es, this message translates to:
  /// **'El plan Gratis permite un solo negocio. Con Pro puedes administrar varios desde la misma cuenta.'**
  String get businessAddProMessage;

  /// No description provided for @businessAddProAction.
  ///
  /// In es, this message translates to:
  /// **'Ver planes'**
  String get businessAddProAction;

  /// No description provided for @validationPhoneLength.
  ///
  /// In es, this message translates to:
  /// **'El teléfono debe tener al menos 6 dígitos'**
  String get validationPhoneLength;

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

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get commonAdd;

  /// No description provided for @commonSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get commonSearch;

  /// No description provided for @commonAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get commonAll;

  /// No description provided for @commonMinutes.
  ///
  /// In es, this message translates to:
  /// **'{count} min'**
  String commonMinutes(int count);

  /// No description provided for @statusPendiente.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get statusPendiente;

  /// No description provided for @statusConfirmada.
  ///
  /// In es, this message translates to:
  /// **'Confirmada'**
  String get statusConfirmada;

  /// No description provided for @statusCompletada.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get statusCompletada;

  /// No description provided for @statusCancelada.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get statusCancelada;

  /// No description provided for @statusNoAsistio.
  ///
  /// In es, this message translates to:
  /// **'No asistió'**
  String get statusNoAsistio;

  /// No description provided for @agendaToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get agendaToday;

  /// No description provided for @agendaDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get agendaDay;

  /// No description provided for @agendaWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get agendaWeek;

  /// No description provided for @agendaEmptyDay.
  ///
  /// In es, this message translates to:
  /// **'No hay citas para este día.'**
  String get agendaEmptyDay;

  /// No description provided for @agendaEmptyWeek.
  ///
  /// In es, this message translates to:
  /// **'No hay citas esta semana.'**
  String get agendaEmptyWeek;

  /// No description provided for @agendaNewAppointment.
  ///
  /// In es, this message translates to:
  /// **'Nueva cita'**
  String get agendaNewAppointment;

  /// No description provided for @agendaWhatsapp.
  ///
  /// In es, this message translates to:
  /// **'Abrir WhatsApp'**
  String get agendaWhatsapp;

  /// No description provided for @agendaTotalDay.
  ///
  /// In es, this message translates to:
  /// **'{count} citas'**
  String agendaTotalDay(int count);

  /// No description provided for @appointmentDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle de la cita'**
  String get appointmentDetailTitle;

  /// No description provided for @appointmentClient.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get appointmentClient;

  /// No description provided for @appointmentService.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get appointmentService;

  /// No description provided for @appointmentStaff.
  ///
  /// In es, this message translates to:
  /// **'Empleado'**
  String get appointmentStaff;

  /// No description provided for @appointmentWhen.
  ///
  /// In es, this message translates to:
  /// **'Fecha y hora'**
  String get appointmentWhen;

  /// No description provided for @appointmentPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get appointmentPrice;

  /// No description provided for @appointmentNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get appointmentNotes;

  /// No description provided for @appointmentChangeStatus.
  ///
  /// In es, this message translates to:
  /// **'Cambiar estado'**
  String get appointmentChangeStatus;

  /// No description provided for @appointmentConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get appointmentConfirm;

  /// No description provided for @appointmentComplete.
  ///
  /// In es, this message translates to:
  /// **'Marcar completada'**
  String get appointmentComplete;

  /// No description provided for @appointmentNoShow.
  ///
  /// In es, this message translates to:
  /// **'No asistió'**
  String get appointmentNoShow;

  /// No description provided for @appointmentCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar cita'**
  String get appointmentCancel;

  /// No description provided for @appointmentCancelReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo (opcional)'**
  String get appointmentCancelReason;

  /// No description provided for @appointmentUpdated.
  ///
  /// In es, this message translates to:
  /// **'Cita actualizada'**
  String get appointmentUpdated;

  /// No description provided for @newAppointmentTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva cita'**
  String get newAppointmentTitle;

  /// No description provided for @newAppointmentClient.
  ///
  /// In es, this message translates to:
  /// **'1. Cliente'**
  String get newAppointmentClient;

  /// No description provided for @newAppointmentService.
  ///
  /// In es, this message translates to:
  /// **'2. Servicio'**
  String get newAppointmentService;

  /// No description provided for @newAppointmentSlot.
  ///
  /// In es, this message translates to:
  /// **'3. Horario'**
  String get newAppointmentSlot;

  /// No description provided for @newAppointmentStaff.
  ///
  /// In es, this message translates to:
  /// **'Empleado'**
  String get newAppointmentStaff;

  /// No description provided for @newAppointmentAnyStaff.
  ///
  /// In es, this message translates to:
  /// **'Cualquiera'**
  String get newAppointmentAnyStaff;

  /// No description provided for @newAppointmentNoSlots.
  ///
  /// In es, this message translates to:
  /// **'No hay horarios libres ese día.'**
  String get newAppointmentNoSlots;

  /// No description provided for @newAppointmentPickSlot.
  ///
  /// In es, this message translates to:
  /// **'Elige el horario del servicio'**
  String get newAppointmentPickSlot;

  /// No description provided for @newAppointmentCreated.
  ///
  /// In es, this message translates to:
  /// **'Cita creada'**
  String get newAppointmentCreated;

  /// No description provided for @newAppointmentNeedService.
  ///
  /// In es, this message translates to:
  /// **'Elige un servicio para ver horarios'**
  String get newAppointmentNeedService;

  /// No description provided for @newClientInline.
  ///
  /// In es, this message translates to:
  /// **'Cliente nuevo'**
  String get newClientInline;

  /// No description provided for @clientsTitle.
  ///
  /// In es, this message translates to:
  /// **'Clientes'**
  String get clientsTitle;

  /// No description provided for @clientsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre o teléfono'**
  String get clientsSearchHint;

  /// No description provided for @clientsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes clientes registrados.'**
  String get clientsEmpty;

  /// No description provided for @clientNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo cliente'**
  String get clientNew;

  /// No description provided for @clientName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get clientName;

  /// No description provided for @clientPhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono con código de país'**
  String get clientPhone;

  /// No description provided for @clientNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get clientNotes;

  /// No description provided for @clientHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial de visitas'**
  String get clientHistory;

  /// No description provided for @clientNoVisits.
  ///
  /// In es, this message translates to:
  /// **'Sin visitas registradas.'**
  String get clientNoVisits;

  /// No description provided for @clientSaved.
  ///
  /// In es, this message translates to:
  /// **'Cliente guardado'**
  String get clientSaved;

  /// No description provided for @clientDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este cliente?'**
  String get clientDeleteConfirm;

  /// No description provided for @clientHasVisits.
  ///
  /// In es, this message translates to:
  /// **'No se puede eliminar: tiene citas registradas.'**
  String get clientHasVisits;

  /// No description provided for @servicesTitle.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get servicesTitle;

  /// No description provided for @servicesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Agrega tu primer servicio.'**
  String get servicesEmpty;

  /// No description provided for @serviceNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo servicio'**
  String get serviceNew;

  /// No description provided for @serviceName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del servicio'**
  String get serviceName;

  /// No description provided for @serviceDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración (minutos)'**
  String get serviceDuration;

  /// No description provided for @servicePrice.
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get servicePrice;

  /// No description provided for @serviceSaved.
  ///
  /// In es, this message translates to:
  /// **'Servicio guardado'**
  String get serviceSaved;

  /// No description provided for @servicesManagement.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get servicesManagement;

  /// No description provided for @staffTitle.
  ///
  /// In es, this message translates to:
  /// **'Empleados'**
  String get staffTitle;

  /// No description provided for @staffEmpty.
  ///
  /// In es, this message translates to:
  /// **'Agrega a tu primer empleado.'**
  String get staffEmpty;

  /// No description provided for @staffNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo empleado'**
  String get staffNew;

  /// No description provided for @staffName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del empleado'**
  String get staffName;

  /// No description provided for @staffSaved.
  ///
  /// In es, this message translates to:
  /// **'Empleado guardado'**
  String get staffSaved;

  /// No description provided for @staffManagement.
  ///
  /// In es, this message translates to:
  /// **'Empleados y horarios'**
  String get staffManagement;

  /// No description provided for @staffScheduleTitle.
  ///
  /// In es, this message translates to:
  /// **'Horario semanal'**
  String get staffScheduleTitle;

  /// No description provided for @staffScheduleEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin horario: no aparecerá disponible.'**
  String get staffScheduleEmpty;

  /// No description provided for @staffScheduleSaved.
  ///
  /// In es, this message translates to:
  /// **'Horario guardado'**
  String get staffScheduleSaved;

  /// No description provided for @staffBlocksTitle.
  ///
  /// In es, this message translates to:
  /// **'Bloqueos'**
  String get staffBlocksTitle;

  /// No description provided for @staffBlocksEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin vacaciones ni descansos.'**
  String get staffBlocksEmpty;

  /// No description provided for @staffBlockNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo bloqueo'**
  String get staffBlockNew;

  /// No description provided for @staffBlockKind.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get staffBlockKind;

  /// No description provided for @staffBlockVacation.
  ///
  /// In es, this message translates to:
  /// **'Vacaciones'**
  String get staffBlockVacation;

  /// No description provided for @staffBlockBreak.
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get staffBlockBreak;

  /// No description provided for @staffBlockOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get staffBlockOther;

  /// No description provided for @staffBlockReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo (opcional)'**
  String get staffBlockReason;

  /// No description provided for @staffBlockRange.
  ///
  /// In es, this message translates to:
  /// **'Desde / hasta'**
  String get staffBlockRange;

  /// No description provided for @weekdaySunday.
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get weekdaySunday;

  /// No description provided for @weekdayMonday.
  ///
  /// In es, this message translates to:
  /// **'Lunes'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In es, this message translates to:
  /// **'Martes'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In es, this message translates to:
  /// **'Miércoles'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In es, this message translates to:
  /// **'Jueves'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In es, this message translates to:
  /// **'Viernes'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In es, this message translates to:
  /// **'Sábado'**
  String get weekdaySaturday;

  /// No description provided for @errorConflict.
  ///
  /// In es, this message translates to:
  /// **'Ese horario ya está ocupado.'**
  String get errorConflict;

  /// No description provided for @errorPermission.
  ///
  /// In es, this message translates to:
  /// **'Tu rol no permite esta acción.'**
  String get errorPermission;

  /// No description provided for @errorNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró el registro.'**
  String get errorNotFound;

  /// No description provided for @errorSave.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar. Intenta de nuevo.'**
  String get errorSave;

  /// No description provided for @errorBackend.
  ///
  /// In es, this message translates to:
  /// **'No se pudo conectar con el servidor de disponibilidad.'**
  String get errorBackend;

  /// No description provided for @billingTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu plan'**
  String get billingTitle;

  /// No description provided for @billingRenewsOn.
  ///
  /// In es, this message translates to:
  /// **'Se renueva el {date}'**
  String billingRenewsOn(String date);

  /// No description provided for @billingExpiresOn.
  ///
  /// In es, this message translates to:
  /// **'Vence el {date}'**
  String billingExpiresOn(String date);

  /// No description provided for @billingNoRenewal.
  ///
  /// In es, this message translates to:
  /// **'Renovación desactivada'**
  String get billingNoRenewal;

  /// No description provided for @billingStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get billingStatusActive;

  /// No description provided for @billingStatusGrace.
  ///
  /// In es, this message translates to:
  /// **'Periodo de gracia'**
  String get billingStatusGrace;

  /// No description provided for @billingStatusPaused.
  ///
  /// In es, this message translates to:
  /// **'En pausa'**
  String get billingStatusPaused;

  /// No description provided for @billingStatusCanceled.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get billingStatusCanceled;

  /// No description provided for @billingStatusExpired.
  ///
  /// In es, this message translates to:
  /// **'Vencido'**
  String get billingStatusExpired;

  /// No description provided for @billingStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de pago'**
  String get billingStatusPending;

  /// No description provided for @billingManage.
  ///
  /// In es, this message translates to:
  /// **'Administrar en Google Play'**
  String get billingManage;

  /// No description provided for @billingUpgrade.
  ///
  /// In es, this message translates to:
  /// **'Mejorar plan'**
  String get billingUpgrade;

  /// No description provided for @billingCurrent.
  ///
  /// In es, this message translates to:
  /// **'Plan actual'**
  String get billingCurrent;

  /// No description provided for @billingChoose.
  ///
  /// In es, this message translates to:
  /// **'Elegir plan'**
  String get billingChoose;

  /// No description provided for @billingRestore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar compras'**
  String get billingRestore;

  /// No description provided for @billingPriceUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Precio no disponible'**
  String get billingPriceUnavailable;

  /// No description provided for @billingPurchasePending.
  ///
  /// In es, this message translates to:
  /// **'Procesando la compra...'**
  String get billingPurchasePending;

  /// No description provided for @billingPurchaseSuccess.
  ///
  /// In es, this message translates to:
  /// **'¡Listo! Tu plan ya está activo.'**
  String get billingPurchaseSuccess;

  /// No description provided for @billingPurchaseError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la compra.'**
  String get billingPurchaseError;

  /// No description provided for @billingPurchaseWaiting.
  ///
  /// In es, this message translates to:
  /// **'Tu pago está pendiente de confirmación por Google Play. El plan se activará en cuanto se apruebe.'**
  String get billingPurchaseWaiting;

  /// No description provided for @billingPendingVerificationHelp.
  ///
  /// In es, this message translates to:
  /// **'Ya se cobró tu compra, pero no pudimos verificarla. Reintenta para activar el plan.'**
  String get billingPendingVerificationHelp;

  /// No description provided for @billingRetryVerification.
  ///
  /// In es, this message translates to:
  /// **'Reintentar verificación'**
  String get billingRetryVerification;

  /// No description provided for @billingRestoreStarted.
  ///
  /// In es, this message translates to:
  /// **'Buscando compras anteriores...'**
  String get billingRestoreStarted;

  /// No description provided for @billingRestoreEmpty.
  ///
  /// In es, this message translates to:
  /// **'No encontramos compras para restaurar.'**
  String get billingRestoreEmpty;

  /// No description provided for @billingStoreUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Google Play no está disponible en este dispositivo.'**
  String get billingStoreUnavailable;

  /// No description provided for @billingUsageStaff.
  ///
  /// In es, this message translates to:
  /// **'Empleados: {used} de {limit}'**
  String billingUsageStaff(int used, String limit);

  /// No description provided for @billingUsageAppointments.
  ///
  /// In es, this message translates to:
  /// **'Citas este mes: {used} de {limit}'**
  String billingUsageAppointments(int used, String limit);

  /// No description provided for @billingUsageOnlineBookings.
  ///
  /// In es, this message translates to:
  /// **'Enlace público este mes: {used} de {limit}'**
  String billingUsageOnlineBookings(int used, String limit);

  /// No description provided for @billingOnlineBookings.
  ///
  /// In es, this message translates to:
  /// **'Reservas en línea'**
  String get billingOnlineBookings;

  /// No description provided for @billingMonthlyLimit.
  ///
  /// In es, this message translates to:
  /// **'{limit} / mes'**
  String billingMonthlyLimit(String limit);

  /// No description provided for @billingUnlimited.
  ///
  /// In es, this message translates to:
  /// **'Ilimitado'**
  String get billingUnlimited;

  /// No description provided for @billingFeatureNoAds.
  ///
  /// In es, this message translates to:
  /// **'Sin anuncios'**
  String get billingFeatureNoAds;

  /// No description provided for @planLimitTitle.
  ///
  /// In es, this message translates to:
  /// **'Límite de tu plan'**
  String get planLimitTitle;

  /// No description provided for @planLimitStaff.
  ///
  /// In es, this message translates to:
  /// **'Tu plan permite {limit} empleado(s) activo(s).'**
  String planLimitStaff(String limit);

  /// No description provided for @planLimitAppointments.
  ///
  /// In es, this message translates to:
  /// **'Llegaste al límite de {limit} citas este mes.'**
  String planLimitAppointments(String limit);

  /// No description provided for @planLimitOnlineBookings.
  ///
  /// In es, this message translates to:
  /// **'Llegaste al límite de {limit} reservas en línea este mes.'**
  String planLimitOnlineBookings(String limit);

  /// No description provided for @planLimitGeneric.
  ///
  /// In es, this message translates to:
  /// **'Alcanzaste el límite de tu plan actual.'**
  String get planLimitGeneric;

  /// No description provided for @planLimitUpgrade.
  ///
  /// In es, this message translates to:
  /// **'Ver planes'**
  String get planLimitUpgrade;

  /// No description provided for @planLimitLater.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get planLimitLater;

  /// No description provided for @navIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get navIncome;

  /// No description provided for @incomeToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get incomeToday;

  /// No description provided for @incomeWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get incomeWeek;

  /// No description provided for @incomeMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get incomeMonth;

  /// No description provided for @incomeTotal.
  ///
  /// In es, this message translates to:
  /// **'Total cobrado'**
  String get incomeTotal;

  /// No description provided for @incomeCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cita cobrada} other{{count} citas cobradas}}'**
  String incomeCount(int count);

  /// No description provided for @incomeAverage.
  ///
  /// In es, this message translates to:
  /// **'Ticket promedio'**
  String get incomeAverage;

  /// No description provided for @incomeByDay.
  ///
  /// In es, this message translates to:
  /// **'Por día'**
  String get incomeByDay;

  /// No description provided for @incomeByMethod.
  ///
  /// In es, this message translates to:
  /// **'Por medio de pago'**
  String get incomeByMethod;

  /// No description provided for @incomeByService.
  ///
  /// In es, this message translates to:
  /// **'Por servicio'**
  String get incomeByService;

  /// No description provided for @incomeByStaff.
  ///
  /// In es, this message translates to:
  /// **'Por empleado'**
  String get incomeByStaff;

  /// No description provided for @incomeEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay cobros en este periodo.'**
  String get incomeEmpty;

  /// No description provided for @incomeEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Abre una cita y usa «Registrar pago» para anotar lo que cobraste.'**
  String get incomeEmptyHint;

  /// No description provided for @incomeMethodCash.
  ///
  /// In es, this message translates to:
  /// **'Efectivo'**
  String get incomeMethodCash;

  /// No description provided for @incomeMethodTransfer.
  ///
  /// In es, this message translates to:
  /// **'Transferencia'**
  String get incomeMethodTransfer;

  /// No description provided for @incomeMethodCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta'**
  String get incomeMethodCard;

  /// No description provided for @incomeMethodOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get incomeMethodOther;

  /// No description provided for @incomeMethodNone.
  ///
  /// In es, this message translates to:
  /// **'Sin medio'**
  String get incomeMethodNone;

  /// No description provided for @paymentTitle.
  ///
  /// In es, this message translates to:
  /// **'Pago'**
  String get paymentTitle;

  /// No description provided for @paymentStatusPaid.
  ///
  /// In es, this message translates to:
  /// **'Cobrada'**
  String get paymentStatusPaid;

  /// No description provided for @paymentStatusUnpaid.
  ///
  /// In es, this message translates to:
  /// **'Sin cobrar'**
  String get paymentStatusUnpaid;

  /// No description provided for @paymentRegister.
  ///
  /// In es, this message translates to:
  /// **'Registrar pago'**
  String get paymentRegister;

  /// No description provided for @paymentUndo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer cobro'**
  String get paymentUndo;

  /// No description provided for @paymentAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Importe'**
  String get paymentAmountLabel;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In es, this message translates to:
  /// **'Medio de pago'**
  String get paymentMethodLabel;

  /// No description provided for @paymentSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar pago'**
  String get paymentSave;

  /// No description provided for @paymentSaved.
  ///
  /// In es, this message translates to:
  /// **'Pago registrado.'**
  String get paymentSaved;

  /// No description provided for @paymentUndone.
  ///
  /// In es, this message translates to:
  /// **'Cobro eliminado.'**
  String get paymentUndone;

  /// No description provided for @paymentAmountInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un importe mayor que cero.'**
  String get paymentAmountInvalid;

  /// No description provided for @paymentMethodRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige un medio de pago.'**
  String get paymentMethodRequired;

  /// No description provided for @paymentPaidOn.
  ///
  /// In es, this message translates to:
  /// **'Cobrada el {date}'**
  String paymentPaidOn(String date);

  /// No description provided for @publicLinkTitle.
  ///
  /// In es, this message translates to:
  /// **'Reservas en línea'**
  String get publicLinkTitle;

  /// No description provided for @publicLinkIntro.
  ///
  /// In es, this message translates to:
  /// **'Tus clientes reservan solos desde este enlace, sin instalar la app y sin llamarte.'**
  String get publicLinkIntro;

  /// No description provided for @publicLinkEnabled.
  ///
  /// In es, this message translates to:
  /// **'Enlace de reservas activo'**
  String get publicLinkEnabled;

  /// No description provided for @publicLinkEnabledHint.
  ///
  /// In es, this message translates to:
  /// **'Cualquiera con el enlace puede ver tus servicios y agendar.'**
  String get publicLinkEnabledHint;

  /// No description provided for @publicLinkDisabledHint.
  ///
  /// In es, this message translates to:
  /// **'El enlace está apagado: nadie puede reservar por internet.'**
  String get publicLinkDisabledHint;

  /// No description provided for @publicLinkCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar enlace'**
  String get publicLinkCopy;

  /// No description provided for @publicLinkCopied.
  ///
  /// In es, this message translates to:
  /// **'Enlace copiado.'**
  String get publicLinkCopied;

  /// No description provided for @publicLinkShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get publicLinkShare;

  /// No description provided for @publicLinkShareText.
  ///
  /// In es, this message translates to:
  /// **'Reserva tu cita en {business} aquí: {link}'**
  String publicLinkShareText(String business, String link);

  /// No description provided for @publicLinkOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir en el navegador'**
  String get publicLinkOpen;

  /// No description provided for @publicLinkQrHint.
  ///
  /// In es, this message translates to:
  /// **'Imprime este código y ponlo en tu local'**
  String get publicLinkQrHint;

  /// No description provided for @publicLinkQuotaExhausted.
  ///
  /// In es, this message translates to:
  /// **'Alcanzaste las reservas en línea de este mes: tus clientes no podrán reservar hasta el próximo.'**
  String get publicLinkQuotaExhausted;

  /// No description provided for @publicLinkHowToTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo usarlo'**
  String get publicLinkHowToTitle;

  /// No description provided for @publicLinkHowTo.
  ///
  /// In es, this message translates to:
  /// **'Comparte el enlace por WhatsApp, redes o en tu perfil de Google. Las citas llegan confirmadas a tu agenda con el nombre y el teléfono del cliente.'**
  String get publicLinkHowTo;

  /// No description provided for @businessAddressLabel.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get businessAddressLabel;

  /// No description provided for @businessAddressHint.
  ///
  /// In es, this message translates to:
  /// **'Se muestra a tus clientes en el enlace de reservas'**
  String get businessAddressHint;

  /// No description provided for @businessAddressShownOnLink.
  ///
  /// In es, this message translates to:
  /// **'Visible en el enlace de reservas'**
  String get businessAddressShownOnLink;

  /// No description provided for @authJustBooking.
  ///
  /// In es, this message translates to:
  /// **'Solo quiero reservar una cita'**
  String get authJustBooking;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authOrEmail.
  ///
  /// In es, this message translates to:
  /// **'o con tu correo'**
  String get authOrEmail;

  /// No description provided for @authGoogleEmailExists.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes una cuenta con ese correo. Entra con tu contraseña.'**
  String get authGoogleEmailExists;

  /// No description provided for @authGoogleUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión con Google. Inténtalo de nuevo en un momento.'**
  String get authGoogleUnavailable;

  /// No description provided for @clientBookingTitle.
  ///
  /// In es, this message translates to:
  /// **'Reservar una cita'**
  String get clientBookingTitle;

  /// No description provided for @clientBookingIntro.
  ///
  /// In es, this message translates to:
  /// **'Reserva sin crear cuenta. Pega el enlace que te compartió el negocio y te llevamos a su página de reservas.'**
  String get clientBookingIntro;

  /// No description provided for @clientBookingLinkLabel.
  ///
  /// In es, this message translates to:
  /// **'Enlace o código del negocio'**
  String get clientBookingLinkLabel;

  /// No description provided for @clientBookingLinkHint.
  ///
  /// In es, this message translates to:
  /// **'https://…/r/mi-barberia'**
  String get clientBookingLinkHint;

  /// No description provided for @clientBookingOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir reservas'**
  String get clientBookingOpen;

  /// No description provided for @clientBookingInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ese enlace no parece de reservas. Pídele al negocio el suyo.'**
  String get clientBookingInvalid;

  /// No description provided for @clientBookingLast.
  ///
  /// In es, this message translates to:
  /// **'Última reserva'**
  String get clientBookingLast;

  /// No description provided for @clientBookingWhy.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes el enlace? Pídeselo al negocio. Si ya reservaste, tu enlace personal aparece arriba.'**
  String get clientBookingWhy;
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
