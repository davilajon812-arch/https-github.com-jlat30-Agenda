import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/agenda_api.dart';
import '../../../../core/providers/app_providers.dart';
import '../../domain/appointment.dart';

/// Rango consultado para la agenda.
typedef AgendaQuery = ({String businessId, DateTime from, DateTime to});

/// Parámetros de la consulta de disponibilidad.
typedef AvailabilityQuery = ({
  String businessId,
  String serviceId,
  DateTime date,
  String? staffId,
});

/// Citas del rango (día o semana).
final agendaProvider =
    FutureProvider.autoDispose.family<List<Appointment>, AgendaQuery>(
  (ref, query) => ref.watch(appointmentsRepositoryProvider).listRange(
        businessId: query.businessId,
        from: query.from,
        to: query.to,
      ),
);

/// Detalle de una cita.
final appointmentProvider =
    FutureProvider.autoDispose.family<Appointment, String>(
  (ref, appointmentId) =>
      ref.watch(appointmentsRepositoryProvider).fetch(appointmentId),
);

/// Historial de citas de un cliente.
final clientVisitsProvider = FutureProvider.autoDispose
    .family<List<Appointment>, ({String businessId, String clientId})>(
  (ref, query) => ref.watch(appointmentsRepositoryProvider).listForClient(
        businessId: query.businessId,
        clientId: query.clientId,
      ),
);

/// Huecos libres calculados por el backend.
final availabilityProvider =
    FutureProvider.autoDispose.family<DayAvailability, AvailabilityQuery>(
  (ref, query) => ref.watch(agendaApiProvider).availability(
        businessId: query.businessId,
        serviceId: query.serviceId,
        date: query.date,
        staffId: query.staffId,
      ),
);
