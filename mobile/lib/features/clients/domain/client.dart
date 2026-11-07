/// Cliente del negocio.
class Client {
  const Client({
    required this.id,
    required this.businessId,
    required this.fullName,
    required this.phone,
    this.notes,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String businessId;
  final String fullName;
  final String phone;
  final String? notes;

  /// Teléfono listo para wa.me (solo dígitos).
  String get whatsappNumber => phone.replaceAll(RegExp(r'[^0-9]'), '');

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters(1);
    return '${parts.first.characters(1)}${parts[1].characters(1)}';
  }
}

extension on String {
  String characters(int count) =>
      length >= count ? substring(0, count).toUpperCase() : toUpperCase();
}
