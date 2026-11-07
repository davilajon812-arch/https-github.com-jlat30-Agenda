import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../business/presentation/providers/business_providers.dart';
import './providers/clients_providers.dart';
import 'widgets/client_form_sheet.dart';

/// Listado de clientes con búsqueda por nombre o teléfono.
class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(activeBusinessProvider);

    if (membership == null) {
      return const SizedBox.shrink();
    }

    final businessId = membership.business.id;
    final query = (businessId: businessId, search: _search);
    final clients = ref.watch(clientsProvider(query));

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.clientsSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      ),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(clientsProvider(query)),
              child: clients.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorView(
                  message: l10n.errorGeneric,
                  retryLabel: l10n.commonRetry,
                  onRetry: () => ref.invalidate(clientsProvider(query)),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        Icon(
                          Icons.people_outline,
                          size: 56,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.clientsEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final client = items[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(client.initials)),
                        title: Text(client.fullName),
                        subtitle: Text(client.phone),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/clients/${client.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created =
              await ClientFormSheet.show(context, businessId: businessId);
          if (created != null) ref.invalidate(clientsProvider(query));
        },
        icon: const Icon(Icons.person_add_alt),
        label: Text(l10n.clientNew),
      ),
    );
  }
}
