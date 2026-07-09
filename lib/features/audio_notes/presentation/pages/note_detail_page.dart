import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sample/core/di/injection.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/app_bottom_sheet.dart';
import 'package:sample/core/widgets/obsidian_gradient_button.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_transcript.dart';
import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';
import 'package:sample/features/audio_notes/presentation/bloc/note_detail_bloc.dart';
import 'package:sample/features/audio_notes/presentation/utils/audio_note_status_ui.dart';
import 'package:sample/features/audio_notes/presentation/pages/plan_version_history_page.dart';
import 'package:sample/features/audio_notes/presentation/pages/refinement_recording_page.dart';
import 'package:sample/features/audio_notes/presentation/utils/note_share_formatter.dart';
import 'package:sample/features/audio_notes/presentation/utils/plan_export_formatter.dart';
import 'package:sample/features/audio_notes/presentation/widgets/plan_export_sheet.dart';
import 'package:sample/features/audio_notes/presentation/widgets/audio_note_duration_formatter.dart';
import 'package:sample/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:sample/features/tags/presentation/bloc/tags_cubit.dart';
import 'package:sample/features/tags/presentation/widgets/tag_chips.dart';
import 'package:sample/features/audio_notes/domain/utils/analysis_plan_gaps.dart';
import 'package:sample/features/audio_notes/presentation/widgets/note_detail/plan_gaps_card.dart';
import 'package:sample/features/audio_notes/presentation/widgets/plan_readiness_indicator.dart';
import 'package:sample/l10n/generated/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class NoteDetailPage extends StatelessWidget {
  const NoteDetailPage({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NoteDetailBloc>(param1: noteId),
      child: _NoteDetailView(noteId: noteId),
    );
  }
}

class _NoteDetailView extends StatelessWidget {
  const _NoteDetailView({required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NoteDetailBloc, NoteDetailState>(
      listener: (context, state) {
        state.maybeWhen(
          failure: (m) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(m)));
          },
          deleted: () {
            // Pop after this frame so we never paint `deleted` as an empty
            // scaffold while the bloc may still transition (e.g. watch race).
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              Navigator.of(context).maybePop(true);
            });
          },
          orElse: () {},
        );
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final l10n = AppLocalizations.of(context)!;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.note, style: theme.textTheme.titleMedium),
            centerTitle: true,
            actions: [
              FavoriteButton(noteId: noteId),
              state.maybeWhen(
                loaded: (note, transcript, analysis) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (analysis != null)
                      IconButton(
                        tooltip: l10n.versionHistory,
                        icon: const Icon(Icons.history_rounded),
                        onPressed: () =>
                            _openVersionHistory(context, note, analysis),
                      ),
                    _ShareMenuButton(
                      note: note,
                      transcript: transcript,
                      analysis: analysis,
                    ),
                    IconButton(
                      tooltip: l10n.deleteNote,
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          body: state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (note, transcript, analysis) => _LoadedBody(
              note: note,
              transcript: transcript,
              analysis: analysis,
            ),
            deleted: () => const Center(child: CircularProgressIndicator()),
            failure: (m) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(m, textAlign: TextAlign.center),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openVersionHistory(
    BuildContext context,
    AudioNote note,
    StartupAnalysis analysis,
  ) async {
    final restored = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            PlanVersionHistoryPage(planId: analysis.id, noteId: note.id),
      ),
    );
    if (restored == true && context.mounted) {
      context.read<NoteDetailBloc>().add(NoteDetailEvent.loadRequested(noteId));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteNote, style: theme.textTheme.titleLarge),
        content: Text(l10n.deleteNoteBody, style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<NoteDetailBloc>().add(
        const NoteDetailEvent.deleteRequested(),
      );
    }
  }
}

// ─── Loaded body ─────────────────────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.note, this.transcript, this.analysis});

  final AudioNote note;
  final AudioNoteTranscript? transcript;
  final StartupAnalysis? analysis;

  @override
  Widget build(BuildContext context) {
    if (note.status.isPendingPipeline) return _ProcessingView(note: note);
    if (note.status == AudioNoteStatus.failed) return _FailedView(note: note);

    return _CompletedView(
      note: note,
      transcript: transcript,
      analysis: analysis,
    );
  }
}

// ─── Processing view ─────────────────────────────────────────────────────────

class _ProcessingView extends StatelessWidget {
  const _ProcessingView({required this.note});

  final AudioNote note;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: t.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              note.status == AudioNoteStatus.uploaded
                  ? l10n.startingProcessing
                  : audioNoteStatusLabel(note.status),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.processingWait,
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
}

// ─── Failed view ─────────────────────────────────────────────────────────────

class _FailedView extends StatelessWidget {
  const _FailedView({required this.note});

  final AudioNote note;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.processingFailed, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.retryHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: t.onSurfaceVariant,
              ),
            ),
            if (note.lastProcessingError != null &&
                note.lastProcessingError!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.base),
              Text(
                note.lastProcessingError!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            ObsidianGradientButton(
              onPressed: () => context.read<NoteDetailBloc>().add(
                const NoteDetailEvent.retryProcessing(),
              ),
              icon: Icons.refresh_rounded,
              label: l10n.retryProcessing,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Completed view — tabbed ─────────────────────────────────────────────────

class _CompletedView extends StatelessWidget {
  const _CompletedView({required this.note, this.transcript, this.analysis});

  final AudioNote note;
  final AudioNoteTranscript? transcript;
  final StartupAnalysis? analysis;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: l10n.summary),
              Tab(text: l10n.analysis),
              Tab(text: l10n.transcript),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _SummaryTab(note: note, analysis: analysis),
                _AnalysisTab(
                  note: note,
                  analysis: analysis,
                  onAnswerByVoice: (index, question) async {
                    final refined = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => RefinementRecordingPage(
                          noteId: note.id,
                          followUpQuestionId: index.toString(),
                          followUpQuestionText: question,
                        ),
                      ),
                    );
                    if (refined == true && context.mounted) {
                      context.read<NoteDetailBloc>().add(
                        NoteDetailEvent.loadRequested(note.id),
                      );
                    }
                  },
                ),
                _TranscriptTab(transcript: transcript),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Summary ──────────────────────────────────────────────────────────

class _SummaryTab extends StatefulWidget {
  const _SummaryTab({required this.note, this.analysis});

  final AudioNote note;
  final StartupAnalysis? analysis;

  @override
  State<_SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<_SummaryTab> {
  // Hoisted out of `build` so the pattern-parsing cost is paid once per
  // class load rather than on every BLoC emit (including bursty realtime
  // updates during transcription/analysis).
  static final _dateFmt = DateFormat('MMM d, yyyy • h:mm a');

  Set<String> _selectedTagIds = {};

  @override
  void initState() {
    super.initState();
    _loadNoteTags();
  }

  Future<void> _loadNoteTags() async {
    final cubit = context.read<TagsCubit>();
    final ids = await cubit.getTagIdsForNote(widget.note.id);
    if (mounted) setState(() => _selectedTagIds = ids.toSet());
  }

  Future<void> _toggleTag(String tagId) async {
    final updated = Set<String>.from(_selectedTagIds);
    if (updated.contains(tagId)) {
      updated.remove(tagId);
    } else {
      updated.add(tagId);
    }
    setState(() => _selectedTagIds = updated);
    await context.read<TagsCubit>().setTagsForNote(
      widget.note.id,
      updated.toList(),
    );
  }

  Future<void> _addTag() async {
    final result = await showEditBottomSheet(
      context: context,
      title: 'New tag',
      hintText: 'Tag name',
      maxLines: 1,
      minLines: 1,
      saveLabel: 'Create',
    );
    if (result != null && mounted) {
      final cubit = context.read<TagsCubit>();
      await cubit.create(result);
      // Auto-select the newly created tag
      final newTag = cubit.state.tags
          .where((t) => t.name == result)
          .firstOrNull;
      if (newTag != null) {
        await _toggleTag(newTag.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = _dateFmt;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.base,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Row(
          children: [
            Text(
              dateFmt.format(widget.note.createdAt.toLocal()),
              style: theme.textTheme.bodySmall,
            ),
            if (widget.note.durationSeconds > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                '•  ${AudioNoteDurationFormatter.mmSs(widget.note.durationSeconds)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: t.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () => _editTitle(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.note.title,
                  style: theme.textTheme.headlineLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: t.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        BlocBuilder<TagsCubit, TagsState>(
          builder: (context, tagsState) {
            return TagChips(
              tags: tagsState.tags,
              selectedIds: _selectedTagIds,
              onToggle: _toggleTag,
              onAdd: _addTag,
            );
          },
        ),
        if (widget.analysis?.shortSummary != null) ...[
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: () => _editField(
              context,
              title: l10n.editSummary,
              value: widget.analysis!.shortSummary,
              field: StartupAnalysisEditableField.shortSummary,
            ),
            child: Text(
              widget.analysis!.shortSummary!,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.55,
                color: t.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (widget.analysis != null) ...[
          const SizedBox(height: AppSpacing.xl),
          PlanReadinessIndicator(
            readiness: computePlanReadiness(widget.analysis!),
          ),
          const SizedBox(height: AppSpacing.xl),
          _VentureIntelligence(
            marketPotential: widget.analysis!.marketPotentialScore ?? 0,
            technicalComplexity: widget.analysis!.technicalComplexityScore ?? 0,
          ),
          const SizedBox(height: AppSpacing.xl),
          Builder(
            builder: (context) {
              final gaps = findAnalysisPlanGaps(widget.analysis!);
              return Column(
                children: [
                  if (gaps.isNotEmpty) ...[
                    PlanGapsCard(
                      gaps: gaps,
                      onAnswerByVoice: (field, question) =>
                          _openRefinementRecording(
                            context,
                            followUpQuestionId: field.name,
                            followUpQuestionText: question,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.base),
                  ],
                ],
              );
            },
          ),
          ObsidianGradientButton(
            onPressed: () => _openRefinementRecording(context),
            icon: Icons.mic_rounded,
            label: l10n.continueRecording,
          ),
        ],
      ],
    );
  }

  Future<void> _openRefinementRecording(
    BuildContext context, {
    String? followUpQuestionId,
    String? followUpQuestionText,
  }) async {
    final refined = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RefinementRecordingPage(
          noteId: widget.note.id,
          followUpQuestionId: followUpQuestionId,
          followUpQuestionText: followUpQuestionText,
        ),
      ),
    );
    if (refined == true && context.mounted) {
      // Refresh the detail page to show updated plan
      context.read<NoteDetailBloc>().add(
        NoteDetailEvent.loadRequested(widget.note.id),
      );
    }
  }

  Future<void> _editTitle(BuildContext context) async {
    final result = await showEditBottomSheet(
      context: context,
      title: 'Rename note',
      initialValue: widget.note.title,
      hintText: 'Title',
      maxLines: 2,
      minLines: 1,
    );
    if (result != null && context.mounted) {
      context.read<NoteDetailBloc>().add(NoteDetailEvent.titleUpdated(result));
    }
  }

  Future<void> _editField(
    BuildContext context, {
    required String title,
    required String? value,
    required StartupAnalysisEditableField field,
  }) async {
    final result = await showEditBottomSheet(
      context: context,
      title: title,
      initialValue: value,
    );
    if (result != null && context.mounted) {
      context.read<NoteDetailBloc>().add(
        NoteDetailEvent.analysisFieldUpdated(field: field, value: result),
      );
    }
  }
}

// ─── Tab 2: Analysis ─────────────────────────────────────────────────────────

class _AnalysisTab extends StatelessWidget {
  const _AnalysisTab({required this.note, this.analysis, this.onAnswerByVoice});

  final AudioNote note;
  final StartupAnalysis? analysis;
  final void Function(int index, String question)? onAnswerByVoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.obsidian;
    final l10n = AppLocalizations.of(context)!;

    if (analysis == null) {
      return Center(
        child: Text(
          l10n.noAnalysisAvailable,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: t.onSurfaceVariant,
          ),
        ),
      );
    }

    final cards = [
      _AnalysisEntry(
        label: l10n.theProblem,
        value: analysis!.problem,
        icon: Icons.report_problem_outlined,
        field: StartupAnalysisEditableField.problem,
      ),
      _AnalysisEntry(
        label: l10n.theSolution,
        value: analysis!.solution,
        icon: Icons.auto_awesome_outlined,
        field: StartupAnalysisEditableField.solution,
      ),
      _AnalysisEntry(
        label: l10n.targetAudience,
        value: analysis!.targetAudience,
        icon: Icons.groups_2_outlined,
        field: StartupAnalysisEditableField.targetAudience,
      ),
      _AnalysisEntry(
        label: l10n.businessModel,
        value: analysis!.businessModel,
        icon: Icons.payments_outlined,
        field: StartupAnalysisEditableField.businessModel,
      ),
      _AnalysisEntry(
        label: l10n.keyMetrics,
        value: analysis!.keyMetrics,
        icon: Icons.analytics_outlined,
        field: StartupAnalysisEditableField.keyMetrics,
      ),
      _AnalysisEntry(
        label: l10n.advantages,
        value: analysis!.advantages,
        icon: Icons.star_outline_rounded,
        field: StartupAnalysisEditableField.advantages,
      ),
      _AnalysisEntry(
        label: l10n.risksAndGaps,
        value: analysis!.risksGaps,
        icon: Icons.warning_amber_rounded,
        field: StartupAnalysisEditableField.risksGaps,
      ),
    ];

    final hasFollowUp =
        analysis!.followUpQuestions != null &&
        analysis!.followUpQuestions!.isNotEmpty;

    // CustomScrollView + slivers so the analysis cards are virtualised
    // (only visible ones lay out) instead of being eagerly composed
    // every time the parent BLoC emits — important since realtime
    // updates rebuild this whole tree on each row UPDATE.
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.base,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverList.separated(
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _CollapsibleAnalysisCard(entry: cards[i]),
          ),
        ),
        if (hasFollowUp) ...[
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            sliver: SliverToBoxAdapter(
              child: _FollowUpQuestionsCard(
                questions: analysis!.followUpQuestions!,
                onAnswerByVoice: onAnswerByVoice,
              ),
            ),
          ),
        ] else
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
      ],
    );
  }
}

class _AnalysisEntry {
  const _AnalysisEntry({
    required this.label,
    required this.value,
    required this.icon,
    required this.field,
  });

  final String label;
  final String? value;
  final IconData icon;
  final StartupAnalysisEditableField field;
}

class _CollapsibleAnalysisCard extends StatefulWidget {
  const _CollapsibleAnalysisCard({required this.entry});

  final _AnalysisEntry entry;

  @override
  State<_CollapsibleAnalysisCard> createState() =>
      _CollapsibleAnalysisCardState();
}

class _CollapsibleAnalysisCardState extends State<_CollapsibleAnalysisCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasContent =
        widget.entry.value != null && widget.entry.value!.isNotEmpty;
    final preview = hasContent
        ? (widget.entry.value!.length > 80
              ? '${widget.entry.value!.substring(0, 80)}...'
              : widget.entry.value!)
        : l10n.noData;

    return Container(
      decoration: BoxDecoration(
        color: t.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
        border: Border.all(color: t.ghostBorder(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(
                children: [
                  Icon(widget.entry.icon, size: 18, color: t.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entry.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: t.primary,
                          ),
                        ),
                        if (!_expanded) ...[
                          const SizedBox(height: 2),
                          Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: t.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                0,
                AppSpacing.base,
                AppSpacing.base,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.entry.value ?? l10n.noData,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: t.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _edit(context),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(l10n.edit),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final result = await showEditBottomSheet(
      context: context,
      title: 'Edit: ${widget.entry.label.toLowerCase()}',
      initialValue: widget.entry.value,
    );
    if (result != null && context.mounted) {
      context.read<NoteDetailBloc>().add(
        NoteDetailEvent.analysisFieldUpdated(
          field: widget.entry.field,
          value: result,
        ),
      );
    }
  }
}

class _FollowUpQuestionsCard extends StatelessWidget {
  const _FollowUpQuestionsCard({required this.questions, this.onAnswerByVoice});

  final List<String> questions;
  final void Function(int index, String question)? onAnswerByVoice;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: t.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
        border: Border.all(color: t.ghostBorder(0.12)),
      ),
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, size: 18, color: t.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.followUpQuestions,
                style: theme.textTheme.labelSmall?.copyWith(color: t.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < questions.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: t.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    questions[i],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: t.onSurfaceVariant,
                    ),
                  ),
                ),
                if (onAnswerByVoice != null)
                  IconButton(
                    onPressed: () => onAnswerByVoice!(i, questions[i]),
                    icon: Icon(Icons.mic_rounded, size: 18, color: t.primary),
                    tooltip: l10n.answerByVoice,
                  ),
              ],
            ),
            if (i < questions.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

// ─── Tab 3: Transcript ───────────────────────────────────────────────────────

class _TranscriptTab extends StatelessWidget {
  const _TranscriptTab({this.transcript});

  final AudioNoteTranscript? transcript;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final text = transcript?.transcriptText.trim();

    if (text == null || text.isEmpty) {
      return Center(
        child: Text(
          l10n.transcriptNotAvailable,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: t.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.base,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Row(
          children: [
            Text(l10n.rawTranscription, style: theme.textTheme.titleMedium),
            const Spacer(),
            if (transcript?.language != null)
              Text(
                transcript!.language!.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: t.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        SelectableText(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.65,
            color: t.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _VentureIntelligence extends StatelessWidget {
  const _VentureIntelligence({
    required this.marketPotential,
    required this.technicalComplexity,
  });

  final int marketPotential;
  final int technicalComplexity;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: t.surfaceContainer,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.ventureIntelligence, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.base),
          _MetricProgress(
            label: l10n.marketPotential,
            value: marketPotential,
            accent: t.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          _MetricProgress(
            label: l10n.technicalComplexity,
            value: technicalComplexity,
            accent: t.secondary,
          ),
        ],
      ),
    );
  }
}

class _MetricProgress extends StatelessWidget {
  const _MetricProgress({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: t.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              '$value%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusFull),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 6,
            color: accent,
            backgroundColor: t.surfaceContainerLow,
          ),
        ),
      ],
    );
  }
}

// ─── Share menu ──────────────────────────────────────────────────────────────

class _ShareMenuButton extends StatelessWidget {
  const _ShareMenuButton({required this.note, this.transcript, this.analysis});

  final AudioNote note;
  final AudioNoteTranscript? transcript;
  final StartupAnalysis? analysis;

  String get _formatted => NoteShareFormatter.format(
    note: note,
    transcript: transcript,
    analysis: analysis,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canExportPlan =
        analysis != null && PlanExportFormatter.hasExportableContent(analysis!);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.ios_share_rounded),
      tooltip: l10n.share,
      onSelected: (value) async {
        switch (value) {
          case 'export_plan':
            if (analysis != null) {
              await showPlanExportSheet(context: context, analysis: analysis!);
            }
          case 'copy':
            await Clipboard.setData(ClipboardData(text: _formatted));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.copiedToClipboard)));
            }
          case 'share':
            await SharePlus.instance.share(ShareParams(text: _formatted));
        }
      },
      itemBuilder: (_) => [
        if (canExportPlan)
          PopupMenuItem(
            value: 'export_plan',
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.exportPlan),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        PopupMenuItem(
          value: 'copy',
          child: ListTile(
            leading: const Icon(Icons.copy_rounded),
            title: Text(l10n.copyToClipboard),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: ListTile(
            leading: const Icon(Icons.share_rounded),
            title: Text(l10n.share),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
