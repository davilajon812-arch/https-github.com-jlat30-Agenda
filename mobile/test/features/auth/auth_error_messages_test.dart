import 'package:agenda_pro/features/auth/data/auth_repository.dart';
import 'package:agenda_pro/features/auth/presentation/auth_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers.dart';

void main() {
  final l10n = spanishLocalizations();

  test('un correo ya registrado invita a entrar con contraseña', () {
    expect(
      authErrorMessage(l10n, const GoogleSignInEmailInUse()),
      l10n.authGoogleEmailExists,
    );
  });

  test('un idToken ausente se reporta como Google no disponible', () {
    expect(
      authErrorMessage(l10n, const GoogleSignInTokenUnavailable()),
      l10n.authGoogleUnavailable,
    );
  });
}
