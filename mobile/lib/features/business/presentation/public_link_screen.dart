import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/app_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/business.dart';
import 'providers/business_providers.dart';

/// Enlace público con el que los clientes reservan solos.
class PublicLinkScreen extends ConsumerStatefulWidget {
  const PublicLinkScreen({super.key});

  @override
  ConsumerState<PublicLinkScreen> createState() => _PublicLinkScreenState();
}

class _PublicLinkScreenState extends ConsumerState<PublicLinkScreen> {
  bool _saving = false;

  Future<void> _toggle(Business business, bool enabled) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(businessRepositoryProvider).setPublicBookingEnabled(
            businessId: business.id,
            enabled: enabled,
          );
      ref.invalidate(myBusinessesProvider);
    } on PostgrestException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorSave)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final membership = ref.watch(activeBusinessProvider);

    if (membership == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.publicLinkTitle)),
        body: Center(child: Text(l10n.errorGeneric)),
      );
    }

    final business = membership.business;
    final link =
        '${ref.watch(appConfigProvider).publicBase}/r/${business.slug}';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.publicLinkTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(l10n.publicLinkIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: business.publicBookingEnabled,
                  onChanged: _saving
                      ? null
                      : (value) => _toggle(business, value),
                  title: Text(l10n.publicLinkEnabled),
                  subtitle: Text(
                    business.publicBookingEnabled
                        ? l10n.publicLinkEnabledHint
                        : l10n.publicLinkDisabledHint,
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _LinkBox(link: link, business: business),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (business.publicBookingEnabled) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(l10n.publicLinkQrHint, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    QrImageView(
                      data: link,
                      size: 190,
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.publicLinkHowToTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.publicLinkHowTo, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkBox extends StatelessWidget {
  const _LinkBox({required this.link, required this.business});

  final String link;
  final Business business;

  Future<void> _copy(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.publicLinkCopied)),
    );
  }

  Future<void> _share(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await SharePlus.instance.share(
      ShareParams(
        subject: business.name,
        text: l10n.publicLinkShareText(business.name, link),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final opened = await launchUrl(
      Uri.parse(link),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(
            link,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _share(context),
                icon: const Icon(Icons.share_outlined),
                label: Text(l10n.publicLinkShare),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => _copy(context),
              tooltip: l10n.publicLinkCopy,
              icon: const Icon(Icons.copy_all_outlined),
            ),
            const SizedBox(width: 4),
            IconButton.filledTonal(
              onPressed: () => _open(context),
              tooltip: l10n.publicLinkOpen,
              icon: const Icon(Icons.open_in_new),
            ),
          ],
        ),
      ],
    );
  }
}
