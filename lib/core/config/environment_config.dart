import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  EnvironmentConfig._({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.revenueCatApiKey,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String revenueCatApiKey;

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
  }
}
