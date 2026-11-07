import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/error_view.dart';
import '../features/business/presentation/business_onboarding_screen.dart';
import '../features/business/presentation/providers/business_providers.dart';
import '../l10n/app_localizations.dart';
import 'home_shell.dart';

/// Decide qué ve un usuario autenticado: onboarding o app completa.
class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final memberships = ref.watch(myBusinessesProvider);

    return memberships.when(
      loading: () => const _SplashScreen(),
      error: (error, stackTrace) => Scaffold(
        body: ErrorView(
          message: l10n.errorGeneric,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(myBusinessesProvider),
        ),
      ),
      data: (list) {
        if (list.isEmpty) return const BusinessOnboardingScreen();
        return const HomeShell();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
