import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/client.dart';

/// Clientes del negocio (alta, edición, búsqueda y borrado).
class ClientsRepository {
  ClientsRepository(this._client);

  static const _columns = 'id, business_id, full_name, phone, notes';

  final SupabaseClient _client;

  Future<List<Client>> search({
    required String businessId,
    String term = '',
    int limit = 50,
  }) async {
    var query = _client
        .from('clients')
        .select(_columns)
        .eq('business_id', businessId);

    final trimmed = term.trim();
    if (trimmed.isNotEmpty) {
      // Busca por nombre o por teléfono en una sola consulta.
      query = query.or('full_name.ilike.%$trimmed%,phone.like.%$trimmed%');
    }

    final rows = await query.order('full_name', ascending: true).limit(limit);
    return rows.map(Client.fromJson).toList(growable: false);
  }

  Future<Client> create({
    required String businessId,
    required String fullName,
    required String phone,
    String? notes,
  }) async {
    final row = await _client
        .from('clients')
        .insert({
          'business_id': businessId,
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'notes': notes,
        })
        .select(_columns)
        .single();

    return Client.fromJson(row);
  }

  Future<void> update({
    required String clientId,
    String? fullName,
    String? phone,
    String? notes,
  }) async {
    await _client.from('clients').update({
      'full_name': ?fullName?.trim(),
      'phone': ?phone?.trim(),
      'notes': ?notes,
    }).eq('id', clientId);
  }

  Future<void> delete(String clientId) async {
    await _client.from('clients').delete().eq('id', clientId);
  }

  Future<Client> fetch(String clientId) async {
    final row = await _client
        .from('clients')
        .select(_columns)
        .eq('id', clientId)
        .single();
    return Client.fromJson(row);
  }
}
