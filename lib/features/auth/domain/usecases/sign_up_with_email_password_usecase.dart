import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/auth/domain/entities/email_password_params.dart';
import 'package:sample/features/auth/domain/entities/email_sign_up_result.dart';
import 'package:sample/features/auth/domain/repositories/auth_repository.dart';

class SignUpWithEmailPasswordUseCase
    implements UseCase<EmailSignUpResult, EmailPasswordParams> {
  SignUpWithEmailPasswordUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, EmailSignUpResult>> call(EmailPasswordParams params) {
    return _repository.signUpWithEmailPassword(params);
  }
}
