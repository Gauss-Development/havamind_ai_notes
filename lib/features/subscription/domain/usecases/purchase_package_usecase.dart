import 'package:dartz/dartz.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/subscription/domain/entities/subscription_status.dart';
import 'package:sample/features/subscription/domain/repositories/subscription_repository.dart';

class PurchasePackageUseCase
    implements UseCase<SubscriptionStatus, PurchasePackageParams> {
  PurchasePackageUseCase(this._repository);

  final SubscriptionRepository _repository;

  @override
  Future<Either<Failure, SubscriptionStatus>> call(
    PurchasePackageParams params,
  ) {
    return _repository.purchasePackage(params.package);
  }
}

class PurchasePackageParams {
  const PurchasePackageParams(this.package);

  final Package package;
}
