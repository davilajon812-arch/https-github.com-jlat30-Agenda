import 'package:agenda_pro/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers.dart';

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
}
