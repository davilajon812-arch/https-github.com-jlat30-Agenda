import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// Entrada del flavor prod: build de Google Play.
Future<void> main() =>
    bootstrap(config: AppConfig.fromEnvironment(defaultFlavor: AppFlavor.prod));
