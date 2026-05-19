import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  EnvironmentConfig._({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.revenueCatApiKey,
    required this.privacyPolicyUrl,
    required this.termsOfServiceUrl,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String revenueCatApiKey;
  /// Public privacy policy (HTTPS). Optional; Profile shows Legal when set.
  final String privacyPolicyUrl;
  /// Terms of service (HTTPS). Optional.
  final String termsOfServiceUrl;

  static late final EnvironmentConfig instance;

  /// Loads the first existing file among:
  /// `assets/env/.env.[flavorName]` → `.env` → `.env.example`.
  static Future<void> initialize({required String flavorName}) async {
    Future<bool> loadFirst(Iterable<String> paths) async {
      for (final path in paths) {
        try {
          await dotenv.load(fileName: path);
          return true;
        } catch (_) {}
      }
      return false;
    }

    await loadFirst([
      'assets/env/.env.$flavorName',
      'assets/env/.env',
      'assets/env/.env.example',
    ]);

    String read(String key) {
      final fromFile = dotenv.env[key]?.trim();
      if (fromFile != null && fromFile.isNotEmpty) {
        return fromFile;
      }
      return String.fromEnvironment(key, defaultValue: '');
    }

    instance = EnvironmentConfig._(
      supabaseUrl: read('SUPABASE_URL'),
      supabaseAnonKey: read('SUPABASE_ANON_KEY'),
      revenueCatApiKey: read('REVENUECAT_API_KEY'),
      privacyPolicyUrl: read('PRIVACY_POLICY_URL'),
      termsOfServiceUrl: read('TERMS_OF_SERVICE_URL'),
    );
  }

  void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Environment is not configured. Set SUPABASE_URL and '
        'SUPABASE_ANON_KEY in assets/env/.env.[flavor], assets/env/.env, '
        'or pass --dart-define.',
      );
    }
    if (revenueCatApiKey.isEmpty) {
      throw StateError(
        'REVENUECAT_API_KEY is not configured. Without it RevenueCat '
        'silently misconfigures and every purchase fails at the moment '
        'the user taps Subscribe. Set it in '
        'assets/env/.env.[flavor], assets/env/.env, or pass --dart-define.',
      );
    }
  }
}
