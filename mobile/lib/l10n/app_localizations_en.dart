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
  String get settingsPrivacy => 'Privacy policy';

  @override
  String get settingsTerms => 'Terms of service';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountMessage =>
      'Your account, business, clients, services, staff and appointments will be deleted. This cannot be undone.';

  @override
  String get deleteAccountConfirm => 'Delete permanently';

  @override
  String get deleteAccountSuccess => 'Your account was deleted.';

  @override
  String get deleteAccountError =>
      'We could not delete your account. Please try again.';

  @override
  String get businessManageTitle => 'My business';

  @override
  String get businessNameLabel => 'Business name';

  @override
  String get businessPhoneLabel => 'Business phone';

  @override
  String get businessEdit => 'Edit details';

  @override
  String get businessEditTitle => 'Business details';

  @override
  String get businessNewTitle => 'New business';

  @override
  String get businessSave => 'Save changes';

  @override
  String get businessCreate => 'Create business';

  @override
  String get businessSwitch => 'Your businesses';

  @override
  String get businessSwitchHint =>
      'Choose which business you want to work with.';

  @override
  String get businessAdd => 'Add business';

  @override
  String get businessAddProTitle => 'You need the Pro plan';

  @override
  String get businessAddProMessage =>
      'The Free plan allows a single business. With Pro you can manage several from the same account.';

  @override
  String get businessAddProAction => 'See plans';

  @override
  String get validationPhoneLength => 'The phone must have at least 6 digits';

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

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonClose => 'Close';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonAll => 'All';

  @override
  String commonMinutes(int count) {
    return '$count min';
  }

  @override
  String get statusPendiente => 'Pending';

  @override
  String get statusConfirmada => 'Confirmed';

  @override
  String get statusCompletada => 'Completed';

  @override
  String get statusCancelada => 'Canceled';

  @override
  String get statusNoAsistio => 'No-show';

  @override
  String get agendaToday => 'Today';

  @override
  String get agendaDay => 'Day';

  @override
  String get agendaWeek => 'Week';

  @override
  String get agendaEmptyDay => 'No appointments for this day.';

  @override
  String get agendaEmptyWeek => 'No appointments this week.';

  @override
  String get agendaNewAppointment => 'New appointment';

  @override
  String get agendaWhatsapp => 'Open WhatsApp';

  @override
  String agendaTotalDay(int count) {
    return '$count appointments';
  }

  @override
  String get appointmentDetailTitle => 'Appointment details';

  @override
  String get appointmentClient => 'Client';

  @override
  String get appointmentService => 'Service';

  @override
  String get appointmentStaff => 'Staff';

  @override
  String get appointmentWhen => 'Date and time';

  @override
  String get appointmentPrice => 'Price';

  @override
  String get appointmentNotes => 'Notes';

  @override
  String get appointmentChangeStatus => 'Change status';

  @override
  String get appointmentConfirm => 'Confirm';

  @override
  String get appointmentComplete => 'Mark as completed';

  @override
  String get appointmentNoShow => 'No-show';

  @override
  String get appointmentCancel => 'Cancel appointment';

  @override
  String get appointmentCancelReason => 'Reason (optional)';

  @override
  String get appointmentUpdated => 'Appointment updated';

  @override
  String get newAppointmentTitle => 'New appointment';

  @override
  String get newAppointmentClient => '1. Client';

  @override
  String get newAppointmentService => '2. Service';

  @override
  String get newAppointmentSlot => '3. Time';

  @override
  String get newAppointmentStaff => 'Staff';

  @override
  String get newAppointmentAnyStaff => 'Anyone';

  @override
  String get newAppointmentNoSlots => 'No free slots that day.';

  @override
  String get newAppointmentPickSlot => 'Pick a time for the service';

  @override
  String get newAppointmentCreated => 'Appointment created';

  @override
  String get newAppointmentNeedService => 'Pick a service to see time slots';

  @override
  String get newClientInline => 'New client';

  @override
  String get clientsTitle => 'Clients';

  @override
  String get clientsSearchHint => 'Search by name or phone';

  @override
  String get clientsEmpty => 'You have no clients yet.';

  @override
  String get clientNew => 'New client';

  @override
  String get clientName => 'Full name';

  @override
  String get clientPhone => 'Phone with country code';

  @override
  String get clientNotes => 'Notes';

  @override
  String get clientHistory => 'Visit history';

  @override
  String get clientNoVisits => 'No visits recorded.';

  @override
  String get clientSaved => 'Client saved';

  @override
  String get clientDeleteConfirm => 'Delete this client?';

  @override
  String get clientHasVisits => 'Cannot delete: the client has appointments.';

  @override
  String get servicesTitle => 'Services';

  @override
  String get servicesEmpty => 'Add your first service.';

  @override
  String get serviceNew => 'New service';

  @override
  String get serviceName => 'Service name';

  @override
  String get serviceDuration => 'Duration (minutes)';

  @override
  String get servicePrice => 'Price';

  @override
  String get serviceSaved => 'Service saved';

  @override
  String get servicesManagement => 'Services';

  @override
  String get staffTitle => 'Staff';

  @override
  String get staffEmpty => 'Add your first staff member.';

  @override
  String get staffNew => 'New staff member';

  @override
  String get staffName => 'Staff name';

  @override
  String get staffSaved => 'Staff saved';

  @override
  String get staffManagement => 'Staff and schedules';

  @override
  String get staffScheduleTitle => 'Weekly schedule';

  @override
  String get staffScheduleEmpty =>
      'No schedule: they will not show as available.';

  @override
  String get staffScheduleSaved => 'Schedule saved';

  @override
  String get staffBlocksTitle => 'Blocks';

  @override
  String get staffBlocksEmpty => 'No vacations or breaks.';

  @override
  String get staffBlockNew => 'New block';

  @override
  String get staffBlockKind => 'Type';

  @override
  String get staffBlockVacation => 'Vacation';

  @override
  String get staffBlockBreak => 'Break';

  @override
  String get staffBlockOther => 'Other';

  @override
  String get staffBlockReason => 'Reason (optional)';

  @override
  String get staffBlockRange => 'From / to';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get errorConflict => 'That time slot is already taken.';

  @override
  String get errorPermission => 'Your role cannot perform this action.';

  @override
  String get errorNotFound => 'Record not found.';

  @override
  String get errorSave => 'Could not save. Please try again.';

  @override
  String get errorBackend => 'Could not reach the availability server.';

  @override
  String get billingTitle => 'Your plan';

  @override
  String billingRenewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String billingExpiresOn(String date) {
    return 'Expires on $date';
  }

  @override
  String get billingNoRenewal => 'Auto-renewal off';

  @override
  String get billingStatusActive => 'Active';

  @override
  String get billingStatusGrace => 'Grace period';

  @override
  String get billingStatusPaused => 'Paused';

  @override
  String get billingStatusCanceled => 'Canceled';

  @override
  String get billingStatusExpired => 'Expired';

  @override
  String get billingStatusPending => 'Payment pending';

  @override
  String get billingManage => 'Manage in Google Play';

  @override
  String get billingUpgrade => 'Upgrade';

  @override
  String get billingCurrent => 'Current plan';

  @override
  String get billingChoose => 'Choose plan';

  @override
  String get billingRestore => 'Restore purchases';

  @override
  String get billingPriceUnavailable => 'Price unavailable';

  @override
  String get billingPurchasePending => 'Processing your purchase...';

  @override
  String get billingPurchaseSuccess => 'Done! Your plan is active.';

  @override
  String get billingPurchaseError => 'The purchase could not be completed.';

  @override
  String get billingPurchaseWaiting =>
      'Your payment is awaiting confirmation from Google Play. The plan activates as soon as it is approved.';

  @override
  String get billingPendingVerificationHelp =>
      'Your purchase was charged but we could not verify it. Retry to activate the plan.';

  @override
  String get billingRetryVerification => 'Retry verification';

  @override
  String get billingRestoreStarted => 'Looking for previous purchases...';

  @override
  String get billingRestoreEmpty => 'No purchases to restore.';

  @override
  String get billingStoreUnavailable =>
      'Google Play is not available on this device.';

  @override
  String billingUsageStaff(int used, String limit) {
    return 'Staff: $used of $limit';
  }

  @override
  String billingUsageAppointments(int used, String limit) {
    return 'Appointments this month: $used of $limit';
  }

  @override
  String billingUsageMessages(int used, String limit) {
    return 'Messages this month: $used of $limit';
  }

  @override
  String get billingUnlimited => 'Unlimited';

  @override
  String get billingFeatureReminders => 'Automatic reminders';

  @override
  String get billingFeatureReports => 'Advanced reports';

  @override
  String get billingFeatureBranding => 'Custom branding';

  @override
  String get planLimitTitle => 'Plan limit';

  @override
  String planLimitStaff(String limit) {
    return 'Your plan allows $limit active staff member(s).';
  }

  @override
  String planLimitAppointments(String limit) {
    return 'You reached the $limit appointment limit this month.';
  }

  @override
  String get planLimitGeneric => 'You reached your current plan limit.';

  @override
  String get planLimitUpgrade => 'See plans';

  @override
  String get planLimitLater => 'Not now';

  @override
  String get navIncome => 'Income';

  @override
  String get incomeToday => 'Today';

  @override
  String get incomeWeek => 'Week';

  @override
  String get incomeMonth => 'Month';

  @override
  String get incomeTotal => 'Collected';

  @override
  String incomeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paid visits',
      one: '1 paid visit',
    );
    return '$_temp0';
  }

  @override
  String get incomeAverage => 'Average ticket';

  @override
  String get incomeByDay => 'By day';

  @override
  String get incomeByMethod => 'By payment method';

  @override
  String get incomeByService => 'By service';

  @override
  String get incomeByStaff => 'By staff';

  @override
  String get incomeEmpty => 'No payments recorded in this period.';

  @override
  String get incomeEmptyHint =>
      'Open an appointment and use \"Register payment\" to log what you collected.';

  @override
  String get incomeMethodCash => 'Cash';

  @override
  String get incomeMethodTransfer => 'Transfer';

  @override
  String get incomeMethodCard => 'Card';

  @override
  String get incomeMethodOther => 'Other';

  @override
  String get incomeMethodNone => 'No method';

  @override
  String get paymentTitle => 'Payment';

  @override
  String get paymentStatusPaid => 'Paid';

  @override
  String get paymentStatusUnpaid => 'Unpaid';

  @override
  String get paymentRegister => 'Register payment';

  @override
  String get paymentUndo => 'Undo payment';

  @override
  String get paymentAmountLabel => 'Amount';

  @override
  String get paymentMethodLabel => 'Payment method';

  @override
  String get paymentSave => 'Save payment';

  @override
  String get paymentSaved => 'Payment recorded.';

  @override
  String get paymentUndone => 'Payment removed.';

  @override
  String get paymentAmountInvalid => 'Enter an amount greater than zero.';

  @override
  String get paymentMethodRequired => 'Pick a payment method.';

  @override
  String paymentPaidOn(String date) {
    return 'Paid on $date';
  }

  @override
  String get publicLinkTitle => 'Online booking';

  @override
  String get publicLinkIntro =>
      'Your customers book by themselves from this link, without installing the app or calling you.';

  @override
  String get publicLinkEnabled => 'Booking link active';

  @override
  String get publicLinkEnabledHint =>
      'Anyone with the link can see your services and book.';

  @override
  String get publicLinkDisabledHint =>
      'The link is off: nobody can book online.';

  @override
  String get publicLinkCopy => 'Copy link';

  @override
  String get publicLinkCopied => 'Link copied.';

  @override
  String get publicLinkShare => 'Share';

  @override
  String publicLinkShareText(String business, String link) {
    return 'Book your appointment at $business here: $link';
  }

  @override
  String get publicLinkOpen => 'Open in browser';

  @override
  String get publicLinkQrHint => 'Print this code and put it in your shop';

  @override
  String get publicLinkHowToTitle => 'How to use it';

  @override
  String get publicLinkHowTo =>
      'Share the link on WhatsApp, social media or your Google profile. Bookings arrive confirmed in your calendar with the customer\'s name and phone.';

  @override
  String get businessAddressLabel => 'Address';

  @override
  String get businessAddressHint =>
      'Shown to your customers on the booking link';

  @override
  String get businessAddressShownOnLink => 'Visible on the booking link';

  @override
  String get authJustBooking => 'I just want to book an appointment';

  @override
  String get clientBookingTitle => 'Book an appointment';

  @override
  String get clientBookingIntro =>
      'Book without creating an account. Paste the link the business shared with you and we\'ll take you to their booking page.';

  @override
  String get clientBookingLinkLabel => 'Business link or code';

  @override
  String get clientBookingLinkHint => 'https://…/r/my-barbershop';

  @override
  String get clientBookingOpen => 'Open booking';

  @override
  String get clientBookingInvalid =>
      'That doesn\'t look like a booking link. Ask the business for theirs.';

  @override
  String get clientBookingLast => 'Last booking';

  @override
  String get clientBookingWhy =>
      'Don\'t have the link? Ask the business. If you already booked, your personal link shows above.';
}
