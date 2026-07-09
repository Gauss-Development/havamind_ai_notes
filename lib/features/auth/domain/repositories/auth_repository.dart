import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/auth/domain/auth_snapshot.dart';
import 'package:sample/features/auth/domain/entities/email_password_params.dart';
import 'package:sample/features/auth/domain/entities/email_sign_up_result.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserProfile?>> getInitialSession();

  Future<Either<Failure, Unit>> signInWithGoogle();

  Future<Either<Failure, Unit>> signInWithApple();

  Future<Either<Failure, Unit>> signInWithEmailPassword(
    EmailPasswordParams params,
  );

  Future<Either<Failure, EmailSignUpResult>> signUpWithEmailPassword(
    EmailPasswordParams params,
  );

  Future<Either<Failure, Unit>> signOut();

  Stream<AuthSnapshot> watchAuthState();
}
