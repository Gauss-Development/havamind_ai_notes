import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample/core/constants/audio_notes_constants.dart';
import 'package:sample/core/di/injection.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';
import 'package:sample/features/audio_notes/presentation/bloc/recording_bloc.dart';
import 'package:sample/features/audio_notes/presentation/widgets/audio_note_duration_formatter.dart';
import 'package:sample/features/audio_notes/presentation/widgets/recording/recording_founder_prompts_card.dart';
import 'package:sample/features/audio_notes/presentation/widgets/recording/recording_mic_action_button.dart';
import 'package:sample/features/audio_notes/presentation/widgets/recording/recording_waveform_sketch.dart';
import 'package:sample/features/subscription/presentation/widgets/paywall_sheet.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

class RecordingPage extends StatelessWidget {
  const RecordingPage({super.key, this.initialTemplateId});

  final String? initialTemplateId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecordingBloc(
        recordingService: getIt(),
        processLocalAudioNote: getIt(),
        getCurrentUsage: getIt(),
        initialTemplateId: initialTemplateId,
      ),
      child: const _RecordingView(),
    );
  }
}

class _RecordingView extends StatelessWidget {
  const _RecordingView();

  RecordingMicScale _micScaleForHeight(double height) {
    if (height < 560) return RecordingMicScale.small;
    if (height < 680) return RecordingMicScale.compact;
    return RecordingMicScale.normal;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<RecordingBloc, RecordingState>(
      listener: (context, state) {
        state.maybeWhen(
          failure: (m) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(m)));
          },
          limitReached: () {
            showPaywallSheet(context, limitReached: true);
          },
          success: (_) => Navigator.of(context).pop(true),
          orElse: () {},
        );
      },
      builder: (context, state) {
        final t = context.appTokens;
        final theme = Theme.of(context);

        final elapsed = state.maybeWhen(
          recording: (seconds, _, _) => seconds,
          readyToSave: (_, duration) => duration,
          orElse: () => 0,
        );
        final isRecording = state.maybeWhen(
          recording: (_, _, _) => true,
          orElse: () => false,
        );
        final isPaused = state.maybeWhen(
          recording: (_, _, paused) => paused,
          orElse: () => false,
        );
        final isActivelyRecording = isRecording && !isPaused;
        final templateId = state.maybeWhen(
          idle: (id) => id,
          orElse: () => RecordingTemplateIds.founderPitch,
        );

        return Scaffold(
          backgroundColor: t.surface,
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(false),
              icon: const Icon(Icons.close_rounded),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            ),
            title: Text(l10n.voiceMemo, style: theme.textTheme.titleMedium),
            centerTitle: true,
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 680;
                final micScale = _micScaleForHeight(constraints.maxHeight);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: compact ? AppSpacing.sm : AppSpacing.lg,
                              ),
                              Text(
                                AudioNoteDurationFormatter.mmSs(elapsed),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontSize: compact ? 40 : 52,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: compact ? -0.8 : -1.2,
                                ),
                              ),
                              SizedBox(
                                height: compact ? AppSpacing.xs : AppSpacing.sm,
                              ),
                              Text(
                                !isRecording
                                    ? l10n.readyToCapture
                                    : isPaused
                                    ? l10n.paused
                                    : l10n.recording,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isActivelyRecording
                                      ? t.primary
                                      : t.onSurfaceVariant.withValues(
                                          alpha: 0.75,
                                        ),
                                ),
                              ),
                              SizedBox(
                                height: compact ? AppSpacing.lg : AppSpacing.xl,
                              ),
                              RecordingWaveformSketch(
                                color: t.primary,
                                isAnimating: isActivelyRecording,
                              ),
                              SizedBox(
                                height: compact ? AppSpacing.lg : AppSpacing.xl,
                              ),
                              if (!isRecording)
                                RecordingFounderPromptsCard(
                                  templateId: templateId,
                                  isRecording: false,
                                  elapsedSeconds: 0,
                                  compactLayout: compact,
                                )
                              else
                                RecordingFounderPromptsCard(
                                  templateId: templateId,
                                  isRecording: true,
                                  elapsedSeconds: elapsed,
                                  compactLayout: compact,
                                  overlayLayout: false,
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (state.maybeWhen(
                        idle: (_) => true,
                        recording: (_, _, _) => true,
                        orElse: () => false,
                      )) ...[
                        const SizedBox(height: AppSpacing.md),
                        Center(
                          child: RecordingMicActionButton(
                            color: t.primary,
                            iconColor: t.onPrimaryButton,
                            icon: !isRecording
                                ? Icons.mic_rounded
                                : isPaused
                                ? Icons.mic_rounded
                                : Icons.pause_rounded,
                            semanticLabel: !isRecording
                                ? l10n.record
                                : isPaused
                                ? l10n.resumeRecording
                                : l10n.pauseRecording,
                            scale: micScale,
                            onPressed: () {
                              final bloc = context.read<RecordingBloc>();
                              if (!isRecording) {
                                bloc.add(const RecordingEvent.startPressed());
                              } else if (isPaused) {
                                bloc.add(const RecordingEvent.resumePressed());
                              } else {
                                bloc.add(const RecordingEvent.pausePressed());
                              }
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        alignment: Alignment.topCenter,
                        child: _RecordingFooterControls(
                          state: state,
                          tokens: t,
                          l10n: l10n,
                        ),
                      ),
                      Text(
                        l10n.maxMinutes(kMaxRecordingDurationSeconds ~/ 60),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: t.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _RecordingFooterControls extends StatelessWidget {
  const _RecordingFooterControls({
    required this.state,
    required this.tokens,
    required this.l10n,
  });

  final RecordingState state;
  final AppTokens tokens;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return state.maybeWhen(
      recording: (_, _, _) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.read<RecordingBloc>().add(
                  const RecordingEvent.cancelPressed(),
                ),
                child: Text(l10n.cancel),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.read<RecordingBloc>().add(
                  const RecordingEvent.stopPressed(),
                ),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: Text(l10n.finishRecording),
              ),
            ),
          ],
        ),
      ),
      readyToSave: (path, duration) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.read<RecordingBloc>().add(
                  const RecordingEvent.cancelPressed(),
                ),
                child: Text(l10n.cancel),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton(
                onPressed: () => context.read<RecordingBloc>().add(
                  const RecordingEvent.savePressed(),
                ),
                child: Text(l10n.submitForAnalysis),
              ),
            ),
          ],
        ),
      ),
      uploading: () => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: tokens.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.transcribingAndAnalyzing,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      failure: (message) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
