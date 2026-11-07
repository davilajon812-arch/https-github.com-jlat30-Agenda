// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AgendaPro';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonSoon => 'Coming soon';

  @override
  String get authSignInTitle => 'Welcome back';

  @override
  String get authSignInSubtitle => 'Sign in to manage your schedule.';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authRegisterTitle => 'Create your account';

  @override
  String get authRegisterSubtitle =>
      'Start organizing your business appointments.';

  @override
  String get authFullName => 'Full name';

  @override
  String get authPhoneOptional => 'Phone (optional)';

  @override
  String get authRegister => 'Sign up';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authResetTitle => 'Reset password';

  @override
  String get authResetSubtitle =>
      'We will email you a link to reset your password.';

  @override
  String get authSendResetLink => 'Send link';

  @override
  String get authResetSent =>
      'Check your inbox: we sent a password reset link.';

  @override
  String get authConfirmEmailSent =>
      'We emailed you a confirmation link. Confirm your account, then sign in.';

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationEmail => 'Enter a valid email';

  @override
  String get validationPasswordLength =>
      'Password must be at least 8 characters';

  @override
  String get validationNameLength => 'Name must be at least 3 characters';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorInvalidCredentials => 'Wrong email or password.';

  @override
  String get errorEmailNotConfirmed => 'Confirm your email before signing in.';

  @override
  String get errorEmailInUse => 'That email is already registered.';

  @override
  String get errorNetwork => 'No connection. Check your network and try again.';

  @override
  String get errorWeakPassword => 'That password is too weak.';

  @override
  String get onboardingTitle => 'Tell us about your business';

  @override
  String get onboardingSubtitle =>
      'We use these details to set up your schedule.';

  @override
  String get onboardingBusinessName => 'Business name';

  @override
  String get onboardingIndustry => 'Industry';

  @override
  String get onboardingCountry => 'Country';

  @override
  String get onboardingCurrency => 'Currency';

  @override
  String get onboardingTimezone => 'Time zone';

  @override
  String get onboardingCreate => 'Create business';

  @override
  String get onboardingNameRequired => 'Enter your business name';

  @override
  String get industryBarberia => 'Barbershop';

  @override
  String get industrySalon => 'Beauty salon';

  @override
  String get industryTaller => 'Auto repair shop';

  @override
  String get industryVeterinaria => 'Veterinary clinic';

  @override
  String get industryGimnasio => 'Gym';

  @override
  String get industryAcademia => 'Academy';

  @override
  String get industryFotografia => 'Photography';

  @override
  String get industryOtro => 'Other';

  @override
  String get navAppointments => 'Schedule';

  @override
  String get navClients => 'Clients';

  @override
  String get navPlan => 'Plan';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeTodayEmpty => 'Your daily schedule will show up here.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSpanish => 'Spanish';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsBusiness => 'Business';

  @override
  String get billingCurrentPlan => 'Current plan';

  @override
  String get billingPlanFree => 'Free';

  @override
  String get billingSoon => 'Paid plans arrive in Phase 3.';

  @override
  String get placeholderPhaseTwo => 'This section opens in Phase 2.';

  @override
  String get configMissingTitle => 'Missing configuration';

  @override
  String get configMissingMessage =>
      'Set SUPABASE_URL and SUPABASE_ANON_KEY when building the app (see README).';
}
