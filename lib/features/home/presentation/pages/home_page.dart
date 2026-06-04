import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sample/core/di/injection.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/app_gradient_card.dart';
import 'package:sample/core/widgets/app_icon_chip.dart';
import 'package:sample/core/widgets/app_section_header.dart';
import 'package:sample/core/widgets/founder_backdrop.dart';
import 'package:sample/core/widgets/obsidian_gradient_button.dart';
import 'package:sample/core/widgets/obsidian_note_list_tile.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/entities/note_search_hit.dart';
import 'package:sample/features/audio_notes/domain/usecases/search_notes_usecase.dart';
import 'package:sample/features/audio_notes/presentation/bloc/audio_notes_list_bloc.dart';
import 'package:sample/features/audio_notes/presentation/cubit/notes_count_cubit.dart';
import 'package:sample/features/audio_notes/presentation/cubit/plan_readiness_home_cubit.dart';
import 'package:sample/features/audio_notes/presentation/widgets/plan_readiness_nudge_card.dart';
import 'package:sample/features/audio_notes/presentation/pages/note_detail_page.dart';
import 'package:sample/features/audio_notes/presentation/utils/recording_flow.dart';
import 'package:sample/features/audio_notes/presentation/widgets/audio_note_duration_formatter.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';
import 'package:sample/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:sample/features/tags/presentation/bloc/tags_cubit.dart';
import 'package:sample/features/search/presentation/widgets/home_notes_search_section.dart';

/// Home tab — bold, vibrant landing for the audio notes app.
///
/// Composition (top → bottom):
///   1. Hero block: radial brand backdrop + greeting + stat chips.
///   2. Primary CTA: gradient hero card summarizing the library +
///      "Record" tap target. Becomes a "first note" prompt when empty.
///   3. Search: existing memoized search section (recently optimized).
///   4. Recent notes: `AppSectionHeader` + `AppNoteListTile` rows.
///
/// FAB: `AppGradientFab` extended action, kept above the floating nav.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final greetingName = profile.displayName.trim().isEmpty
        ? 'there'
        : profile.displayName.trim().split(' ').first;

    return Scaffold(
      backgroundColor: t.surface,
      body: SafeArea(
        bottom: false,
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
            final totalCount = context.watch<NotesCountCubit>().state;

            return RefreshIndicator(
              color: t.primary,
              backgroundColor: t.surfaceContainer,
              onRefresh: () async {
                context.read<AudioNotesListBloc>().add(
                  const AudioNotesListEvent.refreshed(),
                );
                await Future<void>.delayed(
                  const Duration(milliseconds: 350),
                );
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Hero header (greeting + stats + CTA card) ───────────
                  SliverToBoxAdapter(
                    child: _HomeHero(
                      name: greetingName,
                      notes: notes,
                      totalCount: totalCount,
                      onRecord: () => _openRecording(context),
                    ),
                  ),

                  // ── Search ──────────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: HomeNotesSearchSection(
                        notesCount: totalCount,
                        onSearch: _searchNotes,
                        onOpenNote: (noteId) =>
                            _openNoteDetail(context, noteId),
                      ),
                    ),
                  ),

                  // ── Recent notes section header ─────────────────────────
                  if (notes.isNotEmpty)
                    SliverToBoxAdapter(
                      child: AppSectionHeader(
                        eyebrow: 'Library',
                        title: 'Recent notes',
                        subtitle: _savedSubtitle(totalCount, notes.length),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.xl,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                      ),
                    ),

                  // ── Recent notes list / empty / loading ─────────────────
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
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        appFabBottomPadding(context) + AppSpacing.xl,
                      ),
                      sliver: SliverList.separated(
                        itemCount: notes.length > 5 ? 5 : notes.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return AppNoteListTile(
                            title: note.title,
                            subtitle: _noteSubtitle(note),
                            onTap: () => _openNoteDetail(context, note.id),
                            status: note.status,
                            index: index,
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
        padding: EdgeInsets.only(bottom: appFabBottomPadding(context)),
        child: AppGradientFab(
          onPressed: () => _openRecording(context),
          icon: Icons.mic_rounded,
          label: 'New note',
        ),
      ),
    );
  }

  Future<List<NoteSearchHit>> _searchNotes(String query) async {
    final result = await getIt<SearchNotesUseCase>()(
      SearchNotesParams(query: query),
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (hits) => hits,
    );
  }

  Future<void> _openRecording(BuildContext context) async {
    final added = await openRecordingFlow(context);
    if (context.mounted && added == true) {
      context.read<AudioNotesListBloc>().add(
        const AudioNotesListEvent.refreshed(),
      );
    }
  }
}

String _savedSubtitle(int? totalCount, int loadedCount) {
  final n = totalCount ?? loadedCount;
  return n == 1 ? '1 saved' : '$n saved';
}

Future<void> _openNoteDetail(BuildContext context, String noteId) async {
  final favBloc = context.read<FavoritesBloc>();
  final tagsCubit = context.read<TagsCubit>();
  await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<FavoritesBloc>.value(value: favBloc),
          BlocProvider<TagsCubit>.value(value: tagsCubit),
        ],
        child: NoteDetailPage(noteId: noteId),
      ),
    ),
  );
  if (!context.mounted) return;
  context.read<AudioNotesListBloc>().add(
    const AudioNotesListEvent.refreshed(),
  );
}

String _noteSubtitle(AudioNote note) {
  final dateFmt = DateFormat.MMMd();
  final date = dateFmt.format(note.createdAt.toLocal());
  final duration = AudioNoteDurationFormatter.mmSs(note.durationSeconds);
  return '$date · $duration';
}

// ─── Hero block ──────────────────────────────────────────────────────────────

/// Top-of-page hero: backdrop blob + greeting + stat chips + CTA card.
///
/// Pulled out of [HomePage] so the surrounding scrollable stays declarative
/// and the hero can own its own paint subtree (radial gradient + gradient
/// card) without interfering with sliver rebuilds.
class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.name,
    required this.notes,
    required this.totalCount,
    required this.onRecord,
  });

  final String name;
  final List<AudioNote> notes;
  final int? totalCount;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);
    final greeting = _timeGreeting();

    return AppHeroBackdrop(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting row.
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: t.primary,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _Avatar(name: name),
              ],
            ),

            // Inline stat chips (only when there's something to show).
            if (notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _StatsChips(notes: notes, totalCount: totalCount),
            ],

            BlocBuilder<PlanReadinessHomeCubit, PlanReadinessNudge?>(
              buildWhen: (previous, current) => previous != current,
              builder: (context, nudge) {
                if (nudge == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: PlanReadinessNudgeCard(
                    nudge: nudge,
                    onTap: () => _openNoteDetail(context, nudge.noteId),
                  ),
                );
              },
            ),

            // Hero CTA card.
            const SizedBox(height: AppSpacing.lg),
            _HeroCtaCard(notes: notes, onRecord: onRecord),
          ],
        ),
      ),
    );
  }

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);
    final initial =
        name.trim().isEmpty ? '?' : name.characters.first.toUpperCase();

    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.surfaceContainerLowest,
        shape: BoxShape.circle,
        border: Border.all(color: t.primary.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Text(
        initial,
        style: theme.textTheme.titleMedium?.copyWith(
          color: t.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─── Stats ───────────────────────────────────────────────────────────────────

class _StatsChips extends StatelessWidget {
  const _StatsChips({required this.notes, required this.totalCount});

  final List<AudioNote> notes;
  final int? totalCount;

  @override
  Widget build(BuildContext context) {
    final total = totalCount ?? notes.length;
    final ready =
        notes.where((n) => n.status == AudioNoteStatus.completed).length;
    final processing =
        notes.where((n) => n.status.isPendingPipeline).length;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        AppIconChip(
          icon: Icons.library_music_rounded,
          label: '$total total',
          tone: AppIconChipTone.brand,
        ),
        if (ready > 0)
          AppIconChip(
            icon: Icons.check_circle_outline_rounded,
            label: '$ready ready',
            tone: AppIconChipTone.success,
          ),
        if (processing > 0)
          AppIconChip(
            icon: Icons.hourglass_top_rounded,
            label: '$processing processing',
            tone: AppIconChipTone.warning,
          ),
      ],
    );
  }
}

// ─── Hero CTA card ───────────────────────────────────────────────────────────

class _HeroCtaCard extends StatelessWidget {
  const _HeroCtaCard({required this.notes, required this.onRecord});

  final List<AudioNote> notes;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);
    final isFirstRun = notes.isEmpty;

    final headline = isFirstRun ? 'Capture your first thought' : 'Ready when you are';
    final body = isFirstRun
        ? 'Tap record and we’ll transcribe, summarize, and tag it for you.'
        : 'Pick up where you left off — record a new note in one tap.';

    return AppGradientCard(
      onTap: onRecord,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: t.onPrimaryButton,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: t.onPrimaryButton.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Decorative mic medallion. Not the primary tap target — the whole
          // card is tappable, and the FAB / "Record" button below take the
          // explicit input.
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.onPrimaryButton.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: t.onPrimaryButton.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.mic_rounded,
              color: t.onPrimaryButton,
              size: 26,
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
    final t = context.appTokens;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: t.accentGradient,
                shape: BoxShape.circle,
                boxShadow: t.vibrantGlow,
              ),
              child: Icon(
                Icons.graphic_eq_rounded,
                size: 36,
                color: t.onPrimaryButton,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No notes yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Record a voice note and it will appear here, '
              'fully transcribed and searchable.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: t.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppGradientButton(
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
