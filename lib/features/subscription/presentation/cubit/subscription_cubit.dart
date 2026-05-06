import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:sample/features/subscription/domain/usecases/get_current_usage_usecase.dart';
import 'package:sample/features/subscription/domain/usecases/get_offerings_usecase.dart';
import 'package:sample/features/subscription/domain/usecases/get_subscription_status_usecase.dart';
import 'package:sample/features/subscription/domain/usecases/purchase_package_usecase.dart';
import 'package:sample/features/subscription/domain/usecases/restore_purchases_usecase.dart';
import 'package:sample/features/subscription/presentation/cubit/subscription_state.dart';
import 'package:sample/features/subscription/presentation/pages/customer_center_page.dart';
import 'package:sample/features/subscription/presentation/pages/paywall_page.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit({
    required GetSubscriptionStatusUseCase getSubscriptionStatus,
    required RestorePurchasesUseCase restorePurchases,
    required GetOfferingsUseCase getOfferings,
    required PurchasePackageUseCase purchasePackage,
    required SubscriptionRepository repository,
    required GetCurrentUsageUseCase getCurrentUsage,
  })  : _getSubscriptionStatus = getSubscriptionStatus,
        _restorePurchases = restorePurchases,
        _getOfferings = getOfferings,
        _purchasePackage = purchasePackage,
        _repository = repository,
        _getCurrentUsage = getCurrentUsage,
        super(const SubscriptionInitial());

  final GetSubscriptionStatusUseCase _getSubscriptionStatus;
  final RestorePurchasesUseCase _restorePurchases;
  final GetOfferingsUseCase _getOfferings;
  final PurchasePackageUseCase _purchasePackage;
  final SubscriptionRepository _repository;
  final GetCurrentUsageUseCase _getCurrentUsage;

  StreamSubscription<void>? _statusSubscription;

  void loadStatus() {
    emit(const SubscriptionLoading());
    _fetchStatusAndUsage();
    _listenToUpdates();
  }

  Future<void> _fetchStatusAndUsage() async {
    final statusResult = await _getSubscriptionStatus(const NoParams());
    await statusResult.fold(
      (failure) async => emit(SubscriptionError(failure.message)),
      (status) async {
        final usageResult = await _getCurrentUsage(const NoParams());
        final usageInfo = usageResult.fold((_) => null, (info) => info);
        emit(SubscriptionLoaded(status, usageInfo: usageInfo));
      },
    );
  }

  void _listenToUpdates() {
    _statusSubscription?.cancel();
    _statusSubscription = _repository.watchSubscriptionStatus().listen(
      (status) async {
        final usageResult = await _getCurrentUsage(const NoParams());
        final usageInfo = usageResult.fold((_) => null, (info) => info);
        emit(SubscriptionLoaded(status, usageInfo: usageInfo));
      },
    );
  }

  Future<void> showPaywall(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BlocProvider.value(
          value: this,
          child: const PaywallPage(),
        ),
      ),
    );
    await _fetchStatusAndUsage();
  }

  /// Loads offerings for paywall display. Called from PaywallPage.
  Future<Offerings?> loadOfferings() async {
    final result = await _getOfferings(const NoParams());
    return result.fold(
      (failure) {
        emit(SubscriptionError(failure.message));
        return null;
      },
      (offerings) => offerings,
    );
  }

  /// Triggers a purchase via RevenueCat.
  /// Returns true on success, false on failure/cancel.
  Future<PurchaseOutcome> purchase(Package package) async {
    final result = await _purchasePackage(PurchasePackageParams(package));
    return result.fold(
      (failure) {
        if (failure is PurchaseCancelledFailure) {
          return const PurchaseOutcome.cancelled();
        }
        return PurchaseOutcome.error(failure.message);
      },
      (status) async {
        final usageResult = await _getCurrentUsage(const NoParams());
        final usageInfo = usageResult.fold((_) => null, (info) => info);
        emit(SubscriptionLoaded(status, usageInfo: usageInfo));
        return const PurchaseOutcome.success();
      },
    );
  }

  Future<void> showCustomerCenter(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: this,
          child: const CustomerCenterPage(),
        ),
      ),
    );
    await _fetchStatusAndUsage();
  }

  Future<void> restore() async {
    emit(const SubscriptionLoading());
    final result = await _restorePurchases(const NoParams());
    await result.fold(
      (failure) async => emit(SubscriptionError(failure.message)),
      (status) async {
        final usageResult = await _getCurrentUsage(const NoParams());
        final usageInfo = usageResult.fold((_) => null, (info) => info);
        emit(SubscriptionLoaded(status, usageInfo: usageInfo));
      },
    );
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    return super.close();
  }
}

/// Result of attempting a purchase from the paywall.
sealed class PurchaseOutcome {
  const PurchaseOutcome();

  const factory PurchaseOutcome.success() = PurchaseSuccess;
  const factory PurchaseOutcome.cancelled() = PurchaseCancelled;
  const factory PurchaseOutcome.error(String message) = PurchaseError;
}

class PurchaseSuccess extends PurchaseOutcome {
  const PurchaseSuccess();
}

class PurchaseCancelled extends PurchaseOutcome {
  const PurchaseCancelled();
}

class PurchaseError extends PurchaseOutcome {
  const PurchaseError(this.message);
  final String message;
}
