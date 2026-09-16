import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample/core/di/injection.dart';
import 'package:sample/core/widgets/obsidian_floating_nav_bar.dart';
import 'package:sample/features/audio_notes/presentation/bloc/audio_notes_list_bloc.dart';
import 'package:sample/features/audio_notes/presentation/cubit/notes_count_cubit.dart';
import 'package:sample/features/audio_notes/presentation/pages/notes_list_page.dart';
import 'package:sample/features/thesis/presentation/cubit/thesis_home_cubit.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';
import 'package:sample/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:sample/features/subscription/presentation/cubit/subscription_cubit.dart';
import 'package:sample/features/tags/presentation/bloc/tags_cubit.dart';
import 'package:sample/features/favorites/presentation/pages/favorites_page.dart';
import 'package:sample/features/home/presentation/pages/home_page.dart';
import 'package:sample/features/profile/presentation/pages/profile_page.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  late final AudioNotesListBloc _audioNotesListBloc;
  late final FavoritesBloc _favoritesBloc;
  late final TagsCubit _tagsCubit;
  late final NotesCountCubit _notesCountCubit;
  late final ThesisHomeCubit _thesisHomeCubit;
  late final SubscriptionCubit _subscriptionCubit;

  @override
  void initState() {
    super.initState();
    _audioNotesListBloc = getIt<AudioNotesListBloc>()
      ..add(const AudioNotesListEvent.started());
    _favoritesBloc = getIt<FavoritesBloc>()
      ..add(const FavoritesEvent.started());
    _tagsCubit = getIt<TagsCubit>()..load();
    // Refreshes on construction so the count is ready by first paint.
    _notesCountCubit = getIt<NotesCountCubit>();
    _thesisHomeCubit = getIt<ThesisHomeCubit>()..load();
    // Load early so paywall/usage UI is ready by first paint. Server-side
    // gates read subscription state that is written by trusted backend paths.
    _subscriptionCubit = getIt<SubscriptionCubit>()..loadStatus();
  }

  @override
  void dispose() {
    _audioNotesListBloc.close();
    _favoritesBloc.close();
    _tagsCubit.close();
    _notesCountCubit.close();
    _thesisHomeCubit.close();
    // SubscriptionCubit is a lazySingleton; do not close it here.
    super.dispose();
  }

  List<ObsidianNavItem> _items(AppLocalizations l10n) => [
    ObsidianNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: l10n.home,
    ),
    ObsidianNavItem(
      icon: Icons.description_outlined,
      activeIcon: Icons.description_rounded,
      label: l10n.notes,
    ),
    ObsidianNavItem(
      icon: Icons.favorite_border_rounded,
      activeIcon: Icons.favorite_rounded,
      label: l10n.favorites,
    ),
    ObsidianNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: l10n.profile,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MultiBlocProvider(
      providers: [
        BlocProvider<AudioNotesListBloc>.value(value: _audioNotesListBloc),
        BlocProvider<FavoritesBloc>.value(value: _favoritesBloc),
        BlocProvider<TagsCubit>.value(value: _tagsCubit),
        BlocProvider<NotesCountCubit>.value(value: _notesCountCubit),
        BlocProvider<ThesisHomeCubit>.value(value: _thesisHomeCubit),
        BlocProvider<SubscriptionCubit>.value(value: _subscriptionCubit),
      ],
      child: BlocListener<AudioNotesListBloc, AudioNotesListState>(
        // Mounted at dashboard root so the total count stays accurate
        // regardless of which tab is currently visible (delete from Notes
        // list, record from any tab, refresh, etc.). Freezed equality
        // suppresses duplicate fires for no-op reloads.
        listenWhen: (prev, curr) =>
            curr.maybeWhen(loaded: (_, _, _) => true, orElse: () => false),
        listener: (context, state) {
          state.maybeWhen(
            loaded: (_, _, _) {
              context.read<NotesCountCubit>().refresh();
              context.read<ThesisHomeCubit>().refresh();
            },
            orElse: () {},
          );
        },
        child: Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              HomePage(profile: widget.profile),
              NotesListPage(profile: widget.profile),
              const FavoritesPage(),
              ProfilePage(profile: widget.profile),
            ],
          ),
          extendBody: true,
          bottomNavigationBar: ObsidianFloatingNavBar(
            items: _items(l10n),
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
          ),
        ),
      ),
    );
  }
}
