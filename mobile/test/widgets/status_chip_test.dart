import 'package:turnia/features/appointments/domain/appointment.dart';
import 'package:turnia/features/appointments/presentation/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('StatusChip muestra el estado traducido', (tester) async {
    await tester.pumpWidget(
      wrapWidget(
        const Scaffold(
          body: Center(child: StatusChip(status: AppointmentStatus.noAsistio)),
        ),
      ),
    );

    expect(find.text('No asistió'), findsOneWidget);
  });

  testWidgets('StatusChip cambia con el estado', (tester) async {
    await tester.pumpWidget(
      wrapWidget(
        const Scaffold(
          body: Center(child: StatusChip(status: AppointmentStatus.confirmada)),
        ),
      ),
    );

    expect(find.text('Confirmada'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
}
