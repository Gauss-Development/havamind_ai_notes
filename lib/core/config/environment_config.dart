import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  EnvironmentConfig._({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required String revenueCatApiKeyIos,
    required String revenueCatApiKeyAndroid,
    required String revenueCatApiKeyLegacy,
    required this.privacyPolicyUrl,
    required this.termsOfServiceUrl,
  })  : _revenueCatApiKeyIos = revenueCatApiKeyIos,
        _revenueCatApiKeyAndroid = revenueCatApiKeyAndroid,
        _revenueCatApiKeyLegacy = revenueCatApiKeyLegacy;

  final String supabaseUrl;
  final String supabaseAnonKey;

  // RevenueCat publishes a distinct public SDK key per platform: `appl_` for
  // Apple, `goog_` for Google. `_revenueCatApiKeyLegacy` supports older env
  // files that set a single `REVENUECAT_API_KEY`.
  final String _revenueCatApiKeyIos;
  final String _revenueCatApiKeyAndroid;
  final String _revenueCatApiKeyLegacy;

  /// Public privacy policy (HTTPS). Optional; Profile shows Legal when set.
  final String privacyPolicyUrl;
  /// Terms of service (HTTPS). Optional.
  final String termsOfServiceUrl;

  static late final EnvironmentConfig instance;

  /// Platform-specific RevenueCat public SDK key, falling back to the legacy
  /// single-key variable when the per-platform key is not set.
  String get revenueCatApiKey {
    if (Platform.isIOS || Platform.isMacOS) {
      return _revenueCatApiKeyIos.isNotEmpty
          ? _revenueCatApiKeyIos
          : _revenueCatApiKeyLegacy;
    }
    if (Platform.isAndroid) {
      return _revenueCatApiKeyAndroid.isNotEmpty
          ? _revenueCatApiKeyAndroid
          : _revenueCatApiKeyLegacy;
    }
    // Tests / desktop hosts: prefer the legacy key, then whatever is set.
    if (_revenueCatApiKeyLegacy.isNotEmpty) return _revenueCatApiKeyLegacy;
    return _revenueCatApiKeyIos.isNotEmpty
        ? _revenueCatApiKeyIos
        : _revenueCatApiKeyAndroid;
  }

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
      revenueCatApiKeyIos: read('REVENUECAT_API_KEY_IOS'),
      revenueCatApiKeyAndroid: read('REVENUECAT_API_KEY_ANDROID'),
      revenueCatApiKeyLegacy: read('REVENUECAT_API_KEY'),
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
    final rcKey = revenueCatApiKey;
    if (rcKey.isEmpty) {
      throw StateError(
        'RevenueCat API key is not configured. Without it RevenueCat '
        'silently misconfigures and every purchase fails at the moment '
        'the user taps Subscribe. Set REVENUECAT_API_KEY_IOS / '
        'REVENUECAT_API_KEY_ANDROID (or legacy REVENUECAT_API_KEY) in '
        'assets/env/.env.[flavor], assets/env/.env, or pass --dart-define.',
      );
    }
    // A real public SDK key is `appl_` (iOS) or `goog_` (Android). A `test_`
    // or otherwise malformed key silently misconfigures RevenueCat and every
    // purchase fails. Fail fast in release; only warn in debug so local
    // development can still run against a sandbox key.
    final looksLikePlatformKey =
        rcKey.startsWith('appl_') || rcKey.startsWith('goog_');
    if (!looksLikePlatformKey) {
      final prefixLen = rcKey.length < 6 ? rcKey.length : 6;
      final message =
          'REVENUECAT_API_KEY does not look like a platform SDK key '
          '(expected an "appl_" iOS or "goog_" Android key, got '
          '"${rcKey.substring(0, prefixLen)}…"). Set REVENUECAT_API_KEY_IOS / '
          'REVENUECAT_API_KEY_ANDROID with the real keys from the RevenueCat '
          'dashboard.';
      if (kReleaseMode) {
        throw StateError(message);
      }
      debugPrint('⚠️  $message');
    }
  }
}
