import 'package:citurno/core/providers/app_providers.dart';
import 'package:citurno/features/auth/data/auth_repository.dart';
import 'package:citurno/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../test_helpers.dart';

class _FakeAuthRepository implements AuthRepository {
  int googleCalls = 0;
  String? lastClientId;

  @override
  Session? get currentSession => null;

  @override
  User? get currentUser => null;

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String locale = 'es',
  }) async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> signInWithGoogle({required String serverClientId}) async {
    googleCalls++;
    lastClientId = serverClientId;
    return false;
  }
}

void main() {
  testWidgets('la pantalla de login muestra el formulario', (tester) async {
    await tester.pumpWidget(wrapWidget(const LoginScreen()));

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Correo electrónico'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });

  testWidgets('valida el correo antes de enviar', (tester) async {
    await tester.pumpWidget(wrapWidget(const LoginScreen()));

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Este campo es obligatorio'), findsNWidgets(2));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico'),
      'no-es-un-correo',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Ingresa un correo válido'), findsOneWidget);
  });

  testWidgets('sin Client ID Web no ofrece el acceso con Google',
      (tester) async {
    await tester.pumpWidget(wrapWidget(const LoginScreen()));

    expect(find.text('Continuar con Google'), findsNothing);
  });

  testWidgets('con Client ID Web el botón inicia sesión con Google',
      (tester) async {
    final repository = _FakeAuthRepository();

    await tester.pumpWidget(
      wrapWidget(
        const LoginScreen(),
        config: testAppConfig(googleWebClientId: 'web-client-id'),
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      ),
    );

    expect(find.text('o con tu correo'), findsOneWidget);
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();

    expect(repository.googleCalls, 1);
    expect(repository.lastClientId, 'web-client-id');
  });
}
