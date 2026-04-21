import 'package:sample/bootstrap.dart';
import 'package:sample/flavors.dart';

/// Default entry point (production). Prefer explicit targets:
/// `flutter run --flavor development -t lib/main_development.dart`
/// `flutter run --flavor production -t lib/main_production.dart`
Future<void> main() => bootstrap(Flavor.production);
