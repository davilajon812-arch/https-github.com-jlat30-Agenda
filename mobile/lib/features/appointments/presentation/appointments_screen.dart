import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/widgets/placeholder_view.dart';

/// Pantalla de la agenda del día (se completa en la Fase 2).
class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderView(
      icon: Icons.event_note_outlined,
      title: l10n.navAppointments,
      message: '${l10n.homeTodayEmpty}\n\n${l10n.placeholderPhaseTwo}',
    );
  }
}
