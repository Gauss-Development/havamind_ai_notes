import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sample/features/auth/data/models/user_profile_mapper.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<UserProfile> upsertFromSupabaseUser(User user) async {
    final now = DateTime.now().toUtc();
    final meta = user.userMetadata ?? <String, dynamic>{};
    final fullName = meta['full_name'] as String? ?? meta['name'] as String?;
    final avatarUrl =
        meta['avatar_url'] as String? ?? meta['picture'] as String?;

    final lastSignIn = user.lastSignInAt != null
        ? DateTime.tryParse(user.lastSignInAt!)
        : null;

    final payload = <String, dynamic>{
      'id': user.id,
      'email': user.email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'last_sign_in_at': (lastSignIn ?? now).toIso8601String(),
    };

    await _client.from('profiles').upsert(payload, onConflict: 'id');

    final row = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) {
      return UserProfileMapper.fromSupabaseUser(user);
    }
    return UserProfileMapper.fromRow(Map<String, dynamic>.from(row));
  }

  Future<UserProfile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return UserProfileMapper.fromRow(Map<String, dynamic>.from(row));
  }

  /// Mirrors the RevenueCat tier into `profiles.subscription_tier` so the
  /// Edge Functions that gate usage (`process-audio-note`, `refine-plan`)
  /// can read it server-side. Best-effort: a transient failure is
  /// swallowed so it never breaks the auth/subscription UI.
  Future<void> updateSubscriptionTier(String tier) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client
          .from('profiles')
          .update({'subscription_tier': tier})
          .eq('id', userId);
    } catch (_) {
      // Best-effort — silently retried on the next RC status emit.
    }
  }
}
