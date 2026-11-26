import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// El usuario tenía una cuenta creada con correo y contraseña; Google no se
/// enlaza solo para evitar que alguien entre a una cuenta ajena.
class GoogleSignInEmailInUse implements Exception {
  const GoogleSignInEmailInUse();
}

/// Google autenticó al usuario pero no devolvió idToken (configuración
/// incompleta del proyecto).
class GoogleSignInTokenUnavailable implements Exception {
  const GoogleSignInTokenUnavailable();
}

/// Operaciones de autenticación contra Supabase Auth.
class AuthRepository {
  AuthRepository(this._client);

  /// `initialize()` debe ocurrir una sola vez por proceso.
  static Future<void>? _googleInitialization;

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Inicia sesión con la cuenta de Google del teléfono.
  ///
  /// Devuelve `false` si el usuario cerró el selector de cuentas (no es un
  /// error que merezca un mensaje). La cuenta creada aquí queda sin negocio:
  /// `AppGate` manda al onboarding igual que con el registro por correo.
  Future<bool> signInWithGoogle({required String serverClientId}) async {
    final googleSignIn = GoogleSignIn.instance;

    try {
      await (_googleInitialization ??=
          googleSignIn.initialize(serverClientId: serverClientId));
    } catch (_) {
      // Un fallo de configuración no debe quedar cacheado: el siguiente
      // intento vuelve a inicializar.
      _googleInitialization = null;
      rethrow;
    }

    final GoogleSignInAccount account;
    try {
      account = await googleSignIn.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const GoogleSignInTokenUnavailable();
    }

    try {
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on AuthException catch (error) {
      if (_isExistingAccount(error)) throw const GoogleSignInEmailInUse();
      rethrow;
    }

    return true;
  }

  /// Supabase rechaza el idToken de Google cuando ese correo ya tiene cuenta
  /// con contraseña y el enlazado automático está apagado.
  bool _isExistingAccount(AuthException error) {
    final code = (error.code ?? '').toLowerCase();
    final message = error.message.toLowerCase();
    return code == 'email_exists' ||
        code == 'identity_already_exists' ||
        message.contains('already registered') ||
        message.contains('already exists') ||
        message.contains('already linked');
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String locale = 'es',
  }) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        'locale': locale,
      },
    );
  }

  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() async {
    // Sin esto el teléfono recuerda la cuenta elegida y el próximo "Continuar
    // con Google" entra directo, sin dejar cambiar de cuenta.
    if (_googleInitialization != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Cerrar la sesión local de Google nunca debe impedir salir de la app.
      }
    }
    await _client.auth.signOut();
  }
}
