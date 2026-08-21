import 'package:dartz/dartz.dart';

import 'package:sample/core/constants/audio_notes_constants.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';
import 'package:sample/features/subscription/domain/entities/subscription_status.dart';
import 'package:sample/features/subscription/domain/entities/usage_info.dart';
import 'package:sample/features/subscription/domain/repositories/subscription_repository.dart';

class GetCurrentUsageUseCase implements UseCase<UsageInfo, NoParams> {
  GetCurrentUsageUseCase({
    required SubscriptionRepository subscriptionRepository,
    required AudioNotesRepository audioNotesRepository,
  }) : _subscriptionRepository = subscriptionRepository,
       _audioNotesRepository = audioNotesRepository;

  final SubscriptionRepository _subscriptionRepository;
  final AudioNotesRepository _audioNotesRepository;

  @override
  Future<Either<Failure, UsageInfo>> call(NoParams params) async {
    final statusResult = await _subscriptionRepository.getSubscriptionStatus();

    return statusResult.fold((failure) => Left(failure), (status) async {
      final tier = status.tier;
      final limitSeconds = _limitForTier(tier);
      final period = _currentPeriod(status);

      final usageResult = await _audioNotesRepository.getTotalUsageSeconds(
        from: period.$1,
        to: period.$2,
      );

      return usageResult.fold(
        (failure) => Left(failure),
        (usedSeconds) => Right(
          UsageInfo(
            usedSeconds: usedSeconds,
            limitSeconds: limitSeconds,
            tier: tier,
            periodStart: period.$1,
            periodEnd: period.$2,
          ),
        ),
      );
    });
  }

  int _limitForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return kFreeMonthlyLimitSeconds;
      case SubscriptionTier.basic:
        return kBasicMonthlyLimitSeconds;
      case SubscriptionTier.pro:
        return kProMonthlyLimitSeconds;
    }
  }

  /// For monthly subscribers: billing period = [expirationDate - 1 month, expirationDate).
  /// For yearly subscribers and free users: calendar month boundaries.
  (DateTime, DateTime) _currentPeriod(SubscriptionStatus status) {
    if (status.isActive &&
        status.period == SubscriptionPeriod.monthly &&
        status.expirationDate != null) {
      final end = status.expirationDate!;
      final start = _subtractOneMonth(end);
      return (start, end);
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);
    return (start, end);
  }

  /// Subtracts exactly one calendar month, clamping the day to the last
  /// valid day of the target month (so Mar 31 → Feb 28/29, not Mar 3).
  DateTime _subtractOneMonth(DateTime d) {
    final prevYear = d.month == 1 ? d.year - 1 : d.year;
    final prevMonth = d.month == 1 ? 12 : d.month - 1;
    final lastDayOfPrevMonth = DateTime(prevYear, prevMonth + 1, 0).day;
    final day = d.day > lastDayOfPrevMonth ? lastDayOfPrevMonth : d.day;
    return DateTime(
      prevYear,
      prevMonth,
      day,
      d.hour,
      d.minute,
      d.second,
      d.millisecond,
      d.microsecond,
    );
  }
}
