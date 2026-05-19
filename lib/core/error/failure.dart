import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}

/// Distinct from [UnexpectedFailure] so the UI can route deletion-after-
/// load scenarios (note watched in real-time, then removed from another
/// device) to a `deleted` state instead of stranding on an opaque error.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class PurchaseFailure extends Failure {
  const PurchaseFailure(super.message);
}

class PurchaseCancelledFailure extends PurchaseFailure {
  const PurchaseCancelledFailure()
      : super('Purchase was cancelled');
}

class PurchaseNotAllowedFailure extends PurchaseFailure {
  const PurchaseNotAllowedFailure()
      : super('Purchases are not allowed on this device');
}

class PaymentPendingFailure extends PurchaseFailure {
  const PaymentPendingFailure()
      : super('Payment is pending approval');
}
