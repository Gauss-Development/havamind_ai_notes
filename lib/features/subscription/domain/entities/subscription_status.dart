import 'package:equatable/equatable.dart';

enum SubscriptionPeriod { monthly, yearly, lifetime, unknown }

enum SubscriptionStore {
  appStore,
  playStore,
  amazon,
  stripe,
  promotional,
  unknown,
}

enum SubscriptionTier { free, basic, pro }

class SubscriptionStatus extends Equatable {
  const SubscriptionStatus({
    required this.isActive,
    this.entitlementId,
    this.productId,
    this.expirationDate,
    this.willRenew = false,
    this.managementUrl,
    this.isLifetime = false,
    this.isSandbox = false,
    this.period = SubscriptionPeriod.unknown,
    this.store = SubscriptionStore.unknown,
    this.latestPurchaseDate,
    this.originalPurchaseDate,
    this.unsubscribeDetectedAt,
    this.billingIssueDetectedAt,
    this.isTrial = false,
    this.isIntroOffer = false,
    this.tier = SubscriptionTier.free,
  });

  final bool isActive;
  final String? entitlementId;
  final String? productId;
  final DateTime? expirationDate;
  final bool willRenew;
  final String? managementUrl;
  final bool isLifetime;
  final bool isSandbox;
  final SubscriptionPeriod period;
  final SubscriptionStore store;
  final DateTime? latestPurchaseDate;
  final DateTime? originalPurchaseDate;
  final DateTime? unsubscribeDetectedAt;
  final DateTime? billingIssueDetectedAt;
  final bool isTrial;
  final bool isIntroOffer;
  final SubscriptionTier tier;

  bool get isCancelled => !willRenew && !isLifetime && isActive;
  bool get hasBillingIssue => billingIssueDetectedAt != null;

  /// Store-facing product line (tier). Never exposes raw store product ids.
  String get marketingProductName => switch (tier) {
    SubscriptionTier.free => 'Havamind Voice Free',
    SubscriptionTier.basic => 'Havamind Voice Basic',
    SubscriptionTier.pro => 'Havamind Voice Pro',
  };

  String get planDisplayName {
    switch (period) {
      case SubscriptionPeriod.monthly:
        return 'Monthly';
      case SubscriptionPeriod.yearly:
        return 'Yearly';
      case SubscriptionPeriod.lifetime:
        return 'Lifetime';
      case SubscriptionPeriod.unknown:
        return 'Pro';
    }
  }

  String get storeDisplayName {
    switch (store) {
      case SubscriptionStore.appStore:
        return 'App Store';
      case SubscriptionStore.playStore:
        return 'Google Play';
      case SubscriptionStore.amazon:
        return 'Amazon';
      case SubscriptionStore.stripe:
        return 'Web';
      case SubscriptionStore.promotional:
        return 'Promotional';
      case SubscriptionStore.unknown:
        return 'Unknown';
    }
  }

  static const inactive = SubscriptionStatus(isActive: false);

  @override
  List<Object?> get props => [
    isActive,
    entitlementId,
    productId,
    expirationDate,
    willRenew,
    managementUrl,
    isLifetime,
    isSandbox,
    period,
    store,
    latestPurchaseDate,
    originalPurchaseDate,
    unsubscribeDetectedAt,
    billingIssueDetectedAt,
    isTrial,
    isIntroOffer,
    tier,
  ];
}
