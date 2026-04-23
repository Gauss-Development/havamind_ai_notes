import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample/core/constants/audio_notes_constants.dart';
import 'package:sample/core/di/injection.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/audio_notes/presentation/bloc/plan_refinement_cubit.dart';
import 'package:sample/features/audio_notes/presentation/widgets/audio_note_duration_formatter.dart';
import 'package:sample/features/audio_notes/presentation/widgets/recording/recording_mic_action_button.dart';
import 'package:sample/features/audio_notes/presentation/widgets/recording/recording_waveform_sketch.dart';

/// Recording page for plan refinement — either free-form "continue recording"
/// or targeted follow-up question response.
///
/// Returns `true` via [Navigator.pop] when refinement succeeds.
class RefinementRecordingPage extends StatelessWidget {
  const RefinementRecordingPage({
    super.key,
    required this.noteId,
    this.followUpQuestionId,
    this.followUpQuestionText,
  });

  final String noteId;
  final String? followUpQuestionId;
  final String? followUpQuestionText;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PlanRefinementCubit>()
        ..configure(
          noteId: noteId,
          followUpQuestionId: followUpQuestionId,
          followUpQuestionText: followUpQuestionText,
        ),
      child: _RefinementRecordingView(
        followUpQuestionText: followUpQuestionText,
      ),
    );
  }
}

class _RefinementRecordingView extends StatelessWidget {
  const _RefinementRecordingView({this.followUpQuestionText});

  final String? followUpQuestionText;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlanRefinementCubit, PlanRefinementState>(
      listener: (context, state) {
        if (state.status == PlanRefinementStatus.failure &&
            state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
        if (state.status == PlanRefinementStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final t = context.appTokens;
        final theme = Theme.of(context);

        final isRecording =
            state.status == PlanRefinementStatus.recording;
        final elapsed = state.elapsedSeconds;

        return Scaffold(
          backgroundColor: t.surface,
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(false),
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Close',
            ),
            title: Text(
              followUpQuestionText != null
                  ? 'Answer Question'
                  : 'Refine Plan',
              style: theme.textTheme.titleMedium,
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  // Question context banner
                  if (followUpQuestionText != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.md,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.base),
                      decoration: BoxDecoration(
                        color: t.primaryContainer,
                        borderRadius: BorderRadius.circular(
                            ObsidianUiTokens.radiusMd),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            size: 18,
                            color: t.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              followUpQuestionText!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: t.primary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Hero block: timer + waveform + mic button
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AudioNoteDurationFormatter.mmSs(elapsed),
                            textAlign: TextAlign.center,
                            style:
                                theme.textTheme.displayLarge?.copyWith(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _statusLabel(state.status),
                            textAlign: TextAlign.center,
                            style:
                                theme.textTheme.labelSmall?.copyWith(
                              color: isRecording
                                  ? t.primary
                                  : t.onSurfaceVariant
                                      .withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          RecordingWaveformSketch(
                            color: t.primary,
                            isAnimating: isRecording,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          RecordingMicActionButton(
                            color: t.primary,
                            iconColor: t.onPrimaryButton,
                            icon: isRecording
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            onPressed: () {
                              if (!_canInteract(state.status)) return;
                              final cubit =
                                  context.read<PlanRefinementCubit>();
                              if (isRecording) {
                                cubit.stopRecording();
                              } else {
                                cubit.startRecording();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer controls
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: _FooterControls(
                      state: state,
                      isRecording: isRecording,
                      tokens: t,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Max ${kMaxRecordingDurationSeconds ~/ 60} minutes',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: t.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _canInteract(PlanRefinementStatus status) {
    return status == PlanRefinementStatus.idle ||
        status == PlanRefinementStatus.recording ||
        status == PlanRefinementStatus.failure;
  }

  String _statusLabel(PlanRefinementStatus status) {
    return switch (status) {
      PlanRefinementStatus.idle => 'READY TO CAPTURE',
      PlanRefinementStatus.recording => 'RECORDING',
      PlanRefinementStatus.readyToSave => 'REVIEW RECORDING',
      PlanRefinementStatus.uploading => 'UPLOADING...',
      PlanRefinementStatus.refining => 'REFINING YOUR PLAN...',
      PlanRefinementStatus.success => 'DONE',
      PlanRefinementStatus.failure => 'READY TO CAPTURE',
    };
  }
}

class _FooterControls extends StatelessWidget {
  const _FooterControls({
    required this.state,
    required this.isRecording,
    required this.tokens,
  });

  final PlanRefinementState state;
  final bool isRecording;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<PlanRefinementCubit>();

    switch (state.status) {
      case PlanRefinementStatus.readyToSave:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: cubit.cancelRecording,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton(
                onPressed: cubit.submitRecording,
                child: const Text('Refine'),
              ),
            ),
          ],
        );
      case PlanRefinementStatus.uploading:
      case PlanRefinementStatus.refining:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: tokens.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              state.status == PlanRefinementStatus.refining
                  ? 'Refining your plan...'
                  : 'Uploading...',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.onSurfaceVariant,
              ),
            ),
          ],
        );
      case PlanRefinementStatus.recording:
        return TextButton.icon(
          onPressed: cubit.cancelRecording,
          icon: const Icon(Icons.close_rounded),
          label: const Text('Cancel recording'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
