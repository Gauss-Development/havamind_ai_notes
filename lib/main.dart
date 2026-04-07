import 'package:flutter/material.dart';
import 'package:sample/app/app.dart';
import 'package:sample/core/config/environment_config.dart';
import 'package:sample/core/di/injection.dart';
import 'package:sample/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvironmentConfig.initialize();
  EnvironmentConfig.instance.validate();
  await Supabase.initialize(
    url: EnvironmentConfig.instance.supabaseUrl,
    anonKey: EnvironmentConfig.instance.supabaseAnonKey,
  );
  await configureDependencies();
  await getIt<SubscriptionRepository>().initialize();
  runApp(const SampleApp());
}
