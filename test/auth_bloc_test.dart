import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/auth/domain/auth_snapshot.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';
import 'package:sample/features/auth/domain/entities/email_password_params.dart';
import 'package:sample/features/auth/domain/entities/email_sign_up_result.dart';
import 'package:sample/features/auth/domain/repositories/auth_repository.dart';
import 'package:sample/features/auth/domain/usecases/get_initial_session_usecase.dart';
import 'package:sample/features/auth/domain/usecases/observe_auth_state_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_in_with_apple_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_in_with_email_password_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_up_with_email_password_usecase.dart';
import 'package:sample/features/auth/presentation/bloc/auth_bloc.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late AuthBloc bloc;
  late StreamController<AuthSnapshot> authStreamController;

  final profile = UserProfile(
    id: 'u1',
    email: 'a@b.c',
    fullName: 'Test',
    avatarUrl: null,
    createdAt: DateTime.utc(2025),
    updatedAt: DateTime.utc(2025),
    lastSignInAt: DateTime.utc(2025),
  );

  final params = const EmailPasswordParams(email: 'a@b.c', password: 'secret');

  setUp(() {
    repository = _MockAuthRepository();
    authStreamController = StreamController<AuthSnapshot>.broadcast();
    when(
      () => repository.getInitialSession(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => repository.watchAuthState(),
    ).thenAnswer((_) => authStreamController.stream);
    bloc = AuthBloc(
      getInitialSession: GetInitialSessionUseCase(repository),
      signInWithGoogle: SignInWithGoogleUseCase(repository),
      signInWithApple: SignInWithAppleUseCase(repository),
      signInWithEmailPassword: SignInWithEmailPasswordUseCase(repository),
      signUpWithEmailPassword: SignUpWithEmailPasswordUseCase(repository),
      signOut: SignOutUseCase(repository),
      observeAuthState: ObserveAuthStateUseCase(repository),
    );
  });

  tearDown(() async {
    await authStreamController.close();
    await bloc.close();
  });

  test('started with no session yields unauthenticated', () async {
    bloc.add(const AuthEvent.started());
    await expectLater(
      bloc.stream,
      emitsInOrder(<AuthState>[
        const AuthState.loading(),
        const AuthState.unauthenticated(),
      ]),
    );
  });

  test(
    'signInWithGoogle success yields authenticated after snapshot',
    () async {
      when(
        () => repository.signInWithGoogle(),
      ).thenAnswer((_) async => const Right(unit));
      bloc.add(const AuthEvent.started());
      await expectLater(
        bloc.stream,
        emitsInOrder(<AuthState>[
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ]),
      );

      bloc.add(const AuthEvent.signInWithGooglePressed());
      await expectLater(
        bloc.stream,
        emitsInOrder(<AuthState>[const AuthState.loading()]),
      );

      authStreamController.add(AuthSnapshot.signedIn(profile));
      await expectLater(
        bloc.stream,
        emitsInOrder(<AuthState>[AuthState.authenticated(profile)]),
      );
    },
  );

  test(
    'signInWithGoogle failure yields unauthenticated with message',
    () async {
      when(
        () => repository.signInWithGoogle(),
      ).thenAnswer((_) async => const Left<Failure, Unit>(AuthFailure('bad')));
      bloc.add(const AuthEvent.started());
      await bloc.stream.firstWhere(
        (s) => s.maybeWhen(
          unauthenticated: (_, _, _) => true,
          orElse: () => false,
        ),
      );

      bloc.add(const AuthEvent.signInWithGooglePressed());
      await expectLater(
        bloc.stream,
        emitsInOrder(<AuthState>[
          const AuthState.loading(),
          const AuthState.unauthenticated(errorMessage: 'bad'),
        ]),
      );
    },
  );

  test('signOut yields unauthenticated', () async {
    when(() => repository.signOut()).thenAnswer((_) async => const Right(unit));
    bloc.add(const AuthEvent.signOutPressed());
    await expectLater(
      bloc.stream,
      emitsInOrder(<AuthState>[
        const AuthState.loading(),
        const AuthState.unauthenticated(),
      ]),
    );
  });

  test(
    'signInWithEmailPassword submits without global loading state',
    () async {
      when(
        () => repository.signInWithEmailPassword(params),
      ).thenAnswer((_) async => const Right(unit));
      bloc.add(const AuthEvent.started());
      await bloc.stream.firstWhere(
        (s) => s.maybeWhen(
          unauthenticated: (_, _, _) => true,
          orElse: () => false,
        ),
      );

      bloc.add(AuthEvent.signInWithEmailPasswordPressed(params));
      await expectLater(
        bloc.stream,
        emitsInOrder(<AuthState>[
          const AuthState.unauthenticated(isSubmitting: true),
        ]),
      );

      authStreamController.add(AuthSnapshot.signedIn(profile));
      await expectLater(
        bloc.stream,
        emitsInOrder(<AuthState>[AuthState.authenticated(profile)]),
      );
    },
  );

  test(
    'signInWithEmailPassword failure yields unauthenticated with message',
    () async {
      when(
        () => repository.signInWithEmailPassword(params),
      ).thenAnswer((_) async => const Left<Failure, Unit>(AuthFailure('bad')));
      bloc.add(const AuthEvent.started());
      await bloc.stream.firstWhere(
        (s) => s.maybeWhen(
          unauthenticated: (_, _, _) => true,
          orElse: () => false,
        ),
      );

      bloc.add(AuthEvent.signInWithEmailPasswordPressed(params));
      await expectLater(
        bloc.stream,
        emitsInOrder(<AuthState>[
          const AuthState.unauthenticated(isSubmitting: true),
          const AuthState.unauthenticated(errorMessage: 'bad'),
        ]),
      );
    },
  );

  test(
    'signUpWithEmailPassword with confirmation yields emailConfirmationSent',
    () async {
      when(() => repository.signUpWithEmailPassword(params)).thenAnswer(
        (_) async =>
            const Right(EmailSignUpResult(emailConfirmationRequired: true)),
      );
      bloc.add(const AuthEvent.started());
      await bloc.stream.firstWhere(
        (s) => s.maybeWhen(
          unauthenticated: (_, _, _) => true,
          orElse: () => false,
        ),
      );

      bloc.add(AuthEvent.signUpWithEmailPasswordPressed(params));
      await expectLater(
        bloc.stream,
        emitsInOrder(<AuthState>[
          const AuthState.unauthenticated(isSubmitting: true),
          const AuthState.unauthenticated(emailConfirmationSent: true),
        ]),
      );
    },
  );
}
