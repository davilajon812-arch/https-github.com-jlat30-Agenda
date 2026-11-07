import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/plan.dart';

/// Diálogo amable cuando el negocio llega al límite de su plan.
Future<void> showPlanLimitDialog(
  BuildContext context,
  PlanLimitException error,
) async {
  final l10n = AppLocalizations.of(context);

  final detalle = switch (error.limit) {
    'staff' => l10n.planLimitStaff(_limitLabel(error, l10n)),
    'appointments_per_month' =>
      l10n.planLimitAppointments(_limitLabel(error, l10n)),
    _ => l10n.planLimitGeneric,
  };

  final upgrade = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.workspace_premium_outlined),
      title: Text(l10n.planLimitTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(detalle),
          const SizedBox(height: 8),
          Text(
            error.upgradeTo != null
                ? '${l10n.billingUpgrade}: ${_planName(error.upgradeTo!)}'
                : '',
            style: Theme.of(dialogContext).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.planLimitLater),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.planLimitUpgrade),
        ),
      ],
    ),
  );

  if (upgrade == true && context.mounted) {
    context.push('/plan');
  }
}

String _planName(String planId) => switch (planId) {
      'basico' => 'Básico',
      'pro' => 'Pro',
      _ => planId,
    };

String _limitLabel(PlanLimitException error, AppLocalizations l10n) {
  // El backend manda el límite en el mensaje; se usa un texto corto si falta.
  return switch (error.limit) {
    'staff' => error.plan == 'free' ? '1' : '3',
    'appointments_per_month' => '30',
    _ => l10n.billingUnlimited,
  };
}
