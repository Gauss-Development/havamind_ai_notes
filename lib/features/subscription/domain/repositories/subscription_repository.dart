import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/subscription/domain/entities/paywall_action_result.dart';
import 'package:sample/features/subscription/domain/entities/subscription_status.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, void>> initialize({String? appUserId});

  Future<Either<Failure, SubscriptionStatus>> getSubscriptionStatus();

  Future<Either<Failure, SubscriptionStatus>> restorePurchases();

  Future<Either<Failure, PaywallActionResult>> presentPaywall();

  Future<Either<Failure, void>> presentCustomerCenter();

  Future<Either<Failure, void>> logIn(String appUserId);

  Future<Either<Failure, void>> logOut();

  Stream<SubscriptionStatus> watchSubscriptionStatus();
}
