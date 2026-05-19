import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample/core/di/injection.dart';
import 'package:sample/core/widgets/obsidian_floating_nav_bar.dart';
import 'package:sample/features/audio_notes/presentation/bloc/audio_notes_list_bloc.dart';
import 'package:sample/features/audio_notes/presentation/cubit/notes_count_cubit.dart';
import 'package:sample/features/audio_notes/presentation/pages/notes_list_page.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';
import 'package:sample/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:sample/features/subscription/presentation/cubit/subscription_cubit.dart';
import 'package:sample/features/tags/presentation/bloc/tags_cubit.dart';
import 'package:sample/features/favorites/presentation/pages/favorites_page.dart';
import 'package:sample/features/home/presentation/pages/home_page.dart';
import 'package:sample/features/profile/presentation/pages/profile_page.dart';

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
    // Load early — the RC status callback mirrors the tier into
    // `profiles.subscription_tier`, which the Edge Function usage gate
    // reads server-side. Without this, the first recording attempt by
    // a freshly signed-in paid user gets gated as if they were free.
    _subscriptionCubit = getIt<SubscriptionCubit>()..loadStatus();
  }

  @override
  void dispose() {
    _audioNotesListBloc.close();
    _favoritesBloc.close();
    _tagsCubit.close();
    _notesCountCubit.close();
    // SubscriptionCubit is a lazySingleton; do not close it here.
    super.dispose();
  }

  static const _items = [
    ObsidianNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    ObsidianNavItem(
      icon: Icons.description_outlined,
      activeIcon: Icons.description_rounded,
      label: 'Notes',
    ),
    ObsidianNavItem(
      icon: Icons.favorite_border_rounded,
      activeIcon: Icons.favorite_rounded,
      label: 'Favorites',
    ),
    ObsidianNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AudioNotesListBloc>.value(value: _audioNotesListBloc),
        BlocProvider<FavoritesBloc>.value(value: _favoritesBloc),
        BlocProvider<TagsCubit>.value(value: _tagsCubit),
        BlocProvider<NotesCountCubit>.value(value: _notesCountCubit),
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
          context.read<NotesCountCubit>().refresh();
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
            items: _items,
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
          ),
        ),
      ),
    );
  }
}
