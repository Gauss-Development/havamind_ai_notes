import 'package:supabase_flutter/supabase_flutter.dart';

/// Heuristic: does [error] look like a permanent auth failure that
/// should force the session out? Covers revoked refresh tokens, expired
/// JWTs, and explicit `AuthException`s the Supabase SDK propagates.
bool isAuthSessionError(Object error) {
  if (error is AuthException) return true;
  if (error is PostgrestException) {
    final code = error.code ?? '';
    // PGRST301 = JWT expired/invalid. Do not treat 42501 (insufficient_privilege)
    // as a session death — that is usually RLS/permission, not auth expiry.
    if (code == 'PGRST301') return true;
    final msg = error.message.toLowerCase();
    return msg.contains('jwt') ||
        msg.contains('invalid refresh') ||
        msg.contains('not authenticated');
  }
  return false;
}

/// Forces a sign-out so Supabase fires its `signedOut` change-event,
/// which routes the user back to the login page. Best-effort: any
/// failure here is swallowed because we're already in a broken state.
Future<void> forceSignOutAfterAuthError(SupabaseClient client) async {
  try {
    await client.auth.signOut();
  } catch (_) {}
}
