import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/billing/domain/plan.dart';

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
            ).toLocal(),
            endsAt: DateTime.parse(
              slot['ends_at'] as String,
            ).toLocal(),
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
/// El backend es la fuente de verdad de disponibilidad y de límites del plan.
class AgendaApi {
  AgendaApi({
    required this.baseUrl,
    required SupabaseClient supabaseClient,
    http.Client? httpClient,
    Duration timeout = defaultTimeout,
    Duration verifyTimeout = defaultVerifyTimeout,
  })  : _supabase = supabaseClient,
        _http = httpClient ?? http.Client(),
        _timeout = timeout,
        _verifyTimeout = verifyTimeout;

  final String baseUrl;
  final SupabaseClient _supabase;
  final http.Client _http;
  final Duration _timeout;
  final Duration _verifyTimeout;

  /// Render (plan gratuito) tarda en despertar; sin límite, la petición puede
  /// quedarse colgada para siempre.
  static const defaultTimeout = Duration(seconds: 30);

  /// Verificar una compra tiene un margen mayor: si se corta, el usuario ya
  /// pagó y la compra quedaría sin completar (Google la reembolsa a los 3 días).
  static const defaultVerifyTimeout = Duration(seconds: 60);

  /// Envuelve la petición con un límite de tiempo y un error legible.
  Future<http.Response> _send(
    Future<http.Response> request, {
    Duration? timeout,
  }) async {
    try {
      return await request.timeout(timeout ?? _timeout);
    } on TimeoutException {
      throw AgendaApiException(
        'La conexión tardó demasiado. Revisa tu internet e intenta de nuevo.',
        statusCode: 408,
      );
    }
  }

  Map<String, String> _authHeaders() {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw AgendaApiException('Sesión expirada', statusCode: 401);
    }
    return {'Authorization': 'Bearer $token'};
  }

  static String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {
      // El cuerpo no era JSON: se usa el mensaje genérico.
    }
    return 'No se pudo completar la operación';
  }

  /// Convierte un error HTTP en excepción tipada (402 -> límite de plan).
  static Never _throwFor(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 402 &&
          decoded is Map &&
          decoded['detail'] is Map) {
        throw PlanLimitException.fromDetail(
          Map<String, dynamic>.from(decoded['detail'] as Map),
        );
      }
    } on PlanLimitException {
      rethrow;
    } catch (_) {
      // Se sigue con el error genérico.
    }
    throw AgendaApiException(
      _errorMessage(response.body),
      statusCode: response.statusCode,
    );
  }

  Future<DayAvailability> availability({
    required String businessId,
    required String serviceId,
    required DateTime date,
    String? staffId,
  }) async {
    final query = {
      'service_id': serviceId,
      'date': _dateOnly(date),
      'staff_id': ?staffId,
    };
    final uri = Uri.parse('$baseUrl/api/v1/businesses/$businessId/availability')
        .replace(queryParameters: query);

    final response = await _send(_http.get(uri, headers: _authHeaders()));
    if (response.statusCode != 200) _throwFor(response);

    return DayAvailability.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Catálogo de planes con sus límites.
  Future<List<Plan>> plans() async {
    final response = await _send(
      _http.get(Uri.parse('$baseUrl/api/v1/billing/plans')),
    );
    if (response.statusCode != 200) _throwFor(response);

    return [
      for (final item in jsonDecode(response.body) as List<dynamic>)
        Plan.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// Plan activo y consumo del negocio.
  Future<Entitlements> entitlements(String businessId) async {
    final response = await _send(
      _http.get(
        Uri.parse('$baseUrl/api/v1/businesses/$businessId/entitlements'),
        headers: _authHeaders(),
      ),
    );
    if (response.statusCode != 200) _throwFor(response);

    return Entitlements.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Verifica una compra de Google Play y devuelve el nuevo estado del plan.
  Future<Entitlements> verifyPurchase({
    required String businessId,
    required String productId,
    required String purchaseToken,
  }) async {
    final response = await _send(
      _http.post(
        Uri.parse('$baseUrl/api/v1/billing/verify'),
        headers: {..._authHeaders(), 'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': businessId,
          'product_id': productId,
          'purchase_token': purchaseToken,
        }),
      ),
      timeout: _verifyTimeout,
    );
    if (response.statusCode != 200) _throwFor(response);

    return Entitlements.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Crea un empleado (el backend aplica el límite del plan).
  Future<Map<String, dynamic>> createStaff({
    required String businessId,
    required String displayName,
    String? phone,
  }) async {
    final response = await _send(
      _http.post(
        Uri.parse('$baseUrl/api/v1/businesses/$businessId/staff'),
        headers: {..._authHeaders(), 'Content-Type': 'application/json'},
        body: jsonEncode({
          'display_name': displayName,
          'phone': phone,
        }),
      ),
    );
    if (response.statusCode != 201) _throwFor(response);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Crea una cita (el backend valida choques y límite mensual).
  Future<Map<String, dynamic>> createAppointment({
    required String businessId,
    required String clientId,
    required DateTime startsAt,
    String? serviceId,
    String? staffId,
    double? price,
    String? notes,
  }) async {
    final response = await _send(
      _http.post(
        Uri.parse('$baseUrl/api/v1/businesses/$businessId/appointments'),
        headers: {..._authHeaders(), 'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_id': clientId,
          'service_id': serviceId,
          'staff_id': staffId,
          'starts_at': startsAt.toUtc().toIso8601String(),
          'price': price,
          'notes': notes,
        }),
      ),
    );
    if (response.statusCode != 201) _throwFor(response);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Elimina la cuenta del usuario y los datos de sus negocios.
  Future<void> deleteAccount() async {
    final response = await _send(
      _http.delete(
        Uri.parse('$baseUrl/api/v1/account'),
        headers: _authHeaders(),
      ),
    );
    if (response.statusCode != 200) _throwFor(response);
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void dispose() => _http.close();
}
