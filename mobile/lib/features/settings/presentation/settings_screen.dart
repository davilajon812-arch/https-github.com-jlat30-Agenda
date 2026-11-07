import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/preferences/preferences_controller.dart';
import '../../../core/providers/app_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../business/presentation/providers/business_providers.dart';

/// Ajustes de la app: negocio, apariencia, idioma y cuenta.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preferences = ref.watch(preferencesProvider);
    final membership = ref.watch(activeBusinessProvider);
    final email = ref.watch(currentUserProvider)?.email;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (membership != null)
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(membership.business.name),
            subtitle: Text('${l10n.settingsBusiness} · ${membership.role}'),
          ),
        if (email != null)
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(email),
            subtitle: Text(l10n.settingsAccount),
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.content_cut),
          title: Text(l10n.servicesManagement),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/services'),
        ),
        ListTile(
          leading: const Icon(Icons.badge_outlined),
          title: Text(l10n.staffManagement),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/staff'),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.settingsAppearance,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        RadioGroup<ThemeMode>(
          groupValue: preferences.themeMode,
          onChanged: (mode) {
            if (mode != null) {
              ref.read(preferencesProvider.notifier).setThemeMode(mode);
            }
          },
          child: Column(
            children: [
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                title: Text(l10n.settingsThemeSystem),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                title: Text(l10n.settingsThemeLight),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                title: Text(l10n.settingsThemeDark),
              ),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.settingsLanguage,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        RadioGroup<String>(
          groupValue: preferences.localeCode ?? '',
          onChanged: (code) {
            ref
                .read(preferencesProvider.notifier)
                .setLocale(code == null || code.isEmpty ? null : code);
          },
          child: Column(
            children: [
              RadioListTile<String>(
                value: 'es',
                title: Text(l10n.settingsLanguageSpanish),
              ),
              RadioListTile<String>(
                value: 'en',
                title: Text(l10n.settingsLanguageEnglish),
              ),
            ],
          ),
        ),
        const Divider(),
        ListTile(
          leading: Icon(
            Icons.logout,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            l10n.settingsSignOut,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          onTap: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
    );
  }
}
