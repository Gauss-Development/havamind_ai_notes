import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/subscription/domain/entities/subscription_status.dart';
import 'package:sample/features/subscription/domain/repositories/subscription_repository.dart';

class RestorePurchasesUseCase
    implements UseCase<SubscriptionStatus, NoParams> {
  RestorePurchasesUseCase(this._repository);

  final SubscriptionRepository _repository;

  @override
  Future<Either<Failure, SubscriptionStatus>> call(NoParams params) {
    return _repository.restorePurchases();
  }
}
