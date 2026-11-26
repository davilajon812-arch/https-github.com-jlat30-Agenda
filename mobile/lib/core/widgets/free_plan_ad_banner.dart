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
  static const _fallbackHeight = 50.0;

  BannerAd? _banner;
  bool _loaded = false;
  bool _failed = false;
  int? _width;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Un banner de 320 px fijo deja bandas laterales en pantallas anchas; el
    // adaptativo ocupa el ancho real y Google calcula la altura.
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width == _width) return;
    _width = width;
    _loadBanner(width);
  }

  Future<void> _loadBanner(int width) async {
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width) ??
        AdSize.banner;

    // El ancho pudo cambiar mientras se pedía el tamaño.
    if (!mounted || width != _width) return;

    _banner?.dispose();
    final banner = BannerAd(
      adUnitId: ref.read(appConfigProvider).admobBannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || ad != _banner) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted || ad != _banner) return;
          // Sin anuncio no se deja un hueco vacío.
          setState(() {
            _banner = null;
            _failed = true;
          });
        },
      ),
    );

    setState(() {
      _banner = banner;
      _loaded = false;
      _failed = false;
    });
    await banner.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();

    final height = _banner?.size.height.toDouble() ?? _fallbackHeight;
    return SizedBox(
      height: height,
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
