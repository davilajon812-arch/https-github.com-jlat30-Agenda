import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../l10n/app_localizations.dart';
import 'providers/business_providers.dart';
import 'widgets/business_form_fields.dart';

/// Alta del negocio justo después del registro.
class BusinessOnboardingScreen extends ConsumerStatefulWidget {
  const BusinessOnboardingScreen({super.key});

  @override
  ConsumerState<BusinessOnboardingScreen> createState() =>
      _BusinessOnboardingScreenState();
}

class _BusinessOnboardingScreenState
    extends ConsumerState<BusinessOnboardingScreen> {
  final _fieldsKey = GlobalKey<BusinessFormFieldsState>();

  bool _submitting = false;
  String? _errorMessage;

  Future<void> _submit() async {
    final draft = _fieldsKey.currentState?.validate();
    if (draft == null) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(businessRepositoryProvider).createBusiness(
            name: draft.name,
            industry: draft.industry,
            countryCode: draft.countryCode,
            currency: draft.currency,
            timezone: draft.timezone,
            phone: draft.phone,
          );
      ref.invalidate(myBusinessesProvider);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(context).errorGeneric;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.onboardingTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.onboardingSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  BusinessFormFields(key: _fieldsKey),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.onboardingCreate),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => ref.read(authRepositoryProvider).signOut(),
                    child: Text(l10n.settingsSignOut),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
