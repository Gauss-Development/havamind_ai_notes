import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sample/app/dashboard_page.dart';
import 'package:sample/core/di/injection.dart';
import 'package:sample/core/theme/app_theme_cubit.dart';
import 'package:sample/core/theme/obsidian_theme.dart';
import 'package:sample/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sample/features/auth/presentation/pages/login_page.dart';
import 'package:sample/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

class SampleApp extends StatelessWidget {
  const SampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<AuthBloc>()..add(const AuthEvent.started()),
        ),
        BlocProvider<AppThemeCubit>.value(value: getIt<AppThemeCubit>()),
      ],
      child: BlocBuilder<AppThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Audio Notes',
            debugShowCheckedModeBanner: false,
            theme: buildObsidianLightTheme(),
            darkTheme: buildObsidianTheme(),
            themeMode: themeMode,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        final repo = getIt<SubscriptionRepository>();
        state.when(
          unknown: () {},
          loading: () {},
          unauthenticated: (_) => repo.logOut(),
          authenticated: (profile) => repo.logIn(profile.id),
        );
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return state.when(
            unknown: () => Scaffold(
              backgroundColor: surface,
              body: const Center(child: CircularProgressIndicator()),
            ),
            loading: () => Scaffold(
              backgroundColor: surface,
              body: const Center(child: CircularProgressIndicator()),
            ),
            unauthenticated: (errorMessage) =>
                LoginPage(errorMessage: errorMessage),
            authenticated: (profile) => DashboardPage(profile: profile),
          );
        },
      ),
    );
  }
}
