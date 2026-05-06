import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/subscription/data/datasources/revenuecat_data_source.dart';
import 'package:sample/features/subscription/domain/entities/subscription_status.dart';
import 'package:sample/features/subscription/domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({
    required RevenueCatDataSource dataSource,
    required String apiKey,
  })  : _dataSource = dataSource,
        _apiKey = apiKey;

  final RevenueCatDataSource _dataSource;
  final String _apiKey;

  @override
  Future<Either<Failure, void>> initialize({String? appUserId}) async {
    try {
      await _dataSource.configure(_apiKey, appUserId: appUserId);
      return const Right(null);
    } catch (e) {
      return Left(PurchaseFailure('Failed to initialize purchases: $e'));
    }
  }

  @override
  Future<Either<Failure, SubscriptionStatus>> getSubscriptionStatus() async {
    try {
      final info = await _dataSource.getCustomerInfo();
      return Right(_mapCustomerInfo(info));
    } on PlatformException catch (e) {
      return Left(_mapPlatformException(e));
    } catch (e) {
      return Left(PurchaseFailure('Failed to get subscription status: $e'));
    }
  }

  @override
  Future<Either<Failure, SubscriptionStatus>> restorePurchases() async {
    try {
      final info = await _dataSource.restorePurchases();
      return Right(_mapCustomerInfo(info));
    } on PlatformException catch (e) {
      return Left(_mapPlatformException(e));
    } catch (e) {
      return Left(PurchaseFailure('Failed to restore purchases: $e'));
    }
  }

  @override
  Future<Either<Failure, Offerings>> getOfferings() async {
    try {
      final offerings = await _dataSource.getOfferings();
      return Right(offerings);
    } on PlatformException catch (e) {
      return Left(_mapPlatformException(e));
    } catch (e) {
      return Left(PurchaseFailure('Failed to load offerings: $e'));
    }
  }

  @override
  Future<Either<Failure, SubscriptionStatus>> purchasePackage(
    Package package,
  ) async {
    try {
      final info = await _dataSource.purchasePackage(package);
      return Right(_mapCustomerInfo(info));
    } on PlatformException catch (e) {
      return Left(_mapPlatformException(e));
    } catch (e) {
      return Left(PurchaseFailure('Failed to complete purchase: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logIn(String appUserId) async {
    try {
      await _dataSource.logIn(appUserId);
      return const Right(null);
    } on PlatformException catch (e) {
      return Left(_mapPlatformException(e));
    } catch (e) {
      return Left(PurchaseFailure('Failed to log in to purchases: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logOut() async {
    try {
      await _dataSource.logOut();
      return const Right(null);
    } on PlatformException catch (e) {
      return Left(_mapPlatformException(e));
    } catch (e) {
      return Left(PurchaseFailure('Failed to log out of purchases: $e'));
    }
  }

  @override
  Stream<SubscriptionStatus> watchSubscriptionStatus() {
    return _dataSource.customerInfoStream.map(_mapCustomerInfo);
  }

  // ── Mappers ──────────────────────────────────────────────────────────────

  SubscriptionStatus _mapCustomerInfo(CustomerInfo info) {
    final activeId = _dataSource.activeEntitlementId(info);

    if (activeId == null) {
      return SubscriptionStatus.inactive;
    }

    final entitlement = info.entitlements.active[activeId]!;
    final isLifetime = entitlement.expirationDate == null;
    final tier = activeId == _dataSource.proEntitlementId
        ? SubscriptionTier.pro
        : SubscriptionTier.basic;

    return SubscriptionStatus(
      isActive: true,
      entitlementId: activeId,
      productId: entitlement.productIdentifier,
      expirationDate: entitlement.expirationDate != null
          ? DateTime.tryParse(entitlement.expirationDate!)
          : null,
      willRenew: entitlement.willRenew,
      managementUrl: info.managementURL,
      isLifetime: isLifetime,
      isSandbox: entitlement.isSandbox,
      period: _inferPeriod(entitlement.productIdentifier, isLifetime),
      store: _mapStore(entitlement.store),
      latestPurchaseDate: DateTime.tryParse(entitlement.latestPurchaseDate),
      originalPurchaseDate: DateTime.tryParse(entitlement.originalPurchaseDate),
      unsubscribeDetectedAt: entitlement.unsubscribeDetectedAt != null
          ? DateTime.tryParse(entitlement.unsubscribeDetectedAt!)
          : null,
      billingIssueDetectedAt: entitlement.billingIssueDetectedAt != null
          ? DateTime.tryParse(entitlement.billingIssueDetectedAt!)
          : null,
      isTrial: entitlement.periodType == PeriodType.trial,
      isIntroOffer: entitlement.periodType == PeriodType.intro,
      tier: tier,
    );
  }

  SubscriptionPeriod _inferPeriod(String productId, bool isLifetime) {
    if (isLifetime) return SubscriptionPeriod.lifetime;
    final id = productId.toLowerCase();
    if (id.contains('monthly') || id.contains('month')) {
      return SubscriptionPeriod.monthly;
    }
    if (id.contains('yearly') || id.contains('year') || id.contains('annual')) {
      return SubscriptionPeriod.yearly;
    }
    return SubscriptionPeriod.unknown;
  }

  SubscriptionStore _mapStore(Store store) {
    switch (store) {
      case Store.appStore:
      case Store.macAppStore:
        return SubscriptionStore.appStore;
      case Store.playStore:
        return SubscriptionStore.playStore;
      case Store.amazon:
        return SubscriptionStore.amazon;
      case Store.stripe:
        return SubscriptionStore.stripe;
      case Store.promotional:
        return SubscriptionStore.promotional;
      default:
        return SubscriptionStore.unknown;
    }
  }

  Failure _mapPlatformException(PlatformException e) {
    final errorCode = PurchasesErrorHelper.getErrorCode(e);
    switch (errorCode) {
      case PurchasesErrorCode.purchaseCancelledError:
        return const PurchaseCancelledFailure();
      case PurchasesErrorCode.purchaseNotAllowedError:
        return const PurchaseNotAllowedFailure();
      case PurchasesErrorCode.paymentPendingError:
        return const PaymentPendingFailure();
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return const PurchaseFailure('This product is already purchased');
      case PurchasesErrorCode.networkError:
        return const PurchaseFailure('Network error. Please check your connection');
      default:
        return PurchaseFailure(e.message ?? 'An unexpected purchase error occurred');
    }
  }
}
