import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/obsidian_note_list_tile.dart';
import 'package:sample/features/audio_notes/presentation/pages/note_detail_page.dart';
import 'package:sample/features/audio_notes/presentation/utils/audio_note_status_ui.dart';
import 'package:sample/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:sample/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:sample/features/tags/presentation/bloc/tags_cubit.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites', style: theme.textTheme.headlineLarge),
      ),
      body: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (notes, _) {
              if (notes.isEmpty) return _buildEmpty(t, theme);
              return RefreshIndicator(
                color: t.primary,
                backgroundColor: t.surfaceContainer,
                onRefresh: () async {
                  context.read<FavoritesBloc>().add(
                    const FavoritesEvent.refreshed(),
                  );
                  await Future<void>.delayed(const Duration(milliseconds: 350));
                },
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    0,
                    AppSpacing.base,
                    obsidianFabBottomPadding(context) + AppSpacing.lg,
                  ),
                  itemCount: notes.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final n = notes[index];
                    return ObsidianNoteListTile(
                      index: index,
                      title: n.title,
                      status: n.status,
                      trailing: FavoriteButton(noteId: n.id, size: 18),
                      subtitle:
                          '${dateFmt.format(n.createdAt.toLocal())} · '
                          '${_formatDuration(n.durationSeconds)} · '
                          '${audioNoteStatusLabel(n.status)}',
                      onTap: () async {
                        final favBloc = context.read<FavoritesBloc>();
                        final tagsCubit = context.read<TagsCubit>();
                        await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => MultiBlocProvider(
                              providers: [
                                BlocProvider<FavoritesBloc>.value(
                                  value: favBloc,
                                ),
                                BlocProvider<TagsCubit>.value(value: tagsCubit),
                              ],
                              child: NoteDetailPage(noteId: n.id),
                            ),
                          ),
                        );
                        if (context.mounted) {
                          context.read<FavoritesBloc>().add(
                            const FavoritesEvent.refreshed(),
                          );
                        }
                      },
                    );
                  },
                ),
              );
            },
            failure: (message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: t.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    TextButton(
                      onPressed: () => context.read<FavoritesBloc>().add(
                        const FavoritesEvent.started(),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(ObsidianUiTokens t, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 64,
              color: t.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No favorites yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap the heart icon on any note to save it here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: t.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
