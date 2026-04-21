import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class RevenueCatDataSource {
  static const _proEntitlementId = 'Havamind Voice Pro';
  static const _basicEntitlementId = 'Havamind Voice Basic';

  bool _isConfigured = false;
  final _statusController = StreamController<CustomerInfo>.broadcast();

  Stream<CustomerInfo> get customerInfoStream => _statusController.stream;

  Future<void> configure(String apiKey, {String? appUserId}) async {
    if (_isConfigured) return;

    await Purchases.setLogLevel(LogLevel.debug);

    final configuration = PurchasesConfiguration(apiKey)
      ..appUserID = appUserId
      ..purchasesAreCompletedBy = const PurchasesAreCompletedByRevenueCat()
      ..shouldShowInAppMessagesAutomatically = true;

    await Purchases.configure(configuration);

    Purchases.addCustomerInfoUpdateListener((info) {
      _statusController.add(info);
    });

    _isConfigured = true;
  }

  Future<CustomerInfo> getCustomerInfo() async {
    return Purchases.getCustomerInfo();
  }

  Future<CustomerInfo> restorePurchases() async {
    return Purchases.restorePurchases();
  }

  Future<Offerings> getOfferings() async {
    return Purchases.getOfferings();
  }

  Future<PaywallResult> presentPaywall() async {
    final offerings = await Purchases.getOfferings();
    return RevenueCatUI.presentPaywall(
      offering: offerings.current,
      displayCloseButton: true,
    );
  }

  Future<LogInResult> logIn(String appUserId) async {
    return Purchases.logIn(appUserId);
  }

  Future<CustomerInfo> logOut() async {
    return Purchases.logOut();
  }

  String get proEntitlementId => _proEntitlementId;
  String get basicEntitlementId => _basicEntitlementId;

  /// Returns the highest-priority active entitlement ID, or null if none.
  /// Pro takes precedence over Basic.
  String? activeEntitlementId(CustomerInfo info) {
    if (info.entitlements.active.containsKey(_proEntitlementId)) {
      return _proEntitlementId;
    }
    if (info.entitlements.active.containsKey(_basicEntitlementId)) {
      return _basicEntitlementId;
    }
    return null;
  }

  void dispose() {
    _statusController.close();
  }
}
