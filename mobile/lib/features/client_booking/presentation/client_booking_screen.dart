import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/app_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/booking_link.dart';

/// Entrada pública para el cliente: abre la página de reservas de un negocio.
///
/// No crea cuentas ni duplica el flujo de reserva: la página web sigue siendo
/// el único lugar donde se agenda. Aquí solo se lleva al cliente a su enlace.
class ClientBookingScreen extends ConsumerStatefulWidget {
  const ClientBookingScreen({super.key, this.openLink});

  /// Permite inyectar el lanzador en las pruebas.
  final Future<bool> Function(Uri uri)? openLink;

  static const lastLinkKey = 'client_last_booking_url';

  @override
  ConsumerState<ClientBookingScreen> createState() =>
      _ClientBookingScreenState();
}

class _ClientBookingScreenState extends ConsumerState<ClientBookingScreen> {
  final _controller = TextEditingController();
  String? _error;
  String? _lastLink;

  @override
  void initState() {
    super.initState();
    _lastLink =
        ref.read(sharedPreferencesProvider).getString(ClientBookingScreen.lastLinkKey);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(String input) async {
    final l10n = AppLocalizations.of(context);
    final slug = parseBookingSlug(input);
    if (slug == null) {
      setState(() => _error = l10n.clientBookingInvalid);
      return;
    }
    setState(() => _error = null);

    final uri = Uri.tryParse(input.trim());
    final token = parseBookingToken(input);
    final target = uri != null && uri.hasScheme
        ? uri
        : Uri.parse(
            bookingLink(ref.read(appConfigProvider).publicBase, slug),
          );
    final finalUri =
        token != null && !target.queryParameters.containsKey('c')
            ? target.replace(queryParameters: {...target.queryParameters, 'c': token})
            : target;

    final open = widget.openLink ?? _launchExternally;
    final opened = await open(finalUri);
    if (!opened) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric)),
      );
      return;
    }

    await ref
        .read(sharedPreferencesProvider)
        .setString(ClientBookingScreen.lastLinkKey, finalUri.toString());
    if (!mounted) return;
    setState(() => _lastLink = finalUri.toString());
  }

  static Future<bool> _launchExternally(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.clientBookingTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Icon(
            Icons.event_available,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.clientBookingIntro,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_lastLink != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(l10n.clientBookingLast),
                subtitle: Text(
                  Uri.parse(_lastLink!).path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _open(_lastLink!),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            autofillHints: const [AutofillHints.url],
            decoration: InputDecoration(
              labelText: l10n.clientBookingLinkLabel,
              hintText: l10n.clientBookingLinkHint,
              prefixIcon: const Icon(Icons.link),
              border: const OutlineInputBorder(),
              errorText: _error,
              errorMaxLines: 2,
            ),
            onSubmitted: _open,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _open(_controller.text),
            icon: const Icon(Icons.open_in_browser),
            label: Text(l10n.clientBookingOpen),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.clientBookingWhy,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
