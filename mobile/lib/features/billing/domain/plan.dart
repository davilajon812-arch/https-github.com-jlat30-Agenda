/// Plan de suscripción con sus límites (los precios vienen de Google Play).
class Plan {
  const Plan({
    required this.id,
    required this.name,
    this.playProductId,
    this.maxStaff,
    this.maxLocations,
    this.maxAppointmentsPerMonth,
    this.maxMessagesPerMonth,
    this.features = const {},
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as String,
      name: json['name'] as String,
      playProductId: json['play_product_id'] as String?,
      maxStaff: (json['max_staff'] as num?)?.toInt(),
      maxLocations: (json['max_locations'] as num?)?.toInt(),
      maxAppointmentsPerMonth:
          (json['max_appointments_per_month'] as num?)?.toInt(),
      maxMessagesPerMonth: (json['max_messages_per_month'] as num?)?.toInt(),
      features: Map<String, dynamic>.from(
        (json['features'] as Map?) ?? const {},
      ),
    );
  }

  final String id;
  final String name;
  final String? playProductId;
  final int? maxStaff;
  final int? maxLocations;
  final int? maxAppointmentsPerMonth;
  final int? maxMessagesPerMonth;
  final Map<String, dynamic> features;

  bool get isPurchasable => playProductId != null;

  bool feature(String name) => features[name] == true;
}

/// Consumo del negocio en el mes en curso.
class PlanUsage {
  const PlanUsage({
    required this.staffCount,
    required this.appointmentsThisMonth,
    required this.messagesThisMonth,
  });

  factory PlanUsage.fromJson(Map<String, dynamic> json) {
    return PlanUsage(
      staffCount: (json['staff_count'] as num).toInt(),
      appointmentsThisMonth: (json['appointments_this_month'] as num).toInt(),
      messagesThisMonth: (json['messages_this_month'] as num).toInt(),
    );
  }

  final int staffCount;
  final int appointmentsThisMonth;
  final int messagesThisMonth;
}

/// Plan efectivo del negocio tal como lo calcula el backend.
class Entitlements {
  const Entitlements({
    required this.plan,
    required this.status,
    required this.source,
    required this.autoRenewing,
    required this.usage,
    required this.remaining,
    this.currentPeriodEnd,
    this.productId,
    this.upgradeTo,
  });

  factory Entitlements.fromJson(Map<String, dynamic> json) {
    return Entitlements(
      plan: Plan.fromJson(json['plan'] as Map<String, dynamic>),
      status: json['status'] as String,
      source: json['source'] as String,
      autoRenewing: json['auto_renewing'] as bool? ?? false,
      currentPeriodEnd: json['current_period_end'] == null
          ? null
          : DateTime.parse(json['current_period_end'] as String).toLocal(),
      productId: json['product_id'] as String?,
      usage: PlanUsage.fromJson(json['usage'] as Map<String, dynamic>),
      remaining: {
        for (final entry in (json['remaining'] as Map).entries)
          entry.key as String: (entry.value as num?)?.toInt(),
      },
      upgradeTo: json['upgrade_to'] as String?,
    );
  }

  final Plan plan;
  final String status;
  final String source;
  final bool autoRenewing;
  final DateTime? currentPeriodEnd;
  final String? productId;
  final PlanUsage usage;
  final Map<String, int?> remaining;
  final String? upgradeTo;

  bool get isPaid => plan.id != 'free';

  /// Cupo restante (null = ilimitado).
  int? remainingOf(String limit) => remaining[limit];
}

/// Error de límite de plan devuelto por el backend (HTTP 402).
class PlanLimitException implements Exception {
  const PlanLimitException({
    required this.limit,
    required this.plan,
    this.upgradeTo,
    this.message,
  });

  factory PlanLimitException.fromDetail(Map<String, dynamic> detail) {
    return PlanLimitException(
      limit: detail['limit'] as String? ?? 'unknown',
      plan: detail['plan'] as String? ?? 'free',
      upgradeTo: detail['upgrade_to'] as String?,
      message: detail['message'] as String?,
    );
  }

  final String limit;
  final String plan;
  final String? upgradeTo;
  final String? message;

  @override
  String toString() => message ?? 'Límite del plan alcanzado';
}
