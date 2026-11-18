import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/service.dart';

/// CRUD de servicios contra Supabase (protegido por RLS).
class ServicesRepository {
  ServicesRepository(this._client);

  static const _columns =
      'id, business_id, name, description, duration_minutes, price, is_active';

  final SupabaseClient _client;

  Future<List<Service>> list(String businessId) async {
    final rows = await _client
        .from('services')
        .select(_columns)
        .eq('business_id', businessId)
        .eq('is_active', true)
        .order('name', ascending: true);

    return rows.map(Service.fromJson).toList(growable: false);
  }

  Future<Service> create({
    required String businessId,
    required String name,
    required int durationMinutes,
    required double price,
    String? description,
  }) async {
    final row = await _client
        .from('services')
        .insert({
          'business_id': businessId,
          'name': name.trim(),
          'duration_minutes': durationMinutes,
          'price': price,
          'description': description,
        })
        .select(_columns)
        .single();

    return Service.fromJson(row);
  }

  Future<void> update({
    required String serviceId,
    String? name,
    int? durationMinutes,
    double? price,
    String? description,
    bool? isActive,
  }) async {
    await _client.from('services').update({
      'name': ?name?.trim(),
      'duration_minutes': ?durationMinutes,
      'price': ?price,
      'description': ?description,
      'is_active': ?isActive,
    }).eq('id', serviceId);
  }

  /// Desactiva el servicio: conserva el historial de citas.
  Future<void> deactivate(String serviceId) async {
    await _client.from('services').update({'is_active': false}).eq('id', serviceId);
  }
}
