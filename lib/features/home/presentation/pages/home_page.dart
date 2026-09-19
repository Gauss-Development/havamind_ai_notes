import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/app_section_header.dart';
import 'package:sample/core/widgets/founder_backdrop.dart';
import 'package:sample/core/widgets/obsidian_gradient_button.dart';
import 'package:sample/core/widgets/obsidian_note_list_tile.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';
import 'package:sample/features/audio_notes/presentation/bloc/audio_notes_list_bloc.dart';
import 'package:sample/features/audio_notes/presentation/utils/recording_flow.dart';
import 'package:sample/features/audio_notes/presentation/widgets/audio_note_duration_formatter.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';
import 'package:sample/features/home/presentation/utils/select_last_debrief_note.dart';
import 'package:sample/features/thesis/presentation/cubit/thesis_home_cubit.dart';
import 'package:sample/features/thesis/presentation/utils/open_thesis_result_page.dart';
import 'package:sample/features/thesis/presentation/widgets/thesis_home_actions.dart';
import 'package:sample/features/thesis/presentation/widgets/thesis_home_card.dart';
import 'package:sample/features/thesis/presentation/widgets/thesis_week_export_sheet.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

/// Home tab — living thesis card and debrief CTA. Notes stay an archive.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final l10n = AppLocalizations.of(context)!;
    final greetingName = profile.displayName.trim().isEmpty
        ? l10n.homeGreetingFallback
        : profile.displayName.trim().split(' ').first;

    return Scaffold(
      backgroundColor: t.surface,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<AudioNotesListBloc, AudioNotesListState>(
          builder: (context, notesState) {
            final notes = notesState.maybeWhen(
              loaded: (loadedNotes, _, _) => loadedNotes,
              orElse: () => const <AudioNote>[],
            );
            final lastDebrief = selectLastDebriefNote(notes);

            return RefreshIndicator(
              color: t.primary,
              backgroundColor: t.surfaceContainer,
              onRefresh: () async {
                context.read<AudioNotesListBloc>().add(
                  const AudioNotesListEvent.refreshed(),
                );
                await context.read<ThesisHomeCubit>().refresh();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _HomeHero(
                      name: greetingName,
                      lastDebrief: lastDebrief,
                      onDebrief: () => _openDebrief(context),
                      onColdPitch: () => _openColdPitch(context),
                      onCollectWeek: () => _openCollectWeek(context),
                      onOpenDebriefNote: lastDebrief == null
                          ? null
                          : () => _openDebriefResult(context, lastDebrief.id),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: appFabBottomPadding(context) + AppSpacing.xl,
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
          onPressed: () => _openDebrief(context),
          icon: Icons.mic_rounded,
          label: l10n.thesisDebriefFab,
        ),
      ),
    );
  }

  Future<void> _openDebrief(BuildContext context) {
    return _openRecording(context, RecordingTemplateIds.customerDiscovery);
  }

  Future<void> _openColdPitch(BuildContext context) {
    return _openRecording(context, RecordingTemplateIds.founderPitch);
  }

  Future<void> _openCollectWeek(BuildContext context) {
    return showThesisWeekExportSheet(context: context);
  }

  Future<void> _openRecording(BuildContext context, String templateId) async {
    final result = await openRecordingFlow(context, templateId: templateId);
    if (!context.mounted || result == null || result == false) return;
    context.read<AudioNotesListBloc>().add(
      const AudioNotesListEvent.refreshed(),
    );
    await context.read<ThesisHomeCubit>().refresh();
    if (!context.mounted) return;
    if (result is AudioNote) {
      await openThesisResultPage(context, result.id);
      if (!context.mounted) return;
      context.read<AudioNotesListBloc>().add(
        const AudioNotesListEvent.refreshed(),
      );
      await context.read<ThesisHomeCubit>().refresh();
    }
  }
}

Future<void> _openDebriefResult(BuildContext context, String noteId) async {
  await openThesisResultPage(context, noteId);
  if (!context.mounted) return;
  context.read<AudioNotesListBloc>().add(const AudioNotesListEvent.refreshed());
  await context.read<ThesisHomeCubit>().refresh();
}

// ─── Hero block ──────────────────────────────────────────────────────────────

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.name,
    required this.lastDebrief,
    required this.onDebrief,
    required this.onColdPitch,
    required this.onCollectWeek,
    this.onOpenDebriefNote,
  });

  final String name;
  final AudioNote? lastDebrief;
  final VoidCallback onDebrief;
  final VoidCallback onColdPitch;
  final VoidCallback onCollectWeek;
  final VoidCallback? onOpenDebriefNote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.appTokens;
    final theme = Theme.of(context);

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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _timeGreeting(l10n),
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
            const SizedBox(height: AppSpacing.lg),
            BlocBuilder<ThesisHomeCubit, ThesisHomeState>(
              builder: (context, state) {
                return switch (state) {
                  ThesisHomeInitial() ||
                  ThesisHomeLoading() => const _ThesisCardPlaceholder(),
                  ThesisHomeError(:final failure) => _ThesisErrorCard(
                    message: failure.message,
                    onRetry: () => context.read<ThesisHomeCubit>().load(),
                  ),
                  ThesisHomeLoaded loaded => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ThesisHomeCard(loaded: loaded),
                      const SizedBox(height: AppSpacing.lg),
                      ThesisHomeActions(
                        isBlankThesis: loaded.isBlank,
                        onDebrief: onDebrief,
                        onColdPitch: onColdPitch,
                        onCollectWeek: onCollectWeek,
                      ),
                    ],
                  ),
                };
              },
            ),
            if (lastDebrief != null && onOpenDebriefNote != null) ...[
              AppSectionHeader(
                eyebrow: l10n.thesisLastDebriefEyebrow,
                title: l10n.thesisLastDebriefTitle,
                padding: const EdgeInsets.fromLTRB(
                  0,
                  AppSpacing.xl,
                  0,
                  AppSpacing.md,
                ),
              ),
              AppNoteListTile(
                title: lastDebrief!.title.trim().isEmpty
                    ? l10n.planReadinessUntitledNote
                    : lastDebrief!.title,
                subtitle: _noteSubtitle(lastDebrief!),
                onTap: onOpenDebriefNote!,
                status: lastDebrief!.status,
                index: 0,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _timeGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.homeGreetingMorning;
    if (hour < 17) return l10n.homeGreetingAfternoon;
    return l10n.homeGreetingEvening;
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);
    final initial = name.trim().isEmpty
        ? '?'
        : name.characters.first.toUpperCase();

    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.surfaceContainerLowest,
        shape: BoxShape.circle,
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

class _ThesisCardPlaceholder extends StatelessWidget {
  const _ThesisCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXl),
      ),
      child: const SizedBox(
        height: 168,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ThesisErrorCard extends StatelessWidget {
  const _ThesisErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.appTokens;
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.thesisLoadError,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: t.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppGradientButton(
              onPressed: onRetry,
              label: l10n.thesisRetry,
              variant: AppButtonVariant.outlined,
            ),
          ],
        ),
      ),
    );
  }
}

String _noteSubtitle(AudioNote note) {
  final date = DateFormat.MMMd().format(note.createdAt.toLocal());
  final duration = AudioNoteDurationFormatter.mmSs(note.durationSeconds);
  return '$date · $duration';
}
