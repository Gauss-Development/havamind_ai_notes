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
import 'package:sample/features/audio_notes/presentation/bloc/audio_player_cubit.dart';
import 'package:sample/features/audio_notes/presentation/bloc/note_detail_bloc.dart';
import 'package:sample/features/audio_notes/presentation/utils/audio_note_status_ui.dart';
import 'package:sample/features/audio_notes/presentation/pages/refinement_recording_page.dart';
import 'package:sample/features/audio_notes/presentation/utils/note_share_formatter.dart';
import 'package:sample/features/audio_notes/presentation/widgets/audio_note_duration_formatter.dart';
import 'package:sample/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:sample/features/tags/presentation/bloc/tags_cubit.dart';
import 'package:sample/features/tags/presentation/widgets/tag_chips.dart';
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(m)),
            );
          },
          deleted: () => Navigator.of(context).pop(true),
          orElse: () {},
        );
      },
      builder: (context, state) {
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text('Note', style: theme.textTheme.titleMedium),
            centerTitle: true,
            actions: [
              FavoriteButton(noteId: noteId),
              state.maybeWhen(
                loaded: (note, transcript, analysis, localAudioExists) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ShareMenuButton(
                      note: note,
                      transcript: transcript,
                      analysis: analysis,
                    ),
                    if (localAudioExists)
                      IconButton(
                        tooltip: 'Delete local audio file',
                        icon: const Icon(Icons.delete_sweep_outlined),
                        onPressed: () => _confirmDeleteLocalAudio(context),
                      ),
                    IconButton(
                      tooltip: 'Delete note',
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
            loaded: (note, transcript, analysis, localAudioExists) =>
                _LoadedBody(
              note: note,
              transcript: transcript,
              analysis: analysis,
              localAudioExists: localAudioExists,
            ),
            deleted: () => const SizedBox.shrink(),
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

  Future<void> _confirmDelete(BuildContext context) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete note?', style: theme.textTheme.titleLarge),
        content: Text(
          'The file and record will be permanently deleted.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
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

  Future<void> _confirmDeleteLocalAudio(BuildContext context) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text('Delete local file?', style: theme.textTheme.titleLarge),
        content: Text(
          'The audio will be removed from this device. '
          'The analysis will remain.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete file'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<NoteDetailBloc>().add(
        const NoteDetailEvent.deleteLocalAudioRequested(),
      );
    }
  }
}

// ─── Loaded body ─────────────────────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.note,
    this.transcript,
    this.analysis,
    required this.localAudioExists,
  });

  final AudioNote note;
  final AudioNoteTranscript? transcript;
  final StartupAnalysis? analysis;
  final bool localAudioExists;

  @override
  Widget build(BuildContext context) {
    if (note.status.isPendingPipeline) return _ProcessingView(note: note);
    if (note.status == AudioNoteStatus.failed) return _FailedView(note: note);

    return _CompletedView(
      note: note,
      transcript: transcript,
      analysis: analysis,
      localAudioExists: localAudioExists,
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
                  ? 'Starting processing...'
                  : audioNoteStatusLabel(note.status),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'This may take a couple of minutes.\n'
              'The page will refresh automatically.',
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
            Text('Processing failed', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try again — this might be a temporary issue.',
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
              label: 'Retry processing',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Completed view — tabbed ─────────────────────────────────────────────────

class _CompletedView extends StatelessWidget {
  const _CompletedView({
    required this.note,
    this.transcript,
    this.analysis,
    required this.localAudioExists,
  });

  final AudioNote note;
  final AudioNoteTranscript? transcript;
  final StartupAnalysis? analysis;
  final bool localAudioExists;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = AudioPlayerCubit();
        if (localAudioExists) {
          cubit.loadAudio(note.audioPath);
        }
        return cubit;
      },
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Summary'),
                Tab(text: 'Analysis'),
                Tab(text: 'Transcript'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _SummaryTab(
                    note: note,
                    analysis: analysis,
                    localAudioExists: localAudioExists,
                  ),
                  _AnalysisTab(
                    note: note,
                    analysis: analysis,
                    onAnswerByVoice: (index, question) async {
                      final refined =
                          await Navigator.of(context).push<bool>(
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
      ),
    );
  }
}

// ─── Tab 1: Summary ──────────────────────────────────────────────────────────

class _SummaryTab extends StatefulWidget {
  const _SummaryTab({
    required this.note,
    this.analysis,
    required this.localAudioExists,
  });

  final AudioNote note;
  final StartupAnalysis? analysis;
  final bool localAudioExists;

  @override
  State<_SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<_SummaryTab> {
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
      final newTag = cubit.state.tags.where((t) => t.name == result).firstOrNull;
      if (newTag != null) {
        await _toggleTag(newTag.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d, yyyy • h:mm a');

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.base,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          dateFmt.format(widget.note.createdAt.toLocal()),
          style: theme.textTheme.bodySmall,
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
        const SizedBox(height: AppSpacing.base),
        _AudioPlayerCard(
          duration: widget.note.durationSeconds,
          localAudioExists: widget.localAudioExists,
        ),
        if (widget.localAudioExists) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Local audio file saved on device',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (widget.analysis?.shortSummary != null) ...[
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: () => _editField(
              context,
              title: 'Edit summary',
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
          _VentureIntelligence(
            marketPotential: widget.analysis!.marketPotentialScore ?? 0,
            technicalComplexity: widget.analysis!.technicalComplexityScore ?? 0,
          ),
          const SizedBox(height: AppSpacing.xl),
          ObsidianGradientButton(
            onPressed: () => _openRefinementRecording(context),
            icon: Icons.mic_rounded,
            label: 'Continue recording',
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
      context.read<NoteDetailBloc>().add(
        NoteDetailEvent.titleUpdated(result),
      );
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
  const _AnalysisTab({
    required this.note,
    this.analysis,
    this.onAnswerByVoice,
  });

  final AudioNote note;
  final StartupAnalysis? analysis;
  final void Function(int index, String question)? onAnswerByVoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.obsidian;

    if (analysis == null) {
      return Center(
        child: Text(
          'No analysis available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: t.onSurfaceVariant,
          ),
        ),
      );
    }

    final cards = [
      _AnalysisEntry(
        label: 'THE PROBLEM',
        value: analysis!.problem,
        icon: Icons.report_problem_outlined,
        field: StartupAnalysisEditableField.problem,
      ),
      _AnalysisEntry(
        label: 'THE SOLUTION',
        value: analysis!.solution,
        icon: Icons.auto_awesome_outlined,
        field: StartupAnalysisEditableField.solution,
      ),
      _AnalysisEntry(
        label: 'TARGET AUDIENCE',
        value: analysis!.targetAudience,
        icon: Icons.groups_2_outlined,
        field: StartupAnalysisEditableField.targetAudience,
      ),
      _AnalysisEntry(
        label: 'BUSINESS MODEL',
        value: analysis!.businessModel,
        icon: Icons.payments_outlined,
        field: StartupAnalysisEditableField.businessModel,
      ),
      _AnalysisEntry(
        label: 'KEY METRICS',
        value: analysis!.keyMetrics,
        icon: Icons.analytics_outlined,
        field: StartupAnalysisEditableField.keyMetrics,
      ),
      _AnalysisEntry(
        label: 'ADVANTAGES',
        value: analysis!.advantages,
        icon: Icons.star_outline_rounded,
        field: StartupAnalysisEditableField.advantages,
      ),
      _AnalysisEntry(
        label: 'RISKS & GAPS',
        value: analysis!.risksGaps,
        icon: Icons.warning_amber_rounded,
        field: StartupAnalysisEditableField.risksGaps,
      ),
    ];

    final hasFollowUp = analysis!.followUpQuestions != null &&
        analysis!.followUpQuestions!.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.base,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          _CollapsibleAnalysisCard(entry: cards[i]),
          if (i < cards.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
        if (hasFollowUp) ...[
          const SizedBox(height: AppSpacing.lg),
          _FollowUpQuestionsCard(
            questions: analysis!.followUpQuestions!,
            onAnswerByVoice: onAnswerByVoice,
          ),
        ],
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
    final hasContent =
        widget.entry.value != null && widget.entry.value!.isNotEmpty;
    final preview = hasContent
        ? (widget.entry.value!.length > 80
            ? '${widget.entry.value!.substring(0, 80)}...'
            : widget.entry.value!)
        : 'No data';

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
                  Icon(
                    widget.entry.icon,
                    size: 18,
                    color: t.primary,
                  ),
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
                    widget.entry.value ?? 'No data available',
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
                      label: const Text('Edit'),
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
  const _FollowUpQuestionsCard({
    required this.questions,
    this.onAnswerByVoice,
  });

  final List<String> questions;
  final void Function(int index, String question)? onAnswerByVoice;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

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
                'FOLLOW-UP QUESTIONS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: t.primary,
                ),
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
                    icon: Icon(
                      Icons.mic_rounded,
                      size: 18,
                      color: t.primary,
                    ),
                    tooltip: 'Answer by voice',
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            if (i < questions.length - 1)
              const SizedBox(height: AppSpacing.sm),
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
    final text = transcript?.transcriptText.trim();

    if (text == null || text.isEmpty) {
      return Center(
        child: Text(
          'Transcript not available yet',
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
            Text('Raw Transcription', style: theme.textTheme.titleMedium),
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

class _AudioPlayerCard extends StatelessWidget {
  const _AudioPlayerCard({
    required this.duration,
    required this.localAudioExists,
  });

  final int duration;
  final bool localAudioExists;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    if (!localAudioExists) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: t.surfaceContainerLow,
          borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: t.onSurfaceVariant.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audio file not available',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: t.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AudioNoteDurationFormatter.mmSs(duration),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      builder: (context, playerState) {
        final isPlaying = playerState.isPlaying;
        final isLoading = playerState.status == AudioPlayerStatus.loading;
        final hasError = playerState.status == AudioPlayerStatus.error;
        final canInteract =
            playerState.status != AudioPlayerStatus.initial &&
            !isLoading &&
            !hasError;

        final position = playerState.position;
        final totalDuration = playerState.duration.inMilliseconds > 0
            ? playerState.duration
            : Duration(seconds: duration);
        final maxMs = totalDuration.inMilliseconds.toDouble();

        return Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: t.surfaceContainerLow,
            borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: canInteract
                    ? () => context.read<AudioPlayerCubit>().togglePlayPause()
                    : null,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasError
                        ? t.onSurfaceVariant.withValues(alpha: 0.3)
                        : t.primary,
                    shape: BoxShape.circle,
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: hasError
                    ? Text(
                        playerState.errorMessage ?? 'Playback error',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              activeTrackColor: t.primary,
                              inactiveTrackColor:
                                  t.primary.withValues(alpha: 0.2),
                              thumbColor: t.primary,
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                            ),
                            child: Slider(
                              value: position.inMilliseconds
                                  .toDouble()
                                  .clamp(0, maxMs),
                              max: maxMs > 0 ? maxMs : 1,
                              onChanged: canInteract
                                  ? (value) {
                                      context
                                          .read<AudioPlayerCubit>()
                                          .seek(
                                            Duration(
                                              milliseconds: value.toInt(),
                                            ),
                                          );
                                    }
                                  : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  _formatDuration(totalDuration),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

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
          Text('Venture Intelligence', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.base),
          _MetricProgress(
            label: 'Market Potential',
            value: marketPotential,
            accent: t.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          _MetricProgress(
            label: 'Technical Complexity',
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
  const _ShareMenuButton({
    required this.note,
    this.transcript,
    this.analysis,
  });

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
    return PopupMenuButton<String>(
      icon: const Icon(Icons.ios_share_rounded),
      tooltip: 'Share',
      onSelected: (value) async {
        switch (value) {
          case 'copy':
            await Clipboard.setData(ClipboardData(text: _formatted));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            }
          case 'share':
            await SharePlus.instance.share(ShareParams(text: _formatted));
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'copy',
          child: ListTile(
            leading: Icon(Icons.copy_rounded),
            title: Text('Copy to clipboard'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: ListTile(
            leading: Icon(Icons.share_rounded),
            title: Text('Share'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
