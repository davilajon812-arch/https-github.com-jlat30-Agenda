import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/billing/presentation/providers/billing_providers.dart';
import '../providers/app_providers.dart';

/// Verdadero cuando el plan activo debe mostrar anuncios.
///
/// Mientras el plan no se conoce devuelve `false`: nunca se muestra un anuncio
/// a una cuenta Pro por una condición de carga.
final shouldShowAdsProvider = Provider<bool>((ref) {
  final entitlements = ref.watch(entitelementsProvider).value;
  return entitlements != null && entitlements.plan.feature('ads');
});

/// Banner de anuncios para las cuentas del plan Gratis.
///
/// El plan se lee de `plans.features.ads` en el backend: si el plan activo no
/// muestra anuncios (Pro), el widget no ocupa espacio ni carga el SDK.
class FreePlanAdBanner extends ConsumerWidget {
  const FreePlanAdBanner({super.key, this.child});

  /// Contenido alternativo para las pruebas (en la app es el banner real).
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(shouldShowAdsProvider)) return const SizedBox.shrink();
    return child ?? const _BannerAdSlot();
  }
}

class _BannerAdSlot extends ConsumerStatefulWidget {
  const _BannerAdSlot();

  @override
  ConsumerState<_BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends ConsumerState<_BannerAdSlot> {
  static const _height = 50.0;

  BannerAd? _banner;
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _banner = BannerAd(
      adUnitId: ref.read(appConfigProvider).admobBannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _banner = null;
          if (!mounted) return;
          // Sin anuncio no se deja un hueco vacío.
          setState(() => _failed = true);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();

    return SizedBox(
      height: _height,
      width: double.infinity,
      child: _loaded && _banner != null
          ? Center(child: AdWidget(ad: _banner!))
          : const Center(
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
    );
  }
}
