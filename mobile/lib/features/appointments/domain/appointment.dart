import 'package:flutter/material.dart';

/// Estados posibles de una cita.
enum AppointmentStatus {
  pendiente('pendiente'),
  confirmada('confirmada'),
  completada('completada'),
  cancelada('cancelada'),
  noAsistio('no_asistio');

  const AppointmentStatus(this.code);

  final String code;

  static AppointmentStatus fromCode(String code) {
    return AppointmentStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => AppointmentStatus.pendiente,
    );
  }

  /// Estados que todavía ocupan el horario del empleado.
  bool get isActive => this != cancelada && this != noAsistio;

  /// Estados cerrados: ya no admiten cambios de estado en la app.
  bool get isFinal =>
      this == completada || this == cancelada || this == noAsistio;

  IconData get icon => switch (this) {
        AppointmentStatus.pendiente => Icons.schedule,
        AppointmentStatus.confirmada => Icons.check_circle_outline,
        AppointmentStatus.completada => Icons.task_alt,
        AppointmentStatus.cancelada => Icons.cancel_outlined,
        AppointmentStatus.noAsistio => Icons.person_off_outlined,
      };

  Color color(ColorScheme scheme) => switch (this) {
        AppointmentStatus.pendiente => scheme.tertiary,
        AppointmentStatus.confirmada => scheme.primary,
        AppointmentStatus.completada => scheme.secondary,
        AppointmentStatus.cancelada => scheme.error,
        AppointmentStatus.noAsistio => scheme.outline,
      };
}

/// Medio de pago de una cita cobrada.
enum PaymentMethod {
  efectivo('efectivo'),
  transferencia('transferencia'),
  tarjeta('tarjeta'),
  otro('otro');

  const PaymentMethod(this.code);

  final String code;

  static PaymentMethod? fromCode(String? code) {
    if (code == null) return null;
    for (final method in PaymentMethod.values) {
      if (method.code == code) return method;
    }
    return null;
  }
}

/// Cita agendada.
class Appointment {
  const Appointment({
    required this.id,
    required this.businessId,
    required this.clientId,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.clientName,
    this.clientPhone,
    this.serviceId,
    this.serviceName,
    this.staffId,
    this.staffName,
    this.price,
    this.notes,
    this.paidAt,
    this.amountPaid,
    this.paymentMethod,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final client = json['clients'] as Map<String, dynamic>?;
    final service = json['services'] as Map<String, dynamic>?;
    final staff = json['staff_members'] as Map<String, dynamic>?;
    final paidAt = json['paid_at'] as String?;

    return Appointment(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      clientId: json['client_id'] as String,
      clientName: client?['full_name'] as String?,
      clientPhone: client?['phone'] as String?,
      serviceId: json['service_id'] as String?,
      serviceName: service?['name'] as String?,
      staffId: json['staff_id'] as String?,
      staffName: staff?['display_name'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
      status: AppointmentStatus.fromCode(json['status'] as String),
      price: (json['price'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      paidAt: paidAt == null ? null : DateTime.parse(paidAt).toLocal(),
      amountPaid: (json['amount_paid'] as num?)?.toDouble(),
      paymentMethod: PaymentMethod.fromCode(json['payment_method'] as String?),
    );
  }

  final String id;
  final String businessId;
  final String clientId;
  final String? clientName;
  final String? clientPhone;
  final String? serviceId;
  final String? serviceName;
  final String? staffId;
  final String? staffName;
  final DateTime startsAt;
  final DateTime endsAt;
  final AppointmentStatus status;
  final double? price;
  final String? notes;

  /// Cuándo se registró el cobro; `null` si todavía no se cobró.
  final DateTime? paidAt;

  /// Importe cobrado (puede diferir del precio por descuentos o propina).
  final double? amountPaid;

  final PaymentMethod? paymentMethod;

  Duration get duration => endsAt.difference(startsAt);

  bool get isPaid => paidAt != null;

  /// Lo que cuenta para los ingresos: lo cobrado o, si no se anotó, el precio.
  double get incomeAmount => amountPaid ?? price ?? 0;

  /// Teléfono listo para wa.me.
  String get whatsappNumber =>
      (clientPhone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
}
