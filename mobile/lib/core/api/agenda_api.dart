import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Error devuelto por la API del backend.
class AgendaApiException implements Exception {
  AgendaApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Franja de un hueco libre.
class SlotRange {
  const SlotRange({required this.startsAt, required this.endsAt});

  final DateTime startsAt;
  final DateTime endsAt;
}

/// Disponibilidad de un empleado para un día.
class StaffAvailability {
  const StaffAvailability({
    required this.staffId,
    required this.staffName,
    required this.slots,
  });

  factory StaffAvailability.fromJson(Map<String, dynamic> json) {
    return StaffAvailability(
      staffId: json['staff_id'] as String,
      staffName: json['staff_name'] as String,
      slots: [
        for (final slot in (json['slots'] as List<dynamic>))
          SlotRange(
            startsAt: DateTime.parse(
              (slot as Map<String, dynamic>)['starts_at'] as String,
            ),
            endsAt: DateTime.parse(slot['ends_at'] as String),
          ),
      ],
    );
  }

  final String staffId;
  final String staffName;
  final List<SlotRange> slots;
}

/// Resultado de disponibilidad de un día.
class DayAvailability {
  const DayAvailability({
    required this.timezone,
    required this.durationMinutes,
    required this.staff,
  });

  factory DayAvailability.fromJson(Map<String, dynamic> json) {
    return DayAvailability(
      timezone: json['timezone'] as String? ?? '',
      durationMinutes: (json['service_duration_minutes'] as num).toInt(),
      staff: [
        for (final item in (json['staff'] as List<dynamic>))
          StaffAvailability.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  final String timezone;
  final int durationMinutes;
  final List<StaffAvailability> staff;

  bool get isEmpty => staff.every((entry) => entry.slots.isEmpty);
}

/// Cliente HTTP de la API de AgendaPro.
///
/// La disponibilidad se calcula en el backend para que sea la fuente de verdad.
class AgendaApi {
  AgendaApi({
    required this.baseUrl,
    required SupabaseClient supabaseClient,
    http.Client? httpClient,
  })  : _supabase = supabaseClient,
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final SupabaseClient _supabase;
  final http.Client _http;

  Future<DayAvailability> availability({
    required String businessId,
    required String serviceId,
    required DateTime date,
    String? staffId,
  }) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw AgendaApiException('Sesión expirada');
    }

    final query = {
      'service_id': serviceId,
      'date': _dateOnly(date),
      'staff_id': ?staffId,
    };
    final uri = Uri.parse('$baseUrl/api/v1/businesses/$businessId/availability')
        .replace(queryParameters: query);

    final response = await _http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw AgendaApiException(
        _errorMessage(response.body),
        statusCode: response.statusCode,
      );
    }

    return DayAvailability.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {
      // El cuerpo no era JSON: se usa el mensaje genérico.
    }
    return 'No se pudo consultar la disponibilidad';
  }

  void dispose() => _http.close();
}
