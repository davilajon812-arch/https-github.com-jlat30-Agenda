import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../domain/appointment.dart';
import '../providers/agenda_providers.dart';
import 'payment_method_labels.dart';

/// Cobro de la cita: registrar o deshacer el pago.
class PaymentSection extends ConsumerWidget {
  const PaymentSection({super.key, required this.appointment});

  final Appointment appointment;

  Future<void> _register(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final draft = await showModalBottomSheet<PaymentDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PaymentSheet(initialAmount: appointment.price ?? 0),
    );
    if (draft == null || !context.mounted) return;

    try {
      await ref.read(appointmentsRepositoryProvider).registerPayment(
            appointmentId: appointment.id,
            amount: draft.amount,
            method: draft.method,
          );
      _refresh(ref);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paymentSaved)),
      );
    } on PostgrestException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorSave)),
      );
    }
  }

  Future<void> _undo(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(appointmentsRepositoryProvider)
          .clearPayment(appointment.id);
      _refresh(ref);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paymentUndone)),
      );
    } on PostgrestException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorSave)),
      );
    }
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(appointmentProvider(appointment.id));
    ref.invalidate(agendaProvider);
    ref.invalidate(clientVisitsProvider);
    ref.invalidate(incomeProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currency = ref.watch(activeBusinessProvider)?.business.currency ?? '';
    final locale = Localizations.localeOf(context).toLanguageTag();
    final money = NumberFormat.currency(
      locale: locale,
      symbol: '$currency ',
      decimalDigits: 2,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  appointment.isPaid
                      ? Icons.check_circle
                      : Icons.payments_outlined,
                  size: 18,
                  color: appointment.isPaid
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(l10n.paymentTitle, style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  appointment.isPaid
                      ? l10n.paymentStatusPaid
                      : l10n.paymentStatusUnpaid,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: appointment.isPaid
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (appointment.isPaid) ...[
              const SizedBox(height: 8),
              Text(
                money.format(appointment.incomeAmount),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (appointment.paymentMethod != null)
                    appointment.paymentMethod!.label(l10n),
                  if (appointment.paidAt != null)
                    l10n.paymentPaidOn(
                      DateFormat.yMMMd(locale).format(appointment.paidAt!),
                    ),
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _undo(context, ref),
                  child: Text(l10n.paymentUndo),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _register(context, ref),
                    icon: const Icon(Icons.price_check),
                    label: Text(l10n.paymentRegister),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lo que devuelve la hoja de cobro.
typedef PaymentDraft = ({double amount, PaymentMethod method});

/// Hoja para anotar importe y medio de pago.
class PaymentSheet extends StatefulWidget {
  const PaymentSheet({super.key, required this.initialAmount});

  final double initialAmount;

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.initialAmount > 0 ? widget.initialAmount.toStringAsFixed(2) : '',
  );
  PaymentMethod _method = PaymentMethod.efectivo;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final raw = _amount.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      setState(() => _error = l10n.paymentAmountInvalid);
      return;
    }
    Navigator.of(context).pop<PaymentDraft>((amount: amount, method: _method));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.paymentRegister, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: l10n.paymentAmountLabel,
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 16),
          Text(l10n.paymentMethodLabel, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final method in PaymentMethod.values)
                ChoiceChip(
                  label: Text(method.label(l10n)),
                  selected: _method == method,
                  onSelected: (_) => setState(() => _method = method),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: Text(l10n.paymentSave),
            ),
          ),
        ],
      ),
    );
  }
}
