import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/auth/domain/auth_snapshot.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';
import 'package:sample/features/auth/domain/usecases/get_initial_session_usecase.dart';
import 'package:sample/features/auth/domain/usecases/observe_auth_state_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_out_usecase.dart';

part 'auth_bloc.freezed.dart';

@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.started() = _Started;
  const factory AuthEvent.signInWithGooglePressed() = _SignInWithGooglePressed;
  const factory AuthEvent.signOutPressed() = _SignOutPressed;
  const factory AuthEvent.snapshotReceived(AuthSnapshot snapshot) =
      _SnapshotReceived;
}

@freezed
class AuthState with _$AuthState {
  const factory AuthState.unknown() = _Unknown;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.unauthenticated({String? errorMessage}) =
      _Unauthenticated;
  const factory AuthState.authenticated(UserProfile profile) = _Authenticated;
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required GetInitialSessionUseCase getInitialSession,
    required SignInWithGoogleUseCase signInWithGoogle,
    required SignOutUseCase signOut,
    required ObserveAuthStateUseCase observeAuthState,
  }) : _getInitialSession = getInitialSession,
       _signInWithGoogle = signInWithGoogle,
       _signOut = signOut,
       _observeAuthState = observeAuthState,
       super(const AuthState.unknown()) {
    on<_Started>(_onStarted);
    on<_SignInWithGooglePressed>(_onSignInWithGoogle);
    on<_SignOutPressed>(_onSignOut);
    on<_SnapshotReceived>(_onSnapshotReceived);
  }

  final GetInitialSessionUseCase _getInitialSession;
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignOutUseCase _signOut;
  final ObserveAuthStateUseCase _observeAuthState;

  StreamSubscription<AuthSnapshot>? _authSubscription;
  var _listening = false;

  /// True while Supabase OAuth is in progress (browser open, session not yet restored).
  bool _oauthPending = false;

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
        emit(const AuthState.unauthenticated());
      },
      signedIn: (profile) {
        _oauthPending = false;
        emit(AuthState.authenticated(profile));
      },
    );
  }

  Future<void> _onSignInWithGoogle(
    _SignInWithGooglePressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    _oauthPending = true;
    final result = await _signInWithGoogle(const NoParams());
    result.fold((f) {
      _oauthPending = false;
      emit(AuthState.unauthenticated(errorMessage: f.message));
    }, (_) {});
  }

  Future<void> _onSignOut(
    _SignOutPressed event,
    Emitter<AuthState> emit,
  ) async {
    _oauthPending = false;
    emit(const AuthState.loading());
    final result = await _signOut(const NoParams());
    result.fold(
      (f) => emit(AuthState.unauthenticated(errorMessage: f.message)),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
