import 'package:agenda_pro/core/widgets/free_plan_ad_banner.dart';
import 'package:agenda_pro/features/billing/domain/plan.dart';
import 'package:agenda_pro/features/billing/presentation/providers/billing_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Entitlements _entitlements({required bool ads}) {
  return Entitlements.fromJson({
    'business_id': 'b1',
    'plan': {
      'id': ads ? 'free' : 'pro',
      'name': ads ? 'Gratis' : 'Pro',
      'features': {'ads': ads},
    },
    'status': 'active',
    'source': 'manual',
    'auto_renewing': false,
    'current_period_end': null,
    'product_id': null,
    'usage': {
      'staff_count': 1,
      'appointments_this_month': 0,
      'messages_this_month': 0,
    },
    'remaining': {
      'staff': null,
      'appointments_per_month': null,
      'messages_per_month': 0,
    },
    'upgrade_to': null,
  });
}

Widget _banner({Entitlements? entitlements}) {
  return ProviderScope(
    overrides: [
      if (entitlements != null)
        entitelementsProvider.overrideWith((ref) async => entitlements),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: FreePlanAdBanner(child: SizedBox(key: Key('anuncio'))),
      ),
    ),
  );
}

void main() {
  testWidgets('el plan Gratis muestra el espacio del anuncio', (tester) async {
    await tester.pumpWidget(_banner(entitlements: _entitlements(ads: true)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('anuncio')), findsOneWidget);
  });

  testWidgets('el plan Pro no muestra anuncios', (tester) async {
    await tester.pumpWidget(_banner(entitlements: _entitlements(ads: false)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('anuncio')), findsNothing);
  });

  testWidgets('sin conocer el plan no se muestra nada', (tester) async {
    await tester.pumpWidget(_banner());
    await tester.pump();

    expect(find.byKey(const Key('anuncio')), findsNothing);
  });

  test('shouldShowAdsProvider sigue la marca del plan', () async {
    final free = ProviderContainer(
      overrides: [
        entitelementsProvider.overrideWith(
          (ref) async => _entitlements(ads: true),
        ),
      ],
    );
    addTearDown(free.dispose);
    await free.read(entitelementsProvider.future);
    expect(free.read(shouldShowAdsProvider), isTrue);

    final pro = ProviderContainer(
      overrides: [
        entitelementsProvider.overrideWith(
          (ref) async => _entitlements(ads: false),
        ),
      ],
    );
    addTearDown(pro.dispose);
    await pro.read(entitelementsProvider.future);
    expect(pro.read(shouldShowAdsProvider), isFalse);
  });
}
