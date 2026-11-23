/// Interpreta lo que el cliente pega en "Reservar una cita".
///
/// Acepta el enlace completo que le compartió el negocio
/// (`https://host/r/mi-barberia`, con o sin `?c=token`) o el código suelto
/// (`mi-barberia`). Devuelve el `slug` del negocio, o `null` si no se
/// reconoce.
String? parseBookingSlug(String input) {
  final value = input.trim();
  if (value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 && segments[segments.length - 2] == 'r') {
      return _validSlug(segments.last);
    }
    return null;
  }

  return _validSlug(value);
}

/// Token de seguimiento de una reserva (`?c=...`), si el enlace lo trae.
String? parseBookingToken(String input) {
  final uri = Uri.tryParse(input.trim());
  if (uri == null || !uri.hasScheme) return null;
  final token = uri.queryParameters['c'];
  return token == null || token.trim().isEmpty ? null : token.trim();
}

String? _validSlug(String candidate) {
  final slug = candidate.trim().toLowerCase();
  if (slug.length < 3 || slug.length > 60) return null;
  return RegExp(r'^[a-z0-9][a-z0-9-]*$').hasMatch(slug) ? slug : null;
}

/// Enlace público de un negocio a partir de su `slug`.
String bookingLink(String publicBase, String slug) {
  final base = publicBase.trim().replaceAll(RegExp(r'/+$'), '');
  return '$base/r/$slug';
}
