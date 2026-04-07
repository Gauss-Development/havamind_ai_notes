import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sample/core/error/failure.dart';
import 'package:sample/features/auth/data/datasources/profile_remote_data_source.dart';
import 'package:sample/features/auth/data/models/user_profile_mapper.dart';
import 'package:sample/features/auth/domain/auth_snapshot.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';
import 'package:sample/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required ProfileRemoteDataSource profileRemote,
    required SupabaseClient client,
  }) : _profileRemote = profileRemote,
       _client = client;

  final ProfileRemoteDataSource _profileRemote;
  final SupabaseClient _client;

  @override
  Future<Either<Failure, UserProfile?>> getInitialSession() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        return const Right(null);
      }
      final user = session.user;
      var profile = await _profileRemote.fetchProfile(user.id);
      profile ??= await _profileRemote.upsertFromSupabaseUser(user);
      return Right(profile);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> signInWithGoogle() async {
    try {
      final launched = kIsWeb
          ? await _client.auth.signInWithOAuth(
              OAuthProvider.google,
              authScreenLaunchMode: LaunchMode.platformDefault,
            )
          : await _client.auth.signInWithOAuth(
              OAuthProvider.google,
              redirectTo: 'havamind://login-callback',
              authScreenLaunchMode: LaunchMode.externalApplication,
            );
      if (!launched) {
        return const Left(
          AuthFailure('Could not open Google sign-in page'),
        );
      }
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Stream<AuthSnapshot> watchAuthState() {
    return _client.auth.onAuthStateChange.asyncMap((data) async {
      final session = data.session;
      if (session == null) {
        return const AuthSnapshot.signedOut();
      }
      final user = session.user;
      try {
        var profile = await _profileRemote.fetchProfile(user.id);
        profile ??= await _profileRemote.upsertFromSupabaseUser(user);
        return AuthSnapshot.signedIn(profile);
      } catch (_) {
        return AuthSnapshot.signedIn(UserProfileMapper.fromSupabaseUser(user));
      }
    });
  }
}
