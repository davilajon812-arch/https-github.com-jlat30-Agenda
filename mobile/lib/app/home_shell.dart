import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/appointments/presentation/appointments_screen.dart';
import '../../features/billing/presentation/billing_screen.dart';
import '../../features/clients/presentation/clients_screen.dart';
import '../../features/business/presentation/providers/business_providers.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../l10n/app_localizations.dart';

/// Contenedor principal con la navegación por pestañas.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final businessName =
        ref.watch(activeBusinessProvider)?.business.name ?? l10n.appTitle;

    return Scaffold(
      appBar: AppBar(title: Text(businessName)),
      body: IndexedStack(
        index: _index,
        children: const [
          AppointmentsScreen(),
          ClientsScreen(),
          BillingScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.event_note_outlined),
            selectedIcon: const Icon(Icons.event_note),
            label: l10n.navAppointments,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: l10n.navClients,
          ),
          NavigationDestination(
            icon: const Icon(Icons.workspace_premium_outlined),
            selectedIcon: const Icon(Icons.workspace_premium),
            label: l10n.navPlan,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
