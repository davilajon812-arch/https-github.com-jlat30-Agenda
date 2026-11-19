import '../../../../l10n/app_localizations.dart';
import '../../domain/appointment.dart';

/// Nombre visible del medio de pago.
extension PaymentMethodLabels on PaymentMethod {
  String label(AppLocalizations l10n) {
    return switch (this) {
      PaymentMethod.efectivo => l10n.incomeMethodCash,
      PaymentMethod.transferencia => l10n.incomeMethodTransfer,
      PaymentMethod.tarjeta => l10n.incomeMethodCard,
      PaymentMethod.otro => l10n.incomeMethodOther,
    };
  }
}
