import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/subscription/domain/entities/paywall_action_result.dart';
import 'package:sample/features/subscription/domain/repositories/subscription_repository.dart';

class PresentPaywallUseCase
    implements UseCase<PaywallActionResult, NoParams> {
  PresentPaywallUseCase(this._repository);

  final SubscriptionRepository _repository;

  @override
  Future<Either<Failure, PaywallActionResult>> call(NoParams params) {
    return _repository.presentPaywall();
  }
}
