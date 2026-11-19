import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/appointment.dart';

/// Consulta de citas: agenda por rango, alta, edición y cambio de estado.
class AppointmentsRepository {
  AppointmentsRepository(this._client);

  static const _columns = 'id, business_id, client_id, clients(full_name, phone), '
      'service_id, services(name), staff_id, staff_members(display_name), '
      'location_id, starts_at, ends_at, status, price, notes, '
      'paid_at, amount_paid, payment_method';

  final SupabaseClient _client;

  Future<List<Appointment>> listRange({
    required String businessId,
    required DateTime from,
    required DateTime to,
    String? staffId,
    AppointmentStatus? status,
  }) async {
    var query = _client
        .from('appointments')
        .select(_columns)
        .eq('business_id', businessId)
        .gte('ends_at', from.toUtc().toIso8601String())
        .lte('starts_at', to.toUtc().toIso8601String());

    if (staffId != null) {
      query = query.eq('staff_id', staffId);
    }
    if (status != null) {
      query = query.eq('status', status.code);
    }

    // `ascending` es explícito a propósito: en postgrest 2.x el valor por
    // defecto es descendente, y la agenda del día debe leerse de 09:00 en
    // adelante.
    final rows = await query.order('starts_at', ascending: true);
    return rows.map(Appointment.fromJson).toList(growable: false);
  }

  Future<List<Appointment>> listForClient({
    required String businessId,
    required String clientId,
  }) async {
    final rows = await _client
        .from('appointments')
        .select(_columns)
        .eq('business_id', businessId)
        .eq('client_id', clientId)
        .order('starts_at', ascending: false)
        .limit(50);

    return rows.map(Appointment.fromJson).toList(growable: false);
  }

  Future<Appointment> fetch(String appointmentId) async {
    final row = await _client
        .from('appointments')
        .select(_columns)
        .eq('id', appointmentId)
        .single();
    return Appointment.fromJson(row);
  }

  Future<Appointment> create({
    required String businessId,
    required String clientId,
    required DateTime startsAt,
    String? serviceId,
    String? staffId,
    double? price,
    String? notes,
  }) async {
    final row = await _client
        .from('appointments')
        .insert({
          'business_id': businessId,
          'client_id': clientId,
          'service_id': serviceId,
          'staff_id': staffId,
          'starts_at': startsAt.toUtc().toIso8601String(),
          'price': price,
          'notes': notes,
        })
        .select(_columns)
        .single();

    return Appointment.fromJson(row);
  }

  Future<void> changeStatus(String appointmentId, AppointmentStatus status) async {
    await _client
        .from('appointments')
        .update({'status': status.code}).eq('id', appointmentId);
  }

  /// Marca la cita como cobrada con su importe y medio de pago.
  Future<void> registerPayment({
    required String appointmentId,
    required double amount,
    required PaymentMethod method,
  }) async {
    await _client.from('appointments').update({
      'paid_at': DateTime.now().toUtc().toIso8601String(),
      'amount_paid': amount,
      'payment_method': method.code,
    }).eq('id', appointmentId);
  }

  /// Deshace el cobro (se registró por error).
  Future<void> clearPayment(String appointmentId) async {
    await _client.from('appointments').update({
      'paid_at': null,
      'amount_paid': null,
      'payment_method': null,
    }).eq('id', appointmentId);
  }

  Future<void> update({
    required String appointmentId,
    DateTime? startsAt,
    String? serviceId,
    String? staffId,
    double? price,
    String? notes,
  }) async {
    await _client.from('appointments').update({
      'starts_at': ?startsAt?.toUtc().toIso8601String(),
      'service_id': ?serviceId,
      'staff_id': ?staffId,
      'price': ?price,
      'notes': ?notes,
    }).eq('id', appointmentId);
  }
}
