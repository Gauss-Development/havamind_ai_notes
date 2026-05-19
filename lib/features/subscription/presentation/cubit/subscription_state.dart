import 'package:equatable/equatable.dart';
import 'package:sample/features/subscription/domain/entities/subscription_status.dart';
import 'package:sample/features/subscription/domain/entities/usage_info.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

class SubscriptionLoaded extends SubscriptionState {
  const SubscriptionLoaded(this.status, {this.usageInfo});

  final SubscriptionStatus status;
  final UsageInfo? usageInfo;

  /// True if the user has any paid plan (Basic or Pro). Use this to gate
  /// "paid features" UI shells (e.g., showing the active-subscription card).
  bool get isPaidPlan => status.isActive;

  /// True only for the Pro tier. Use this to gate Pro-exclusive UI/limits.
  bool get isPro => status.tier == SubscriptionTier.pro;

  @override
  List<Object?> get props => [status, usageInfo];
}

class SubscriptionError extends SubscriptionState {
  const SubscriptionError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
