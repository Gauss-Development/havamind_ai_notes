import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/auth/domain/repositories/auth_repository.dart';

/// Permanently deletes the signed-in user's account and all their data.
class DeleteAccountUseCase implements UseCase<Unit, NoParams> {
  DeleteAccountUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return _repository.deleteAccount();
  }
}
