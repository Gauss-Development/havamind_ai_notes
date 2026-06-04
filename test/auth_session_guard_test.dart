import 'package:flutter_test/flutter_test.dart';
import 'package:sample/core/error/auth_session_guard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('isAuthSessionError', () {
    test('returns true for AuthException', () {
      expect(
        isAuthSessionError(const AuthException('Session expired')),
        isTrue,
      );
    });

    test('returns true for PGRST301 JWT errors', () {
      expect(
        isAuthSessionError(
          PostgrestException(
            message: 'JWT expired',
            code: 'PGRST301',
          ),
        ),
        isTrue,
      );
    });

    test('returns false for 42501 insufficient privilege (RLS)', () {
      expect(
        isAuthSessionError(
          PostgrestException(
            message: 'permission denied for table audio_notes',
            code: '42501',
          ),
        ),
        isFalse,
      );
    });

    test('returns true when Postgrest message mentions jwt', () {
      expect(
        isAuthSessionError(
          PostgrestException(message: 'invalid JWT', code: 'XX000'),
        ),
        isTrue,
      );
    });

    test('returns false for unrelated errors', () {
      expect(isAuthSessionError(Exception('network down')), isFalse);
    });
  });
}
