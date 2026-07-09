import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/auth/domain/repositories/auth_repository.dart';

class SignInWithAppleUseCase implements UseCase<Unit, NoParams> {
  SignInWithAppleUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return _repository.signInWithApple();
  }
}
