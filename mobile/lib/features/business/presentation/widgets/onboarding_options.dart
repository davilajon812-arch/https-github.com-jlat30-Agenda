import '../../../../l10n/app_localizations.dart';

/// Rubros soportados por la app.
class IndustryOption {
  const IndustryOption(this.code, this.label);

  final String code;
  final String Function(AppLocalizations l10n) label;
}

const industries = <IndustryOption>[
  IndustryOption('barberia', _barberia),
  IndustryOption('salon_belleza', _salon),
  IndustryOption('taller_mecanico', _taller),
  IndustryOption('veterinaria', _veterinaria),
  IndustryOption('gimnasio', _gimnasio),
  IndustryOption('academia', _academia),
  IndustryOption('fotografia', _fotografia),
  IndustryOption('otro', _otro),
];

String _barberia(AppLocalizations l10n) => l10n.industryBarberia;
String _salon(AppLocalizations l10n) => l10n.industrySalon;
String _taller(AppLocalizations l10n) => l10n.industryTaller;
String _veterinaria(AppLocalizations l10n) => l10n.industryVeterinaria;
String _gimnasio(AppLocalizations l10n) => l10n.industryGimnasio;
String _academia(AppLocalizations l10n) => l10n.industryAcademia;
String _fotografia(AppLocalizations l10n) => l10n.industryFotografia;
String _otro(AppLocalizations l10n) => l10n.industryOtro;

/// País con sus valores por defecto de moneda y zona horaria.
class CountryOption {
  const CountryOption({
    required this.code,
    required this.name,
    required this.currency,
    required this.timezone,
  });

  final String code;
  final String name;
  final String currency;
  final String timezone;
}

const countries = <CountryOption>[
  CountryOption(
    code: 'NI',
    name: 'Nicaragua',
    currency: 'NIO',
    timezone: 'America/Managua',
  ),
  CountryOption(
    code: 'CR',
    name: 'Costa Rica',
    currency: 'CRC',
    timezone: 'America/Costa_Rica',
  ),
  CountryOption(
    code: 'GT',
    name: 'Guatemala',
    currency: 'GTQ',
    timezone: 'America/Guatemala',
  ),
  CountryOption(
    code: 'HN',
    name: 'Honduras',
    currency: 'HNL',
    timezone: 'America/Tegucigalpa',
  ),
  CountryOption(
    code: 'SV',
    name: 'El Salvador',
    currency: 'USD',
    timezone: 'America/El_Salvador',
  ),
  CountryOption(
    code: 'PA',
    name: 'Panamá',
    currency: 'USD',
    timezone: 'America/Panama',
  ),
  CountryOption(
    code: 'MX',
    name: 'México',
    currency: 'MXN',
    timezone: 'America/Mexico_City',
  ),
  CountryOption(
    code: 'CO',
    name: 'Colombia',
    currency: 'COP',
    timezone: 'America/Bogota',
  ),
  CountryOption(
    code: 'PE',
    name: 'Perú',
    currency: 'PEN',
    timezone: 'America/Lima',
  ),
  CountryOption(
    code: 'DO',
    name: 'República Dominicana',
    currency: 'DOP',
    timezone: 'America/Santo_Domingo',
  ),
];

const currencies = <String>[
  'NIO',
  'USD',
  'CRC',
  'GTQ',
  'HNL',
  'MXN',
  'COP',
  'PEN',
  'DOP',
];

const timezones = <String>[
  'America/Managua',
  'America/Costa_Rica',
  'America/Guatemala',
  'America/Tegucigalpa',
  'America/El_Salvador',
  'America/Panama',
  'America/Mexico_City',
  'America/Bogota',
  'America/Lima',
  'America/Santo_Domingo',
];

CountryOption countryByCode(String code) {
  return countries.firstWhere(
    (country) => country.code == code,
    orElse: () => countries.first,
  );
}
