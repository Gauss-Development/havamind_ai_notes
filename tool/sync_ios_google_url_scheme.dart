// Syncs CFBundleURLSchemes in ios/Runner/Info.plist from GOOGLE_WEB_CLIENT_ID in assets/env/.env
// (reversed Web OAuth client ID — same flow Supabase documents for mobile + web client only).
//
// Run after changing .env:
//   dart run tool/sync_ios_google_url_scheme.dart

import 'dart:io';

import 'package:sample/core/config/google_oauth_client_id.dart';

void main() {
  final envFile = File('assets/env/.env');
  if (!envFile.existsSync()) {
    stderr.writeln('Missing assets/env/.env — copy from .env.example');
    exit(1);
  }
  final env = envFile.readAsStringSync();
  final clientId = _parseEnv(env, 'GOOGLE_WEB_CLIENT_ID');
  if (clientId.isEmpty) {
    stderr.writeln('GOOGLE_WEB_CLIENT_ID is empty in assets/env/.env');
    exit(1);
  }
  final scheme = reversedGoogleOauthUrlScheme(clientId);
  final plist = File('ios/Runner/Info.plist');
  if (!plist.existsSync()) {
    stderr.writeln('Missing ios/Runner/Info.plist');
    exit(1);
  }
  var text = plist.readAsStringSync();
  final pattern = RegExp(
    r'(<key>CFBundleURLSchemes</key>\s*<array>\s*<string>)([^<]*)(</string>)',
  );
  if (!pattern.hasMatch(text)) {
    stderr.writeln('Could not find CFBundleURLSchemes string in Info.plist');
    exit(1);
  }
  text = text.replaceFirstMapped(pattern, (m) => '${m[1]}$scheme${m[3]}');
  plist.writeAsStringSync(text);
  stdout.writeln('Updated iOS URL scheme to: $scheme');
}

String _parseEnv(String content, String key) {
  for (final line in content.split('\n')) {
    final t = line.trim();
    if (t.isEmpty || t.startsWith('#')) continue;
    final idx = t.indexOf('=');
    if (idx <= 0) continue;
    final k = t.substring(0, idx).trim();
    if (k != key) continue;
    return t.substring(idx + 1).trim();
  }
  return '';
}
