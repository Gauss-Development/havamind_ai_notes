import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/auth/domain/auth_snapshot.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserProfile?>> getInitialSession();

  Future<Either<Failure, Unit>> signInWithGoogle();

  Future<Either<Failure, Unit>> signOut();

  Stream<AuthSnapshot> watchAuthState();
}
