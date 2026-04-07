import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/obsidian_gradient_button.dart';
import 'package:sample/core/widgets/obsidian_note_list_tile.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/presentation/bloc/audio_notes_list_bloc.dart';
import 'package:sample/features/audio_notes/presentation/pages/note_detail_page.dart';
import 'package:sample/features/audio_notes/presentation/pages/recording_page.dart';
import 'package:sample/features/audio_notes/presentation/utils/audio_note_status_ui.dart';
import 'package:sample/features/audio_notes/presentation/widgets/audio_note_duration_formatter.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';
import 'package:sample/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:sample/features/favorites/presentation/widgets/favorite_button.dart';

class NotesListPage extends StatelessWidget {
  const NotesListPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) => const _NotesListView();
}

class _NotesListView extends StatelessWidget {
  const _NotesListView();

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notes', style: theme.textTheme.headlineLarge),
      ),
      body: BlocConsumer<AudioNotesListBloc, AudioNotesListState>(
        listener: (context, state) {
          state.maybeWhen(
            failure: (m) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(m)),
              );
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (notes, hasReachedEnd, isLoadingMore) {
              if (notes.isEmpty) return _buildEmpty(context, t, theme);
              return _buildList(context, notes, t);
            },
            failure: (message) => _buildError(context, t, theme, message),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: obsidianFabBottomPadding(context)),
        child: ObsidianGradientButton(
          onPressed: () => _openRecording(context),
          icon: Icons.mic_rounded,
          label: 'Record',
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEmpty(BuildContext context, ObsidianUiTokens t, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_none_rounded,
              size: 64,
              color: t.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No notes yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap the record button to create your first note.',
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

  Widget _buildList(
    BuildContext context,
    List<AudioNote> notes,
    ObsidianUiTokens t,
  ) {
    final groups = _groupByDate(notes);
    final theme = Theme.of(context);

    return RefreshIndicator(
      color: t.primary,
      backgroundColor: t.surfaceContainer,
      onRefresh: () async {
        context.read<AudioNotesListBloc>().add(
          const AudioNotesListEvent.refreshed(),
        );
        await Future<void>.delayed(const Duration(milliseconds: 350));
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          0,
          AppSpacing.base,
          120,
        ),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  index == 0 ? AppSpacing.sm : AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.sm,
                ),
                child: Text(
                  group.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: t.onSurfaceVariant,
                  ),
                ),
              ),
              ...group.notes.asMap().entries.map((entry) {
                final n = entry.value;
                final dateFmt = DateFormat('dd.MM.yyyy HH:mm');
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ObsidianNoteListTile(
                    index: entry.key,
                    title: n.title,
                    status: n.status,
                    trailing: FavoriteButton(noteId: n.id, size: 18),
                    subtitle:
                        '${dateFmt.format(n.createdAt.toLocal())} · '
                        '${AudioNoteDurationFormatter.mmSs(n.durationSeconds)} · '
                        '${audioNoteStatusLabel(n.status)}',
                    onTap: () => _openNoteDetail(context, n.id),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    ObsidianUiTokens t,
    ThemeData theme,
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: t.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ObsidianGradientButton(
              onPressed: () => context.read<AudioNotesListBloc>().add(
                const AudioNotesListEvent.started(),
              ),
              label: 'Retry',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRecording(BuildContext context) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const RecordingPage(),
      ),
    );
    if (context.mounted && added == true) {
      context.read<AudioNotesListBloc>().add(
        const AudioNotesListEvent.refreshed(),
      );
    }
  }

  Future<void> _openNoteDetail(BuildContext context, String noteId) async {
    final favBloc = context.read<FavoritesBloc>();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: favBloc,
          child: NoteDetailPage(noteId: noteId),
        ),
      ),
    );
    if (context.mounted) {
      context.read<AudioNotesListBloc>().add(
        const AudioNotesListEvent.refreshed(),
      );
      context.read<FavoritesBloc>().add(const FavoritesEvent.refreshed());
    }
  }
}

// ─── Date grouping ───────────────────────────────────────────────────────────

class _DateGroup {
  const _DateGroup({required this.label, required this.notes});
  final String label;
  final List<AudioNote> notes;
}

List<_DateGroup> _groupByDate(List<AudioNote> notes) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final weekAgo = today.subtract(const Duration(days: 7));

  final todayNotes = <AudioNote>[];
  final yesterdayNotes = <AudioNote>[];
  final thisWeekNotes = <AudioNote>[];
  final earlierNotes = <AudioNote>[];

  for (final note in notes) {
    final d = DateTime(
      note.createdAt.year,
      note.createdAt.month,
      note.createdAt.day,
    );
    if (d == today) {
      todayNotes.add(note);
    } else if (d == yesterday) {
      yesterdayNotes.add(note);
    } else if (d.isAfter(weekAgo)) {
      thisWeekNotes.add(note);
    } else {
      earlierNotes.add(note);
    }
  }

  return [
    if (todayNotes.isNotEmpty) _DateGroup(label: 'TODAY', notes: todayNotes),
    if (yesterdayNotes.isNotEmpty)
      _DateGroup(label: 'YESTERDAY', notes: yesterdayNotes),
    if (thisWeekNotes.isNotEmpty)
      _DateGroup(label: 'THIS WEEK', notes: thisWeekNotes),
    if (earlierNotes.isNotEmpty)
      _DateGroup(label: 'EARLIER', notes: earlierNotes),
  ];
}
