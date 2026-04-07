import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';

part 'auth_snapshot.freezed.dart';

@freezed
class AuthSnapshot with _$AuthSnapshot {
  const factory AuthSnapshot.signedOut() = _SignedOut;
  const factory AuthSnapshot.signedIn(UserProfile profile) = _SignedIn;
}
