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
import 'package:sample/flavors.dart';
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
            title: F.title,
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
      listener: (context, state) async {
        final repo = getIt<SubscriptionRepository>();
        // We deliberately don't block on these — auth state changes shouldn't
        // be stalled by RevenueCat I/O — but we DO await the Future so that
        // PlatformException paths run their Left branch instead of being
        // swallowed as unhandled errors on the zone.
        await state.when(
          unknown: () async {},
          loading: () async {},
          unauthenticated: (_) async {
            final result = await repo.logOut();
            result.fold(
              (failure) => debugPrint(
                'RevenueCat logOut failed: ${failure.message}',
              ),
              (_) {},
            );
          },
          authenticated: (profile) async {
            final result = await repo.logIn(profile.id);
            result.fold(
              (failure) => debugPrint(
                'RevenueCat logIn failed: ${failure.message}',
              ),
              (_) {},
            );
          },
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
