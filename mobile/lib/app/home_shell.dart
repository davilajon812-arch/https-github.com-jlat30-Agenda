import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/appointments/presentation/appointments_screen.dart';
import '../features/appointments/presentation/income_screen.dart';
import '../features/billing/presentation/billing_screen.dart';
import '../features/clients/presentation/clients_screen.dart';
import '../features/business/presentation/providers/business_providers.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../l10n/app_localizations.dart';
import '../core/widgets/free_plan_ad_banner.dart';

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
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                AppointmentsScreen(),
                ClientsScreen(),
                IncomeScreen(),
                BillingScreen(),
                SettingsScreen(),
              ],
            ),
          ),
          // Solo se pinta para el plan Gratis (ver free_plan_ad_banner.dart).
          const FreePlanAdBanner(),
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
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: l10n.navIncome,
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
