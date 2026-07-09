import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sample/core/constants/auth_constants.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/auth/data/datasources/profile_remote_data_source.dart';
import 'package:sample/features/auth/data/models/user_profile_mapper.dart';
import 'package:sample/features/auth/domain/auth_snapshot.dart';
import 'package:sample/features/auth/domain/entities/email_password_params.dart';
import 'package:sample/features/auth/domain/entities/email_sign_up_result.dart';
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
  Future<Either<Failure, Unit>> signInWithGoogle() =>
      _signInWithOAuth(OAuthProvider.google, 'Google');

  @override
  Future<Either<Failure, Unit>> signInWithApple() =>
      _signInWithOAuth(OAuthProvider.apple, 'Apple');

  Future<Either<Failure, Unit>> _signInWithOAuth(
    OAuthProvider provider,
    String providerLabel,
  ) async {
    try {
      final launched = kIsWeb
          ? await _client.auth.signInWithOAuth(
              provider,
              authScreenLaunchMode: LaunchMode.platformDefault,
            )
          : await _client.auth.signInWithOAuth(
              provider,
              redirectTo: kAuthMobileRedirectUrl,
              authScreenLaunchMode: LaunchMode.externalApplication,
            );
      if (!launched) {
        return Left(
          AuthFailure('Could not open $providerLabel sign-in page'),
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
  Future<Either<Failure, Unit>> signInWithEmailPassword(
    EmailPasswordParams params,
  ) async {
    try {
      await _client.auth.signInWithPassword(
        email: params.email.trim(),
        password: params.password,
      );
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EmailSignUpResult>> signUpWithEmailPassword(
    EmailPasswordParams params,
  ) async {
    try {
      final response = await _client.auth.signUp(
        email: params.email.trim(),
        password: params.password,
        emailRedirectTo: kIsWeb ? null : kAuthMobileRedirectUrl,
      );
      final emailConfirmationRequired = response.session == null;
      return Right(
        EmailSignUpResult(emailConfirmationRequired: emailConfirmationRequired),
      );
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
