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

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonAdd => 'Agregar';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get commonAll => 'Todos';

  @override
  String commonMinutes(int count) {
    return '$count min';
  }

  @override
  String get statusPendiente => 'Pendiente';

  @override
  String get statusConfirmada => 'Confirmada';

  @override
  String get statusCompletada => 'Completada';

  @override
  String get statusCancelada => 'Cancelada';

  @override
  String get statusNoAsistio => 'No asistió';

  @override
  String get agendaToday => 'Hoy';

  @override
  String get agendaDay => 'Día';

  @override
  String get agendaWeek => 'Semana';

  @override
  String get agendaEmptyDay => 'No hay citas para este día.';

  @override
  String get agendaEmptyWeek => 'No hay citas esta semana.';

  @override
  String get agendaNewAppointment => 'Nueva cita';

  @override
  String get agendaWhatsapp => 'Abrir WhatsApp';

  @override
  String agendaTotalDay(int count) {
    return '$count citas';
  }

  @override
  String get appointmentDetailTitle => 'Detalle de la cita';

  @override
  String get appointmentClient => 'Cliente';

  @override
  String get appointmentService => 'Servicio';

  @override
  String get appointmentStaff => 'Empleado';

  @override
  String get appointmentWhen => 'Fecha y hora';

  @override
  String get appointmentPrice => 'Precio';

  @override
  String get appointmentNotes => 'Notas';

  @override
  String get appointmentChangeStatus => 'Cambiar estado';

  @override
  String get appointmentConfirm => 'Confirmar';

  @override
  String get appointmentComplete => 'Marcar completada';

  @override
  String get appointmentNoShow => 'No asistió';

  @override
  String get appointmentCancel => 'Cancelar cita';

  @override
  String get appointmentCancelReason => 'Motivo (opcional)';

  @override
  String get appointmentUpdated => 'Cita actualizada';

  @override
  String get newAppointmentTitle => 'Nueva cita';

  @override
  String get newAppointmentClient => '1. Cliente';

  @override
  String get newAppointmentService => '2. Servicio';

  @override
  String get newAppointmentSlot => '3. Horario';

  @override
  String get newAppointmentStaff => 'Empleado';

  @override
  String get newAppointmentAnyStaff => 'Cualquiera';

  @override
  String get newAppointmentNoSlots => 'No hay horarios libres ese día.';

  @override
  String get newAppointmentPickSlot => 'Elige el horario del servicio';

  @override
  String get newAppointmentCreated => 'Cita creada';

  @override
  String get newAppointmentNeedService => 'Elige un servicio para ver horarios';

  @override
  String get newClientInline => 'Cliente nuevo';

  @override
  String get clientsTitle => 'Clientes';

  @override
  String get clientsSearchHint => 'Buscar por nombre o teléfono';

  @override
  String get clientsEmpty => 'Aún no tienes clientes registrados.';

  @override
  String get clientNew => 'Nuevo cliente';

  @override
  String get clientName => 'Nombre completo';

  @override
  String get clientPhone => 'Teléfono con código de país';

  @override
  String get clientNotes => 'Notas';

  @override
  String get clientHistory => 'Historial de visitas';

  @override
  String get clientNoVisits => 'Sin visitas registradas.';

  @override
  String get clientSaved => 'Cliente guardado';

  @override
  String get clientDeleteConfirm => '¿Eliminar este cliente?';

  @override
  String get clientHasVisits =>
      'No se puede eliminar: tiene citas registradas.';

  @override
  String get servicesTitle => 'Servicios';

  @override
  String get servicesEmpty => 'Agrega tu primer servicio.';

  @override
  String get serviceNew => 'Nuevo servicio';

  @override
  String get serviceName => 'Nombre del servicio';

  @override
  String get serviceDuration => 'Duración (minutos)';

  @override
  String get servicePrice => 'Precio';

  @override
  String get serviceSaved => 'Servicio guardado';

  @override
  String get servicesManagement => 'Servicios';

  @override
  String get staffTitle => 'Empleados';

  @override
  String get staffEmpty => 'Agrega a tu primer empleado.';

  @override
  String get staffNew => 'Nuevo empleado';

  @override
  String get staffName => 'Nombre del empleado';

  @override
  String get staffSaved => 'Empleado guardado';

  @override
  String get staffManagement => 'Empleados y horarios';

  @override
  String get staffScheduleTitle => 'Horario semanal';

  @override
  String get staffScheduleEmpty => 'Sin horario: no aparecerá disponible.';

  @override
  String get staffScheduleSaved => 'Horario guardado';

  @override
  String get staffBlocksTitle => 'Bloqueos';

  @override
  String get staffBlocksEmpty => 'Sin vacaciones ni descansos.';

  @override
  String get staffBlockNew => 'Nuevo bloqueo';

  @override
  String get staffBlockKind => 'Tipo';

  @override
  String get staffBlockVacation => 'Vacaciones';

  @override
  String get staffBlockBreak => 'Descanso';

  @override
  String get staffBlockOther => 'Otro';

  @override
  String get staffBlockReason => 'Motivo (opcional)';

  @override
  String get staffBlockRange => 'Desde / hasta';

  @override
  String get weekdaySunday => 'Domingo';

  @override
  String get weekdayMonday => 'Lunes';

  @override
  String get weekdayTuesday => 'Martes';

  @override
  String get weekdayWednesday => 'Miércoles';

  @override
  String get weekdayThursday => 'Jueves';

  @override
  String get weekdayFriday => 'Viernes';

  @override
  String get weekdaySaturday => 'Sábado';

  @override
  String get errorConflict => 'Ese horario ya está ocupado.';

  @override
  String get errorPermission => 'Tu rol no permite esta acción.';

  @override
  String get errorNotFound => 'No se encontró el registro.';

  @override
  String get errorSave => 'No se pudo guardar. Intenta de nuevo.';

  @override
  String get errorBackend =>
      'No se pudo conectar con el servidor de disponibilidad.';
}
