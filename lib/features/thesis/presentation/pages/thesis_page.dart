import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sample/core/di/injection.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/obsidian_gradient_button.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';
import 'package:sample/features/audio_notes/presentation/pages/note_detail_page.dart';
import 'package:sample/features/audio_notes/presentation/utils/recording_flow.dart';
import 'package:sample/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:sample/features/tags/presentation/bloc/tags_cubit.dart';
import 'package:sample/features/thesis/presentation/cubit/thesis_result_cubit.dart';
import 'package:sample/features/thesis/presentation/utils/open_thesis_result_page.dart';
import 'package:sample/features/thesis/presentation/widgets/thesis_field_diff_section.dart';
import 'package:sample/features/thesis/presentation/widgets/thesis_next_conversation_card.dart';
import 'package:sample/features/thesis/presentation/widgets/thesis_unbacked_stakes_card.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

/// Post-debrief result: field diff, unbacked stakes, next conversation.
///
/// Not [NoteDetailPage]. That stays the archive for transcript and tags.
class ThesisPage extends StatelessWidget {
  const ThesisPage({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ThesisResultCubit>(param1: noteId)..start(),
      child: const _ThesisResultView(),
    );
  }
}

class _ThesisResultView extends StatelessWidget {
  const _ThesisResultView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.appTokens;

    return Scaffold(
      backgroundColor: t.surface,
      appBar: AppBar(
        title: Text(
          l10n.thesisResultTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: BlocBuilder<ThesisResultCubit, ThesisResultState>(
          builder: (context, state) {
            return switch (state) {
              ThesisResultInitial() => const _StatusCard(busy: true),
              ThesisResultProcessing() => _StatusCard(
                busy: true,
                title: l10n.thesisResultProcessing,
                body: l10n.thesisResultProcessingHint,
              ),
              ThesisResultApplying() => _StatusCard(
                busy: true,
                title: l10n.thesisResultApplying,
                body: l10n.thesisResultApplyingHint,
              ),
              ThesisResultNoteFailed(:final note) => _StatusCard(
                title: l10n.thesisResultFailed,
                body: note.lastProcessingError?.trim().isNotEmpty == true
                    ? note.lastProcessingError
                    : l10n.thesisResultFailedHint,
                actionLabel: l10n.thesisRetry,
                onAction: () =>
                    context.read<ThesisResultCubit>().retryProcessing(),
              ),
              ThesisResultError(:final failure) => _StatusCard(
                title: l10n.thesisLoadError,
                body: failure.message,
                actionLabel: l10n.thesisRetry,
                onAction: () => context.read<ThesisResultCubit>().start(),
              ),
              ThesisResultLoaded loaded => _LoadedResult(
                loaded: loaded,
                onAnswerByVoice: (question) =>
                    _replyUnbacked(context, question),
                onOpenTranscript: () =>
                    _openTranscript(context, loaded.note.id),
                onDone: () => Navigator.of(context).maybePop(),
              ),
            };
          },
        ),
      ),
    );
  }

  Future<void> _replyUnbacked(BuildContext context, String question) async {
    final result = await openRecordingFlow(
      context,
      templateId: RecordingTemplateIds.customerDiscovery,
      voicePrompt: question,
    );
    if (!context.mounted) return;
    if (result is! AudioNote) return;
    await openThesisResultPage(context, result.id);
  }

  Future<void> _openTranscript(BuildContext context, String noteId) async {
    final favBloc = context.read<FavoritesBloc>();
    final tagsCubit = context.read<TagsCubit>();
    await Navigator.of(context).push<void>(
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
  }
}

class _LoadedResult extends StatelessWidget {
  const _LoadedResult({
    required this.loaded,
    required this.onAnswerByVoice,
    required this.onOpenTranscript,
    required this.onDone,
  });

  final ThesisResultLoaded loaded;
  final void Function(String question) onAnswerByVoice;
  final VoidCallback onOpenTranscript;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.appTokens;
    final theme = Theme.of(context);
    final title = loaded.thesis.title?.trim();
    final displayTitle = (title == null || title.isEmpty)
        ? l10n.thesisUntitled
        : title;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          displayTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        if (loaded.applyTimedOut) ...[
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: t.surfaceContainer,
              borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXl),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.thesisApplyPending,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: t.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        ThesisFieldDiffSection(
          diff: loaded.fieldDiff,
          diffSummary: loaded.diffSummary,
        ),
        const SizedBox(height: AppSpacing.xl),
        ThesisUnbackedStakesCard(
          stakes: loaded.unbackedStakes,
          onAnswerByVoice: (_, question) => onAnswerByVoice(question),
        ),
        const SizedBox(height: AppSpacing.xl),
        ThesisNextConversationCard(script: loaded.nextConversation),
        const SizedBox(height: AppSpacing.xl),
        TextButton(
          onPressed: onOpenTranscript,
          child: Text(l10n.thesisSeeTranscript),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppGradientButton(
          onPressed: onDone,
          label: l10n.thesisResultDone,
          expand: true,
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    this.busy = false,
    this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final bool busy;
  final String? title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy) ...[
                  const CircularProgressIndicator(),
                  if (title != null) const SizedBox(height: AppSpacing.lg),
                ],
                if (title != null)
                  Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                if (body != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    body!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: t.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppGradientButton(
                    onPressed: onAction,
                    label: actionLabel!,
                    variant: AppButtonVariant.outlined,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
