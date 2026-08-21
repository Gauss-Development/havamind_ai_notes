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
  }) : _revenueCatApiKeyIos = revenueCatApiKeyIos,
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
  /// `assets/env/.env.[flavorName]` → `assets/env/.env`.
  ///
  /// `.env.example` is a template only and is never loaded at runtime. Using
  /// it as a fallback produced a fake host (`dfdfddf.supabase.co`) that passed
  /// the non-empty check and then failed DNS on sign-up.
  static Future<void> initialize({required String flavorName}) async {
    String? loadedFrom;
    for (final path in ['assets/env/.env.$flavorName', 'assets/env/.env']) {
      try {
        await dotenv.load(fileName: path);
        loadedFrom = path;
        break;
      } catch (_) {}
    }

    if (loadedFrom != null) {
      debugPrint('Environment loaded from $loadedFrom');
    }

    String read(String key) {
      final fromFile = loadedFrom == null ? null : dotenv.env[key]?.trim();
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

  /// Returns a configuration error message, or null when the values look usable.
  @visibleForTesting
  static String? supabaseConfigError(String url, String anonKey) {
    if (url.isEmpty || anonKey.isEmpty) {
      return 'Environment is not configured. Set SUPABASE_URL and '
          'SUPABASE_ANON_KEY in assets/env/.env.[flavor], assets/env/.env, '
          'or pass --dart-define. Copy assets/env/.env.example to the flavor '
          'file and fill in real values from Supabase Dashboard → Settings → API.';
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      return 'SUPABASE_URL is not a valid URL: "$url".';
    }
    final isLoopback = uri.host == 'localhost' || uri.host == '127.0.0.1';
    if (uri.scheme != 'https' && !(isLoopback && uri.scheme == 'http')) {
      return 'SUPABASE_URL must use https (or http for localhost).';
    }
    if (_isPlaceholderHost(uri.host) || _isPlaceholderAnonKey(anonKey)) {
      return 'SUPABASE_URL / SUPABASE_ANON_KEY still look like placeholder '
          'values from assets/env/.env.example. Copy that file to '
          'assets/env/.env.[flavor] and fill in the real project from '
          'Supabase Dashboard → Settings → API.';
    }
    return null;
  }

  static bool _isPlaceholderHost(String host) {
    final lower = host.toLowerCase();
    const known = {
      'dfdfddf.supabase.co',
      'your_project_ref.supabase.co',
      'your-project-ref.supabase.co',
      'your-project-id.supabase.co',
      'example.supabase.co',
    };
    if (known.contains(lower)) return true;
    return lower.startsWith('your_') || lower.startsWith('your-');
  }

  static bool _isPlaceholderAnonKey(String key) {
    final lower = key.toLowerCase();
    return lower == 'dfdfddf' ||
        lower.contains('your-anon') ||
        lower.contains('your_anon');
  }

  void validate() {
    final supabaseError = supabaseConfigError(supabaseUrl, supabaseAnonKey);
    if (supabaseError != null) {
      throw StateError(supabaseError);
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
    // `appl_` / `goog_` talk to the real stores. `test_` is RevenueCat's
    // Test Store and is the only way a development flavor (different bundle
    // id) can complete a purchase. Never ship `test_` in a store build.
    final isTestStoreKey = rcKey.startsWith('test_');
    final looksLikePlatformKey =
        rcKey.startsWith('appl_') || rcKey.startsWith('goog_');
    if (isTestStoreKey) {
      if (kReleaseMode) {
        throw StateError(
          'REVENUECAT_API_KEY is a Test Store key (test_…). Store builds '
          'must use an "appl_" iOS or "goog_" Android key from the '
          'RevenueCat dashboard.',
        );
      }
      debugPrint(
        'RevenueCat: using Test Store. Purchases will not go through '
        'Play Store / App Store.',
      );
    } else if (!looksLikePlatformKey) {
      final prefixLen = rcKey.length < 6 ? rcKey.length : 6;
      final message =
          'REVENUECAT_API_KEY does not look like a platform SDK key '
          '(expected an "appl_" iOS, "goog_" Android, or "test_" Test Store '
          'key, got "${rcKey.substring(0, prefixLen)}…"). Set '
          'REVENUECAT_API_KEY_IOS / REVENUECAT_API_KEY_ANDROID from the '
          'RevenueCat dashboard.';
      if (kReleaseMode) {
        throw StateError(message);
      }
      debugPrint('⚠️  $message');
    }
  }
}
