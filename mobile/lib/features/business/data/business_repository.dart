import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/business.dart';

/// Lectura y creación de negocios del usuario.
class BusinessRepository {
  BusinessRepository(this._client);

  static const _businessColumns =
      'id, name, slug, industry, country_code, currency, timezone, '
      'public_booking_enabled';

  final SupabaseClient _client;

  /// Negocios donde el usuario es miembro activo.
  Future<List<BusinessMembership>> fetchMemberships() async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];

    final rows = await _client
        .from('business_members')
        .select('role, businesses($_businessColumns)')
        .eq('profile_id', user.id)
        .eq('is_active', true)
        .order('created_at');

    return rows
        .where((row) => row['businesses'] != null)
        .map(BusinessMembership.fromJson)
        .toList(growable: false);
  }

  /// Crea el negocio; el trigger de la base agrega al dueño como miembro.
  Future<Business> createBusiness({
    required String name,
    required String? industry,
    required String countryCode,
    required String currency,
    required String timezone,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Se requiere una sesión activa');
    }

    PostgrestException? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final row = await _client
            .from('businesses')
            .insert({
              'owner_id': user.id,
              'name': name.trim(),
              'slug': _buildSlug(name, attempt),
              'industry': industry,
              'country_code': countryCode,
              'currency': currency,
              'timezone': timezone,
            })
            .select(_businessColumns)
            .single();
        return Business.fromJson(row);
      } on PostgrestException catch (error) {
        lastError = error;
        // 23505 = violación de unicidad del slug: reintenta con otro sufijo.
        if (error.code != '23505') rethrow;
      }
    }
    throw lastError!;
  }

  static String _buildSlug(String name, int attempt) {
    final base = slugify(name);
    if (attempt == 0) return base;

    final suffix = Random()
        .nextInt(0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0')
        .substring(0, 4);
    return '$base-$suffix';
  }
}

/// Convierte un nombre en slug válido (`^[a-z0-9-]{3,60}$`).
String slugify(String value) {
  const replacements = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'ñ': 'n', 'ç': 'c',
  };

  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final normalized = replacements[char] ?? char;
    if (RegExp('[a-z0-9]').hasMatch(normalized)) {
      buffer.write(normalized);
    } else {
      buffer.write('-');
    }
  }

  var slug = buffer
      .toString()
      .replaceAll(RegExp('-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  if (slug.length > 60) {
    slug = slug.substring(0, 60).replaceAll(RegExp(r'-$'), '');
  }
  if (slug.length < 3) {
    slug = 'negocio';
  }
  return slug;
}
