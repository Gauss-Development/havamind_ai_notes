// Helpers for Google OAuth client ID formatting (optional tooling, e.g. tool/sync_ios_google_url_scheme.dart).
// App auth uses Supabase OAuth; these helpers are not required at runtime.
// Valid client IDs end with .apps.googleusercontent.com (not client secrets).

bool isGoogleOAuthClientIdFormat(String value) {
  final v = value.trim();
  return v.endsWith('.apps.googleusercontent.com');
}

// Reversed client ID for ios/Runner/Info.plist CFBundleURLSchemes (same for Web client ID).
String reversedGoogleOauthUrlScheme(String oauthClientId) {
  const suffix = '.apps.googleusercontent.com';
  final trimmed = oauthClientId.trim();
  if (!trimmed.endsWith(suffix)) {
    throw FormatException(
      'Client ID must end with $suffix (OAuth client from Google Cloud Console, '
      'not a client secret).',
    );
  }
  final prefix = trimmed.substring(0, trimmed.length - suffix.length);
  return 'com.googleusercontent.apps.$prefix';
}
