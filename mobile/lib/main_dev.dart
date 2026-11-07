import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// Entrada del flavor dev: `flutter run --flavor dev -t lib/main_dev.dart`.
Future<void> main() =>
    bootstrap(config: AppConfig.fromEnvironment(defaultFlavor: AppFlavor.dev));
