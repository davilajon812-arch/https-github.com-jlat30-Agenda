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
    required this.dialCode,
    required this.timezone,
    this.extraTimezones = const [],
  });

  final String code;
  final String name;
  final String currency;

  /// Prefijo telefónico sin `+` (Nicaragua: 505).
  final String dialCode;

  /// Zona horaria principal, la que se asigna al elegir el país.
  final String timezone;

  /// Otras zonas del país (México, Chile, Ecuador…).
  final List<String> extraTimezones;

  List<String> get allTimezones => [timezone, ...extraTimezones];
}

const countries = <CountryOption>[
  CountryOption(
    code: 'NI',
    name: 'Nicaragua',
    currency: 'NIO',
    dialCode: '505',
    timezone: 'America/Managua',
  ),
  CountryOption(
    code: 'CR',
    name: 'Costa Rica',
    currency: 'CRC',
    dialCode: '506',
    timezone: 'America/Costa_Rica',
  ),
  CountryOption(
    code: 'GT',
    name: 'Guatemala',
    currency: 'GTQ',
    dialCode: '502',
    timezone: 'America/Guatemala',
  ),
  CountryOption(
    code: 'HN',
    name: 'Honduras',
    currency: 'HNL',
    dialCode: '504',
    timezone: 'America/Tegucigalpa',
  ),
  CountryOption(
    code: 'SV',
    name: 'El Salvador',
    currency: 'USD',
    dialCode: '503',
    timezone: 'America/El_Salvador',
  ),
  CountryOption(
    code: 'PA',
    name: 'Panamá',
    currency: 'USD',
    dialCode: '507',
    timezone: 'America/Panama',
  ),
  CountryOption(
    code: 'MX',
    name: 'México',
    currency: 'MXN',
    dialCode: '52',
    timezone: 'America/Mexico_City',
    extraTimezones: [
      'America/Tijuana',
      'America/Hermosillo',
      'America/Chihuahua',
      'America/Cancun',
    ],
  ),
  CountryOption(
    code: 'CO',
    name: 'Colombia',
    currency: 'COP',
    dialCode: '57',
    timezone: 'America/Bogota',
  ),
  CountryOption(
    code: 'PE',
    name: 'Perú',
    currency: 'PEN',
    dialCode: '51',
    timezone: 'America/Lima',
  ),
  CountryOption(
    code: 'DO',
    name: 'República Dominicana',
    currency: 'DOP',
    dialCode: '1809',
    timezone: 'America/Santo_Domingo',
  ),
  CountryOption(
    code: 'AR',
    name: 'Argentina',
    currency: 'ARS',
    dialCode: '54',
    timezone: 'America/Argentina/Buenos_Aires',
  ),
  CountryOption(
    code: 'CL',
    name: 'Chile',
    currency: 'CLP',
    dialCode: '56',
    timezone: 'America/Santiago',
    extraTimezones: ['Pacific/Easter'],
  ),
  CountryOption(
    code: 'EC',
    name: 'Ecuador',
    currency: 'USD',
    dialCode: '593',
    timezone: 'America/Guayaquil',
    extraTimezones: ['Pacific/Galapagos'],
  ),
  CountryOption(
    code: 'BO',
    name: 'Bolivia',
    currency: 'BOB',
    dialCode: '591',
    timezone: 'America/La_Paz',
  ),
  CountryOption(
    code: 'PY',
    name: 'Paraguay',
    currency: 'PYG',
    dialCode: '595',
    timezone: 'America/Asuncion',
  ),
  CountryOption(
    code: 'UY',
    name: 'Uruguay',
    currency: 'UYU',
    dialCode: '598',
    timezone: 'America/Montevideo',
  ),
  CountryOption(
    code: 'VE',
    name: 'Venezuela',
    currency: 'VES',
    dialCode: '58',
    timezone: 'America/Caracas',
  ),
  CountryOption(
    code: 'PR',
    name: 'Puerto Rico',
    currency: 'USD',
    dialCode: '1787',
    timezone: 'America/Puerto_Rico',
  ),
];

/// Monedas disponibles, derivadas de los países.
///
/// Se derivan a propósito: así no puede quedar un país sin su moneda por
/// olvidar tocar una segunda lista.
List<String> get currencies {
  final seen = <String>{};
  return [
    for (final country in countries)
      if (seen.add(country.currency)) country.currency,
  ];
}

/// Zonas horarias disponibles, derivadas de los países (principal + extra).
List<String> get timezones {
  final seen = <String>{};
  return [
    for (final country in countries)
      for (final zone in country.allTimezones)
        if (seen.add(zone)) zone,
  ];
}

CountryOption countryByCode(String code) {
  return countries.firstWhere(
    (country) => country.code == code,
    orElse: () => countries.first,
  );
}
