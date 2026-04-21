import 'package:flutter/widgets.dart';
import 'package:sample/app/app.dart';
import 'package:sample/core/config/environment_config.dart';
import 'package:sample/core/di/injection.dart';
import 'package:sample/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:sample/flavors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrap(Flavor flavor) async {
  F.appFlavor = flavor;
  WidgetsFlutterBinding.ensureInitialized();
  await EnvironmentConfig.initialize(flavorName: flavor.name);
  EnvironmentConfig.instance.validate();
  await Supabase.initialize(
    url: EnvironmentConfig.instance.supabaseUrl,
    anonKey: EnvironmentConfig.instance.supabaseAnonKey,
  );
  await configureDependencies();
  await getIt<SubscriptionRepository>().initialize();
  runApp(const SampleApp());
}
