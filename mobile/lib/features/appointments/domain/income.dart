import 'appointment.dart';

/// Periodo del reporte de ingresos.
enum IncomePeriod {
  hoy('hoy'),
  semana('semana'),
  mes('mes');

  const IncomePeriod(this.code);

  final String code;
}

/// Resumen de ingresos de un periodo.
class IncomeSummary {
  const IncomeSummary({
    required this.total,
    required this.count,
    required this.byDay,
    required this.byMethod,
    required this.byService,
    required this.byStaff,
  });

  /// Suma de lo cobrado en el periodo.
  final double total;

  /// Cantidad de citas cobradas.
  final int count;

  /// Ingresos por día, del más antiguo al más reciente.
  final List<IncomeBucket> byDay;

  /// Ingresos por medio de pago.
  final List<IncomeBucket> byMethod;

  /// Ingresos por servicio.
  final List<IncomeBucket> byService;

  /// Ingresos por empleado.
  final List<IncomeBucket> byStaff;

  bool get isEmpty => count == 0;

  /// Ticket medio por cita cobrada.
  double get average => count == 0 ? 0 : total / count;

  /// Construye el resumen a partir de las citas del periodo.
  ///
  /// Solo cuentan las citas con cobro registrado: una cita completada sin
  /// cobro anotado no infla los ingresos con dinero que quizá no se recibió.
  factory IncomeSummary.fromAppointments(
    Iterable<Appointment> appointments, {
    required DateTime from,
    required DateTime to,
  }) {
    final paid = appointments
        .where((appointment) => appointment.isPaid)
        .toList(growable: false);

    final byDay = <DateTime, double>{};
    final byMethod = <String, double>{};
    final byService = <String, double>{};
    final byStaff = <String, double>{};
    var total = 0.0;

    for (final appointment in paid) {
      final amount = appointment.incomeAmount;
      total += amount;

      final day = DateTime(
        appointment.startsAt.year,
        appointment.startsAt.month,
        appointment.startsAt.day,
      );
      byDay.update(day, (value) => value + amount, ifAbsent: () => amount);

      final method = _paymentMethodKey(appointment.paymentMethod);
      byMethod.update(method, (value) => value + amount, ifAbsent: () => amount);

      final service = appointment.serviceName ?? '—';
      byService.update(service, (value) => value + amount, ifAbsent: () => amount);

      final staff = appointment.staffName ?? '—';
      byStaff.update(staff, (value) => value + amount, ifAbsent: () => amount);
    }

    return IncomeSummary(
      total: total,
      count: paid.length,
      byDay: _sortedByDay(byDay),
      byMethod: _sortedByAmount(byMethod),
      byService: _sortedByAmount(byService),
      byStaff: _sortedByAmount(byStaff),
    );
  }

  static String _paymentMethodKey(PaymentMethod? method) {
    return switch (method) {
      PaymentMethod.efectivo => 'efectivo',
      PaymentMethod.transferencia => 'transferencia',
      PaymentMethod.tarjeta => 'tarjeta',
      PaymentMethod.otro => 'otro',
      null => 'sin_medio',
    };
  }

  static List<IncomeBucket> _sortedByDay(Map<DateTime, double> values) {
    final days = values.keys.toList()..sort();
    return [
      for (final day in days)
        IncomeBucket(
          key: '${day.year.toString().padLeft(4, '0')}-'
              '${day.month.toString().padLeft(2, '0')}-'
              '${day.day.toString().padLeft(2, '0')}',
          amount: values[day]!,
          date: day,
        ),
    ];
  }

  static List<IncomeBucket> _sortedByAmount(Map<String, double> values) {
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final entry in entries)
        IncomeBucket(key: entry.key, amount: entry.value),
    ];
  }
}

/// Una fila del desglose (un día, un medio de pago, un servicio o un empleado).
class IncomeBucket {
  const IncomeBucket({required this.key, required this.amount, this.date});

  final String key;
  final double amount;

  /// Solo se usa en el desglose por día.
  final DateTime? date;
}

/// Rango de fechas que cubre el periodo, con la semana empezando en lunes.
({DateTime from, DateTime to}) incomeRange(IncomePeriod period, DateTime now) {
  final day = DateTime(now.year, now.month, now.day);
  return switch (period) {
    IncomePeriod.hoy => (from: day, to: day.add(const Duration(days: 1))),
    IncomePeriod.semana => (
        from: day.subtract(Duration(days: now.weekday - 1)),
        to: day.subtract(Duration(days: now.weekday - 1))
            .add(const Duration(days: 7)),
      ),
    IncomePeriod.mes => (
        from: DateTime(now.year, now.month),
        to: DateTime(now.year, now.month + 1),
      ),
  };
}
