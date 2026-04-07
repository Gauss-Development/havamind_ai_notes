import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';

class UserProfileMapper {
  static UserProfile fromSupabaseUser(User user) {
    final meta = user.userMetadata ?? <String, dynamic>{};
    final fullName = meta['full_name'] as String? ?? meta['name'] as String?;
    final avatarUrl =
        meta['avatar_url'] as String? ?? meta['picture'] as String?;
    final now = DateTime.now().toUtc();
    final createdAt = DateTime.tryParse(user.createdAt) ?? now;
    final updatedAt = user.updatedAt != null
        ? DateTime.tryParse(user.updatedAt!) ?? createdAt
        : createdAt;
    final lastSignInAt = user.lastSignInAt != null
        ? DateTime.tryParse(user.lastSignInAt!)
        : null;
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      fullName: fullName,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastSignInAt: lastSignInAt,
    );
  }

  static UserProfile fromRow(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastSignInAt: map['last_sign_in_at'] != null
          ? DateTime.parse(map['last_sign_in_at'] as String)
          : null,
    );
  }
}
