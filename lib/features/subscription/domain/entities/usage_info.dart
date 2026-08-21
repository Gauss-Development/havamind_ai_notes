import 'package:equatable/equatable.dart';

import 'package:sample/features/subscription/domain/entities/subscription_status.dart';

class UsageInfo extends Equatable {
  const UsageInfo({
    required this.usedSeconds,
    required this.limitSeconds,
    required this.tier,
    required this.periodStart,
    required this.periodEnd,
  });

  final int usedSeconds;
  final int limitSeconds;
  final SubscriptionTier tier;
  final DateTime periodStart;
  final DateTime periodEnd;

  int get remainingSeconds =>
      (limitSeconds - usedSeconds).clamp(0, limitSeconds);

  double get usageRatio =>
      limitSeconds > 0 ? (usedSeconds / limitSeconds).clamp(0.0, 1.0) : 1.0;

  bool get isExhausted => usedSeconds >= limitSeconds;

  int get usedMinutes => usedSeconds ~/ 60;
  int get limitMinutes => limitSeconds ~/ 60;
  int get remainingMinutes => remainingSeconds ~/ 60;

  @override
  List<Object?> get props => [
    usedSeconds,
    limitSeconds,
    tier,
    periodStart,
    periodEnd,
  ];
}
