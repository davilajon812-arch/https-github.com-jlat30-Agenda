import 'dart:convert';

import 'package:citurno/core/api/agenda_api.dart';
import 'package:citurno/core/providers/app_providers.dart';
import 'package:citurno/features/billing/domain/plan.dart';
import 'package:citurno/features/billing/presentation/providers/billing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

const _businessId = 'b1';
const _productId = 'citurno_pro_mensual';

Entitlements _proPlan() {
  return Entitlements.fromJson({
    'business_id': _businessId,
    'plan': {
      'id': 'pro',
      'name': 'Pro',
      'features': {'ads': false},
    },
    'status': 'active',
    'source': 'play',
    'auto_renewing': true,
    'current_period_end': null,
    'product_id': _productId,
    'usage': {
      'staff_count': 1,
      'appointments_this_month': 1,
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

/// Cliente HTTP que nunca responde, para probar el límite de tiempo.
class _SilentClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return Future<http.StreamedResponse>.delayed(
      const Duration(seconds: 5),
      () => http.StreamedResponse(Stream.value(utf8.encode('[]')), 200),
    );
  }
}

/// API falsa: controla si la verificación de la compra funciona.
class _FakeAgendaApi extends AgendaApi {
  _FakeAgendaApi({required super.supabaseClient})
      : super(baseUrl: 'https://api.test');

  bool fails = true;
  int verifyCalls = 0;

  @override
  Future<Entitlements> verifyPurchase({
    required String businessId,
    required String productId,
    required String purchaseToken,
  }) async {
    verifyCalls++;
    if (fails) {
      throw AgendaApiException('La conexión tardó demasiado.', statusCode: 408);
    }
    return _proPlan();
  }
}

void main() {
  late SupabaseClient supabase;

  setUpAll(() {
    supabase = SupabaseClient('https://proyecto.supabase.co', 'anon-key');
  });

  group('AgendaApi', () {
    test('una petición que no responde falla por tiempo', () async {
      final api = AgendaApi(
        baseUrl: 'https://api.test',
        supabaseClient: supabase,
        httpClient: _SilentClient(),
        timeout: const Duration(milliseconds: 50),
      );

      await expectLater(
        api.plans(),
        throwsA(
          isA<AgendaApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            408,
          ),
        ),
      );
    });

    test('verificar una compra usa un plazo más largo', () async {
      final api = AgendaApi(
        baseUrl: 'https://api.test',
        supabaseClient: supabase,
        httpClient: _SilentClient(),
        timeout: const Duration(milliseconds: 10),
        verifyTimeout: const Duration(milliseconds: 50),
      );

      // El plazo corto de lectura no aplica aquí: manda verifyTimeout.
      await expectLater(
        api.verifyPurchase(
          businessId: _businessId,
          productId: _productId,
          purchaseToken: 'tok',
        ),
        throwsA(isA<AgendaApiException>()),
      );
    });
  });

  group('PurchaseController', () {
    late _FakeAgendaApi api;
    late ProviderContainer container;
    late int completadas;

    setUp(() {
      api = _FakeAgendaApi(supabaseClient: supabase);
      completadas = 0;
      container = ProviderContainer(
        overrides: [agendaApiProvider.overrideWithValue(api)],
      );
    });

    tearDown(() => container.dispose());

    Future<bool> verificar() {
      return container.read(purchaseControllerProvider.notifier).verifyAndComplete(
            businessId: _businessId,
            productId: _productId,
            purchaseToken: 'tok-1',
            complete: () async => completadas++,
          );
    }

    test('si la verificación falla la compra NO se completa', () async {
      final ok = await verificar();

      expect(ok, isFalse);
      expect(completadas, 0, reason: 'completar antes de verificar hace perder el cobro');
      final estado = container.read(purchaseControllerProvider);
      expect(estado.hasPendingVerification, isTrue);
      expect(estado.error, isNotNull);
    });

    test('reintentar activa el plan y completa la compra', () async {
      await verificar();

      api.fails = false;
      final ok =
          await container.read(purchaseControllerProvider.notifier).retryVerification();

      expect(ok, isTrue);
      expect(api.verifyCalls, 2);
      expect(completadas, 1);
      final estado = container.read(purchaseControllerProvider);
      expect(estado.hasPendingVerification, isFalse);
      expect(estado.lastPlanId, 'pro');
    });

    test('sin compra pendiente el reintento no hace nada', () async {
      final ok =
          await container.read(purchaseControllerProvider.notifier).retryVerification();

      expect(ok, isFalse);
      expect(api.verifyCalls, 0);
    });

    test('un pago diferido se marca como pendiente', () {
      container.read(purchaseControllerProvider.notifier).markPaymentPending();

      expect(container.read(purchaseControllerProvider).paymentPending, isTrue);
    });
  });
}
