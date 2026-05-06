import 'package:dartz/dartz.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/subscription/domain/entities/subscription_status.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, void>> initialize({String? appUserId});

  Future<Either<Failure, SubscriptionStatus>> getSubscriptionStatus();

  Future<Either<Failure, SubscriptionStatus>> restorePurchases();

  Future<Either<Failure, Offerings>> getOfferings();

  Future<Either<Failure, SubscriptionStatus>> purchasePackage(Package package);

  Future<Either<Failure, void>> logIn(String appUserId);

  Future<Either<Failure, void>> logOut();

  Stream<SubscriptionStatus> watchSubscriptionStatus();
}
