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
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final client = json['clients'] as Map<String, dynamic>?;
    final service = json['services'] as Map<String, dynamic>?;
    final staff = json['staff_members'] as Map<String, dynamic>?;

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

  Duration get duration => endsAt.difference(startsAt);

  /// Teléfono listo para wa.me.
  String get whatsappNumber =>
      (clientPhone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
}
