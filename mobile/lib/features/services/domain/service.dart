/// Servicio que ofrece el negocio.
class Service {
  const Service({
    required this.id,
    required this.businessId,
    required this.name,
    required this.durationMinutes,
    required this.price,
    this.description,
    this.isActive = true,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final String id;
  final String businessId;
  final String name;
  final String? description;
  final int durationMinutes;
  final double price;
  final bool isActive;
}
