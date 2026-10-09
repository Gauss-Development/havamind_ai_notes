import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sample/core/di/injection.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/obsidian_gradient_button.dart';
import 'package:sample/features/audio_notes/presentation/pages/note_detail_page.dart';
import 'package:sample/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:sample/features/tags/presentation/bloc/tags_cubit.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';
import 'package:sample/features/thesis/presentation/concept_result_entry.dart';
import 'package:sample/features/thesis/presentation/cubit/thesis_result_cubit.dart';
import 'package:sample/features/thesis/presentation/widgets/thesis_speech_section.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

/// Current concept speech, who already heard older versions, and the
/// confirmation required before a rewrite.
class ThesisPage extends StatelessWidget {
  const ThesisPage({
    super.key,
    required this.noteId,
    this.entry = ConceptResultEntry.view,
  });

  final String noteId;
  final ConceptResultEntry entry;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ThesisResultCubit>(param1: noteId, param2: entry)..start(),
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
              ThesisResultRewriting() => _StatusCard(
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
              ThesisResultAwaitingHearer waiting => _ConceptBody(
                thesis: waiting.thesis,
                versions: waiting.versions,
                noteId: waiting.note.id,
                footer: _HearerForm(waiting: waiting),
              ),
              ThesisResultLoaded loaded => _ConceptBody(
                thesis: loaded.thesis,
                versions: loaded.versions,
                rewriteNote: loaded.rewriteNote,
                noteId: loaded.note.id,
              ),
            };
          },
        ),
      ),
    );
  }
}

class _ConceptBody extends StatelessWidget {
  const _ConceptBody({
    required this.thesis,
    required this.versions,
    required this.noteId,
    this.rewriteNote,
    this.footer,
  });

  final Thesis thesis;
  final List<ThesisVersion> versions;
  final String noteId;
  final String? rewriteNote;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = thesis.title?.trim();
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ThesisSpeechSection(thesis: thesis, rewriteNote: rewriteNote),
        const SizedBox(height: AppSpacing.lg),
        ThesisHeardVersionsSection(versions: versions),
        if (footer != null) ...[const SizedBox(height: AppSpacing.lg), footer!],
        const SizedBox(height: AppSpacing.xl),
        TextButton(
          onPressed: () => _openTranscript(context, noteId),
          child: Text(l10n.thesisSeeTranscript),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppGradientButton(
          onPressed: () => Navigator.of(context).maybePop(),
          label: l10n.thesisResultDone,
          expand: true,
        ),
      ],
    );
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

class _HearerForm extends StatefulWidget {
  const _HearerForm({required this.waiting});

  final ThesisResultAwaitingHearer waiting;

  @override
  State<_HearerForm> createState() => _HearerFormState();
}

class _HearerFormState extends State<_HearerForm> {
  late final TextEditingController _label;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.waiting.suggestedHearer ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.appTokens;
    final theme = Theme.of(context);
    final cubit = context.read<ThesisResultCubit>();
    final confirmed = widget.waiting.canRewrite;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.thesisHearerPrompt,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _label,
              textInputAction: TextInputAction.done,
              maxLength: 120,
              decoration: InputDecoration(
                hintText: l10n.thesisHearerHint,
                counterText: '',
              ),
              onChanged: (_) {
                if (widget.waiting.confirmedLabel != null) {
                  cubit.clearHearerConfirmation();
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppGradientButton(
              onPressed: () => cubit.confirmHearer(_label.text),
              label: l10n.thesisConfirmHearer,
              variant: AppButtonVariant.outlined,
              expand: true,
            ),
            if (confirmed) ...[
              const SizedBox(height: AppSpacing.sm),
              AppGradientButton(
                onPressed: () => cubit.rewrite(),
                label: l10n.thesisRewriteSpeech,
                expand: true,
              ),
            ],
          ],
        ),
      ),
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
