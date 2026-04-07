import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';
import 'package:sample/features/auth/domain/repositories/auth_repository.dart';

class GetInitialSessionUseCase implements UseCase<UserProfile?, NoParams> {
  GetInitialSessionUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserProfile?>> call(NoParams params) {
    return _repository.getInitialSession();
  }
}
