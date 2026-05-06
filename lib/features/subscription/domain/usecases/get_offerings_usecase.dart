import 'package:dartz/dartz.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/subscription/domain/repositories/subscription_repository.dart';

class GetOfferingsUseCase implements UseCase<Offerings, NoParams> {
  GetOfferingsUseCase(this._repository);

  final SubscriptionRepository _repository;

  @override
  Future<Either<Failure, Offerings>> call(NoParams params) {
    return _repository.getOfferings();
  }
}
