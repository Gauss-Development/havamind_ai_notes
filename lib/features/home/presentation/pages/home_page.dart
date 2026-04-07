import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/obsidian_gradient_button.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/presentation/bloc/audio_notes_list_bloc.dart';
import 'package:sample/features/audio_notes/presentation/pages/note_detail_page.dart';
import 'package:sample/features/audio_notes/presentation/pages/recording_page.dart';
import 'package:sample/features/audio_notes/presentation/utils/audio_note_status_ui.dart';
import 'package:sample/features/audio_notes/presentation/widgets/audio_note_duration_formatter.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';
import 'package:sample/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:sample/features/search/presentation/widgets/home_notes_search_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final greetingName = profile.displayName.trim().isEmpty
        ? 'there'
        : profile.displayName.trim().split(' ').first;

    return Scaffold(
      backgroundColor: t.surface,
      body: SafeArea(
        child: BlocBuilder<AudioNotesListBloc, AudioNotesListState>(
          builder: (context, state) {
            final notes = state.maybeWhen(
              loaded: (loadedNotes, _, _) => loadedNotes,
              orElse: () => const <AudioNote>[],
            );
            final isLoading = state.maybeWhen(
              loading: () => true,
              orElse: () => false,
            );

            return RefreshIndicator(
              color: t.primary,
              backgroundColor: t.surfaceContainer,
              onRefresh: () async {
                context.read<AudioNotesListBloc>().add(
                  const AudioNotesListEvent.refreshed(),
                );
                await Future<void>.delayed(const Duration(milliseconds: 350));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.base,
                      AppSpacing.lg,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _Header(name: greetingName),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.base,
                      AppSpacing.lg,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _StatsRow(notes: notes),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: HomeNotesSearchSection(
                        notes: notes,
                        notesCount: notes.length,
                        onOpenNote: (noteId) =>
                            _openNoteDetail(context, noteId),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Recent Notes',
                        count: notes.length,
                      ),
                    ),
                  ),
                  if (isLoading && notes.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (notes.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        onRecord: () => _openRecording(context),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        140,
                      ),
                      sliver: SliverList.separated(
                        itemCount: notes.length > 5 ? 5 : notes.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return _RecentNoteTile(
                            note: note,
                            onTap: () =>
                                _openNoteDetail(context, note.id),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: obsidianFabBottomPadding(context)),
        child: ObsidianGradientButton(
          onPressed: () => _openRecording(context),
          icon: Icons.mic_rounded,
          label: 'New Note',
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
  if (!context.mounted) return;
  context.read<AudioNotesListBloc>().add(
    const AudioNotesListEvent.refreshed(),
  );
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final greeting = _timeGreeting();

    return Row(
      children: [
        Expanded(
          child: Text(
            '$greeting, $name',
            style: theme.textTheme.headlineLarge,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.surfaceContainerLowest,
            shape: BoxShape.circle,
            border: Border.all(color: t.ghostBorder(0.14)),
          ),
          child: Text(
            name.characters.first.toUpperCase(),
            style: theme.textTheme.titleMedium?.copyWith(color: t.primary),
          ),
        ),
      ],
    );
  }

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ─── Stats row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.notes});

  final List<AudioNote> notes;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final total = notes.length;
    final ready =
        notes.where((n) => n.status == AudioNoteStatus.completed).length;
    final processing =
        notes.where((n) => n.status.isPendingPipeline).length;

    if (total == 0) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.library_music_rounded,
            value: '$total',
            label: 'Total',
            accent: t.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline_rounded,
            value: '$ready',
            label: 'Ready',
            accent: t.secondary,
          ),
        ),
        if (processing > 0) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatCard(
              icon: Icons.hourglass_top_rounded,
              value: '$processing',
              label: 'Processing',
              accent: t.warning,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: t.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusSm),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: t.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.obsidian;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: theme.textTheme.headlineMedium),
          ),
          if (count > 0)
            Text(
              '$count notes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: t.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRecord});

  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

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
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No notes yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Record a voice note and it will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: t.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ObsidianGradientButton(
              onPressed: onRecord,
              icon: Icons.mic_rounded,
              label: 'Record your first note',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recent note tile ────────────────────────────────────────────────────────

class _RecentNoteTile extends StatelessWidget {
  const _RecentNoteTile({required this.note, required this.onTap});

  final AudioNote note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final statusColor = audioNoteStatusColor(context, note.status);
    final dateFmt = DateFormat.MMMd();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            color: t.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
            border: Border.all(color: t.ghostBorder(0.12)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(ObsidianUiTokens.radiusSm),
                  ),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    size: 20,
                    color: t.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dateFmt.format(note.createdAt.toLocal())} · '
                        '${AudioNoteDurationFormatter.mmSs(note.durationSeconds)}',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (note.status.isPendingPipeline)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: statusColor,
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: t.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
