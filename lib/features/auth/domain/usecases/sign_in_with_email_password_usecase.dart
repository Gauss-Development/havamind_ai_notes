import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/auth/domain/entities/email_password_params.dart';
import 'package:sample/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmailPasswordUseCase
    implements UseCase<Unit, EmailPasswordParams> {
  SignInWithEmailPasswordUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(EmailPasswordParams params) {
    return _repository.signInWithEmailPassword(params);
  }
}
