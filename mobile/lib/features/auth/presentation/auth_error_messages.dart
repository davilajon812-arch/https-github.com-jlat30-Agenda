import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';

/// Traduce los errores de Supabase Auth a mensajes de la interfaz.
String authErrorMessage(AppLocalizations l10n, Object error) {
  if (error is GoogleSignInEmailInUse) {
    return l10n.authGoogleEmailExists;
  }
  if (error is GoogleSignInTokenUnavailable) {
    return l10n.authGoogleUnavailable;
  }
  if (error is GoogleSignInException) {
    // El detalle (SHA-1 equivocado, consentimiento en pruebas…) no se muestra
    // al usuario, pero deja rastro al depurar en el teléfono.
    debugPrint('Google Sign-In: ${error.code} ${error.description}');
    return l10n.authGoogleUnavailable;
  }
  if (error is AuthException) {
    final code = (error.code ?? '').toLowerCase();
    final message = error.message.toLowerCase();

    if (code == 'email_exists' || code == 'identity_already_exists') {
      return l10n.authGoogleEmailExists;
    }
    if (code == 'invalid_credentials' || message.contains('invalid login')) {
      return l10n.errorInvalidCredentials;
    }
    if (code == 'email_not_confirmed' || message.contains('not confirmed')) {
      return l10n.errorEmailNotConfirmed;
    }
    if (code == 'user_already_exists' ||
        message.contains('already registered')) {
      return l10n.errorEmailInUse;
    }
    if (code == 'weak_password') {
      return l10n.errorWeakPassword;
    }
    if (error.statusCode == '0') {
      return l10n.errorNetwork;
    }
    return l10n.errorGeneric;
  }
  if (error is SocketException || error is TimeoutException) {
    return l10n.errorNetwork;
  }
  return l10n.errorGeneric;
}
