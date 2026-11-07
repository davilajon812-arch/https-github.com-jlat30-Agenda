import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/widgets/placeholder_view.dart';

/// Clientes del negocio (se completa en la Fase 2).
class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderView(
      icon: Icons.people_outline,
      title: l10n.navClients,
      message: l10n.placeholderPhaseTwo,
    );
  }
}
