import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/subscription/domain/entities/paywall_action_result.dart';
import 'package:sample/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:sample/features/subscription/domain/usecases/get_current_usage_usecase.dart';
import 'package:sample/features/subscription/domain/usecases/get_subscription_status_usecase.dart';
import 'package:sample/features/subscription/domain/usecases/present_paywall_usecase.dart';
import 'package:sample/features/subscription/domain/usecases/restore_purchases_usecase.dart';
import 'package:sample/features/subscription/presentation/cubit/subscription_state.dart';
import 'package:sample/features/subscription/presentation/pages/customer_center_page.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit({
    required GetSubscriptionStatusUseCase getSubscriptionStatus,
    required RestorePurchasesUseCase restorePurchases,
    required PresentPaywallUseCase presentPaywall,
    required SubscriptionRepository repository,
    required GetCurrentUsageUseCase getCurrentUsage,
  })  : _getSubscriptionStatus = getSubscriptionStatus,
        _restorePurchases = restorePurchases,
        _presentPaywall = presentPaywall,
        _repository = repository,
        _getCurrentUsage = getCurrentUsage,
        super(const SubscriptionInitial());

  final GetSubscriptionStatusUseCase _getSubscriptionStatus;
  final RestorePurchasesUseCase _restorePurchases;
  final PresentPaywallUseCase _presentPaywall;
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

  Future<void> showPaywall() async {
    final result = await _presentPaywall(const NoParams());
    result.fold(
      (failure) => emit(SubscriptionError(failure.message)),
      (paywallResult) {
        if (paywallResult == PaywallActionResult.purchased ||
            paywallResult == PaywallActionResult.restored) {
          _fetchStatusAndUsage();
        }
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
