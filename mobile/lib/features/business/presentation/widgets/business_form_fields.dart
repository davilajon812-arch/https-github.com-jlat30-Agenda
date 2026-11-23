import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/business.dart';
import 'onboarding_options.dart';

/// Datos del negocio listos para guardar.
class BusinessDraft {
  const BusinessDraft({
    required this.name,
    required this.phone,
    required this.address,
    required this.industry,
    required this.countryCode,
    required this.currency,
    required this.timezone,
  });

  final String name;
  final String? phone;
  final String? address;
  final String industry;
  final String countryCode;
  final String currency;
  final String timezone;
}

/// Campos del negocio: nombre, teléfono, rubro, país, moneda y zona horaria.
///
/// Lo usan el alta del primer negocio y la edición desde Ajustes, para que los
/// campos y sus validaciones no se dupliquen.
class BusinessFormFields extends StatefulWidget {
  const BusinessFormFields({super.key, this.initial});

  /// Negocio a editar; `null` cuando se está creando uno nuevo.
  final Business? initial;

  @override
  State<BusinessFormFields> createState() => BusinessFormFieldsState();
}

class BusinessFormFieldsState extends State<BusinessFormFields> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  late String _industry;
  late String _countryCode;
  late String _currency;
  late String _timezone;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _phoneController = TextEditingController(text: initial?.phone ?? '');
    _addressController = TextEditingController(text: initial?.address ?? '');
    _industry = initial?.industry ?? 'barberia';
    _countryCode = initial?.countryCode ?? 'NI';
    _currency = initial?.currency ?? 'NIO';
    _timezone = initial?.timezone ?? 'America/Managua';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Devuelve los datos si el formulario es válido; si no, `null`.
  BusinessDraft? validate() {
    if (!(_formKey.currentState?.validate() ?? false)) return null;
    return BusinessDraft(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      industry: _industry,
      countryCode: _countryCode,
      currency: _currency,
      timezone: _timezone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.businessNameLabel,
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
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.businessPhoneLabel,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            validator: (value) {
              final phone = value?.trim() ?? '';
              if (phone.isEmpty) return null;
              if (phone.length < 6) return l10n.validationPhoneLength;
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              labelText: l10n.businessAddressLabel,
              helperText: l10n.businessAddressHint,
              prefixIcon: const Icon(Icons.place_outlined),
            ),
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
            onChanged: (value) => setState(() => _industry = value ?? 'otro'),
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
                  (code) => DropdownMenuItem(value: code, child: Text(code)),
                )
                .toList(),
            onChanged: (value) => setState(() => _currency = value ?? _currency),
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
                  (zone) => DropdownMenuItem(value: zone, child: Text(zone)),
                )
                .toList(),
            onChanged: (value) => setState(() => _timezone = value ?? _timezone),
          ),
        ],
      ),
    );
  }
}
