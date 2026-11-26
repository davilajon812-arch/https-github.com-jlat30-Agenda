import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Botón "Continuar con Google".
///
/// Se pinta con el estilo de Google (fondo blanco, texto oscuro) para que se
/// reconozca como el acceso de siempre, aunque la app use tema oscuro.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.busy = false,
  });

  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F1F1F),
        side: const BorderSide(color: Color(0xFFDADCE0)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: busy
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _GoogleGlyph(),
                const SizedBox(width: 12),
                Text(
                  l10n.authContinueWithGoogle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Separador entre el acceso con Google y el formulario de correo.
class AuthProvidersDivider extends StatelessWidget {
  const AuthProvidersDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Row(
      children: [
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(AppLocalizations.of(context).authOrEmail, style: style),
        ),
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
      ],
    );
  }
}

/// La "G" del logotipo, dibujada para no depender de un asset.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      width: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
          height: 1,
        ),
      ),
    );
  }
}
