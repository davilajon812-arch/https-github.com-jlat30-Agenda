import 'dart:async';

import 'package:flutter/foundation.dart';

/// Puente entre un `Stream` y el `Listenable` que espera go_router.
///
/// Cada evento dispara una reevaluación del `redirect`.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen(
      (_) => notifyListeners(),
      onError: (Object error) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
