/// Negocio al que pertenece el usuario.
class Business {
  const Business({
    required this.id,
    required this.name,
    required this.slug,
    required this.countryCode,
    required this.currency,
    required this.timezone,
    this.industry,
    this.publicBookingEnabled = false,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      industry: json['industry'] as String?,
      countryCode: json['country_code'] as String? ?? 'NI',
      currency: json['currency'] as String? ?? 'NIO',
      timezone: json['timezone'] as String? ?? 'America/Managua',
      publicBookingEnabled: json['public_booking_enabled'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String slug;
  final String? industry;
  final String countryCode;
  final String currency;
  final String timezone;
  final bool publicBookingEnabled;
}

/// Membresía del usuario en un negocio, con su rol.
class BusinessMembership {
  const BusinessMembership({required this.business, required this.role});

  factory BusinessMembership.fromJson(Map<String, dynamic> json) {
    return BusinessMembership(
      business: Business.fromJson(json['businesses'] as Map<String, dynamic>),
      role: json['role'] as String? ?? 'staff',
    );
  }

  final Business business;
  final String role;

  bool get isOwner => role == 'owner';
}
