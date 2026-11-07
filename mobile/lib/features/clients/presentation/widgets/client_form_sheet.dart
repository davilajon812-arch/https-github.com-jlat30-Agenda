import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/client.dart';

/// Formulario de alta y edición de clientes.
class ClientFormSheet extends ConsumerStatefulWidget {
  const ClientFormSheet({super.key, required this.businessId, this.client});

  final String businessId;
  final Client? client;

  /// Muestra el formulario y devuelve el cliente guardado (o null si cancela).
  static Future<Client?> show(
    BuildContext context, {
    required String businessId,
    Client? client,
  }) {
    return showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ClientFormSheet(businessId: businessId, client: client),
    );
  }

  @override
  ConsumerState<ClientFormSheet> createState() => _ClientFormSheetState();
}

class _ClientFormSheetState extends ConsumerState<ClientFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.fullName ?? '');
    _phoneController = TextEditingController(text: widget.client?.phone ?? '');
    _notesController = TextEditingController(text: widget.client?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final repository = ref.read(clientsRepositoryProvider);

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final Client saved;
      if (_isEditing) {
        await repository.update(
          clientId: widget.client!.id,
          fullName: _nameController.text,
          phone: _phoneController.text,
          notes: _notesController.text,
        );
        saved = Client(
          id: widget.client!.id,
          businessId: widget.businessId,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      } else {
        saved = await repository.create(
          businessId: widget.businessId,
          fullName: _nameController.text,
          phone: _phoneController.text,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.code == '23505' ? l10n.clientHasVisits : l10n.errorSave;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.errorSave);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? l10n.commonEdit : l10n.clientNew,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.clientName),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.validationRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.clientPhone,
                hintText: '50588880000',
              ),
              validator: (value) {
                final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length < 8) return l10n.validationRequired;
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.clientNotes),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}
