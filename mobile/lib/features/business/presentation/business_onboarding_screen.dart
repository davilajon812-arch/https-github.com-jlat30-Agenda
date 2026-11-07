import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../l10n/app_localizations.dart';
import 'providers/business_providers.dart';
import 'widgets/onboarding_options.dart';

/// Alta del negocio justo después del registro.
class BusinessOnboardingScreen extends ConsumerStatefulWidget {
  const BusinessOnboardingScreen({super.key});

  @override
  ConsumerState<BusinessOnboardingScreen> createState() =>
      _BusinessOnboardingScreenState();
}

class _BusinessOnboardingScreenState
    extends ConsumerState<BusinessOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _countryCode = 'NI';
  String _industry = 'barberia';
  late String _currency;
  late String _timezone;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final country = countryByCode(_countryCode);
    _currency = country.currency;
    _timezone = country.timezone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(businessRepositoryProvider).createBusiness(
            name: _nameController.text,
            industry: _industry,
            countryCode: _countryCode,
            currency: _currency,
            timezone: _timezone,
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
              child: Form(
                key: _formKey,
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
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.onboardingBusinessName,
                        prefixIcon: const Icon(Icons.storefront_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.onboardingNameRequired;
                        }
                        if (value.trim().length < 3) {
                          return l10n.validationNameLength;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _industry,
                      decoration: InputDecoration(
                        labelText: l10n.onboardingIndustry,
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                      items: industries
                          .map(
                            (option) => DropdownMenuItem(
                              value: option.code,
                              child: Text(option.label(l10n)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _industry = value ?? 'otro'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _countryCode,
                      decoration: InputDecoration(
                        labelText: l10n.onboardingCountry,
                        prefixIcon: const Icon(Icons.public),
                      ),
                      items: countries
                          .map(
                            (country) => DropdownMenuItem(
                              value: country.code,
                              child: Text(country.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        final country = countryByCode(value ?? 'NI');
                        setState(() {
                          _countryCode = country.code;
                          _currency = country.currency;
                          _timezone = country.timezone;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: InputDecoration(
                        labelText: l10n.onboardingCurrency,
                        prefixIcon: const Icon(Icons.payments_outlined),
                      ),
                      items: currencies
                          .map(
                            (code) => DropdownMenuItem(
                              value: code,
                              child: Text(code),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _currency = value ?? _currency),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _timezone,
                      decoration: InputDecoration(
                        labelText: l10n.onboardingTimezone,
                        prefixIcon: const Icon(Icons.schedule),
                      ),
                      items: timezones
                          .map(
                            (zone) => DropdownMenuItem(
                              value: zone,
                              child: Text(zone),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _timezone = value ?? _timezone),
                    ),
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
      ),
    );
  }
}
