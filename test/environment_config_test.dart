import 'package:flutter_test/flutter_test.dart';
import 'package:sample/core/config/environment_config.dart';

void main() {
  group('EnvironmentConfig.supabaseConfigError', () {
    test('rejects empty url and key', () {
      expect(
        EnvironmentConfig.supabaseConfigError('', ''),
        contains('not configured'),
      );
    });

    test('rejects the old .env.example placeholder host', () {
      final error = EnvironmentConfig.supabaseConfigError(
        'https://dfdfddf.supabase.co',
        'dfdfddf',
      );
      expect(error, isNotNull);
      expect(error, contains('placeholder'));
    });

    test('rejects the documented template host', () {
      final error = EnvironmentConfig.supabaseConfigError(
        'https://YOUR_PROJECT_REF.supabase.co',
        'your-anon-key',
      );
      expect(error, isNotNull);
      expect(error, contains('placeholder'));
    });

    test('rejects a non-https remote url', () {
      final error = EnvironmentConfig.supabaseConfigError(
        'http://epicucteevjkiqsthqzd.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.sig',
      );
      expect(error, contains('https'));
    });

    test('accepts a real supabase project url and jwt-shaped key', () {
      expect(
        EnvironmentConfig.supabaseConfigError(
          'https://epicucteevjkiqsthqzd.supabase.co',
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.sig',
        ),
        isNull,
      );
    });

    test('accepts local supabase over http', () {
      expect(
        EnvironmentConfig.supabaseConfigError(
          'http://127.0.0.1:54321',
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.sig',
        ),
        isNull,
      );
    });
  });
}
