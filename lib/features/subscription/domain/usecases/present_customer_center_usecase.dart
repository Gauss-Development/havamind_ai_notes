import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/subscription/domain/repositories/subscription_repository.dart';

class PresentCustomerCenterUseCase implements UseCase<void, NoParams> {
  PresentCustomerCenterUseCase(this._repository);

  final SubscriptionRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return _repository.presentCustomerCenter();
  }
}
