import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/auth/domain/auth_snapshot.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';
import 'package:sample/features/auth/domain/entities/email_password_params.dart';
import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/auth/domain/usecases/get_initial_session_usecase.dart';
import 'package:sample/features/auth/domain/usecases/observe_auth_state_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_in_with_apple_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_in_with_email_password_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_up_with_email_password_usecase.dart';

part 'auth_bloc.freezed.dart';

@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.started() = _Started;
  const factory AuthEvent.signInWithGooglePressed() = _SignInWithGooglePressed;
  const factory AuthEvent.signInWithApplePressed() = _SignInWithApplePressed;
  const factory AuthEvent.signInWithEmailPasswordPressed(
    EmailPasswordParams params,
  ) = _SignInWithEmailPasswordPressed;
  const factory AuthEvent.signUpWithEmailPasswordPressed(
    EmailPasswordParams params,
  ) = _SignUpWithEmailPasswordPressed;
  const factory AuthEvent.signOutPressed() = _SignOutPressed;
  const factory AuthEvent.snapshotReceived(AuthSnapshot snapshot) =
      _SnapshotReceived;
}

@freezed
class AuthState with _$AuthState {
  const factory AuthState.unknown() = _Unknown;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.unauthenticated({
    String? errorMessage,
    @Default(false) bool emailConfirmationSent,
    @Default(false) bool isSubmitting,
  }) = _Unauthenticated;
  const factory AuthState.authenticated(UserProfile profile) = _Authenticated;
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required GetInitialSessionUseCase getInitialSession,
    required SignInWithGoogleUseCase signInWithGoogle,
    required SignInWithAppleUseCase signInWithApple,
    required SignInWithEmailPasswordUseCase signInWithEmailPassword,
    required SignUpWithEmailPasswordUseCase signUpWithEmailPassword,
    required SignOutUseCase signOut,
    required ObserveAuthStateUseCase observeAuthState,
  }) : _getInitialSession = getInitialSession,
       _signInWithGoogle = signInWithGoogle,
       _signInWithApple = signInWithApple,
       _signInWithEmailPassword = signInWithEmailPassword,
       _signUpWithEmailPassword = signUpWithEmailPassword,
       _signOut = signOut,
       _observeAuthState = observeAuthState,
       super(const AuthState.unknown()) {
    on<_Started>(_onStarted);
    on<_SignInWithGooglePressed>(_onSignInWithGoogle);
    on<_SignInWithApplePressed>(_onSignInWithApple);
    on<_SignInWithEmailPasswordPressed>(_onSignInWithEmailPassword);
    on<_SignUpWithEmailPasswordPressed>(_onSignUpWithEmailPassword);
    on<_SignOutPressed>(_onSignOut);
    on<_SnapshotReceived>(_onSnapshotReceived);
  }

  final GetInitialSessionUseCase _getInitialSession;
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignInWithAppleUseCase _signInWithApple;
  final SignInWithEmailPasswordUseCase _signInWithEmailPassword;
  final SignUpWithEmailPasswordUseCase _signUpWithEmailPassword;
  final SignOutUseCase _signOut;
  final ObserveAuthStateUseCase _observeAuthState;

  StreamSubscription<AuthSnapshot>? _authSubscription;
  var _listening = false;

  /// True while Supabase OAuth is in progress (browser open, session not yet restored).
  bool _oauthPending = false;

  /// Guards against the OAuth flow leaving the bloc stuck in `loading`
  /// forever if the user closes the browser without completing sign-in.
  Timer? _oauthTimeoutTimer;
  static const _oauthTimeout = Duration(seconds: 90);

  Future<void> _onStarted(_Started event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    final result = await _getInitialSession(const NoParams());
    result.fold(
      (f) => emit(AuthState.unauthenticated(errorMessage: f.message)),
      (profile) {
        if (profile == null) {
          emit(const AuthState.unauthenticated());
        } else {
          emit(AuthState.authenticated(profile));
        }
      },
    );
    _startAuthListener();
  }

  void _startAuthListener() {
    if (_listening) {
      return;
    }
    _listening = true;
    _authSubscription = _observeAuthState().listen(
      (snapshot) => add(AuthEvent.snapshotReceived(snapshot)),
    );
  }

  void _onSnapshotReceived(_SnapshotReceived event, Emitter<AuthState> emit) {
    event.snapshot.when(
      signedOut: () {
        if (_oauthPending) {
          return;
        }
        _oauthTimeoutTimer?.cancel();
        emit(const AuthState.unauthenticated());
      },
      signedIn: (profile) {
        _oauthPending = false;
        _oauthTimeoutTimer?.cancel();
        emit(AuthState.authenticated(profile));
      },
    );
  }

  Future<void> _onSignInWithGoogle(
    _SignInWithGooglePressed event,
    Emitter<AuthState> emit,
  ) => _startOAuthSignIn(emit, () => _signInWithGoogle(const NoParams()));

  Future<void> _onSignInWithApple(
    _SignInWithApplePressed event,
    Emitter<AuthState> emit,
  ) => _startOAuthSignIn(emit, () => _signInWithApple(const NoParams()));

  Future<void> _startOAuthSignIn(
    Emitter<AuthState> emit,
    Future<Either<Failure, Unit>> Function() launch,
  ) async {
    emit(const AuthState.loading());
    _oauthPending = true;
    _oauthTimeoutTimer?.cancel();
    _oauthTimeoutTimer = Timer(_oauthTimeout, () {
      // Browser was opened but the user never made it back. Don't strand
      // the UI on a perma-loading screen — synthesize a signedOut so the
      // existing handler routes us to the login screen with a retry path.
      if (_oauthPending && !isClosed) {
        _oauthPending = false;
        add(const AuthEvent.snapshotReceived(AuthSnapshot.signedOut()));
      }
    });
    final result = await launch();
    result.fold((f) {
      _oauthPending = false;
      _oauthTimeoutTimer?.cancel();
      emit(AuthState.unauthenticated(errorMessage: f.message));
    }, (_) {});
  }

  Future<void> _onSignInWithEmailPassword(
    _SignInWithEmailPasswordPressed event,
    Emitter<AuthState> emit,
  ) async {
    final previousError = state.maybeWhen(
      unauthenticated: (message, emailConfirmationSent, isSubmitting) =>
          message,
      orElse: () => null,
    );
    emit(
      AuthState.unauthenticated(
        errorMessage: previousError,
        isSubmitting: true,
      ),
    );
    final result = await _signInWithEmailPassword(event.params);
    result.fold(
      (f) => emit(AuthState.unauthenticated(errorMessage: f.message)),
      (_) {},
    );
  }

  Future<void> _onSignUpWithEmailPassword(
    _SignUpWithEmailPasswordPressed event,
    Emitter<AuthState> emit,
  ) async {
    final previousError = state.maybeWhen(
      unauthenticated: (message, emailConfirmationSent, isSubmitting) =>
          message,
      orElse: () => null,
    );
    emit(
      AuthState.unauthenticated(
        errorMessage: previousError,
        isSubmitting: true,
      ),
    );
    final result = await _signUpWithEmailPassword(event.params);
    result.fold(
      (f) => emit(AuthState.unauthenticated(errorMessage: f.message)),
      (signUpResult) {
        if (signUpResult.emailConfirmationRequired) {
          emit(const AuthState.unauthenticated(emailConfirmationSent: true));
        }
      },
    );
  }

  Future<void> _onSignOut(
    _SignOutPressed event,
    Emitter<AuthState> emit,
  ) async {
    _oauthPending = false;
    _oauthTimeoutTimer?.cancel();
    emit(const AuthState.loading());
    final result = await _signOut(const NoParams());
    result.fold(
      (f) => emit(AuthState.unauthenticated(errorMessage: f.message)),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }

  @override
  Future<void> close() async {
    _oauthTimeoutTimer?.cancel();
    await _authSubscription?.cancel();
    return super.close();
  }
}
