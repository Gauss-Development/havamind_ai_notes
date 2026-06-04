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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<RecordingBloc, RecordingState>(
      listener: (context, state) {
        state.maybeWhen(
          failure: (m) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(m)),
            );
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
          recording: (seconds, _) => seconds,
          readyToSave: (_, duration) => duration,
          orElse: () => 0,
        );
        final isRecording = state.maybeWhen(
          recording: (_, _) => true,
          orElse: () => false,
        );
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxHeight < 640;
                        final tipsMaxHeight =
                            constraints.maxHeight * (compact ? 0.38 : 0.42);

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            _RecordingHero(
                              elapsed: elapsed,
                              isRecording: isRecording,
                              compact: compact,
                              tokens: t,
                              theme: theme,
                              l10n: l10n,
                            ),
                            if (isRecording)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: tipsMaxHeight,
                                  ),
                                  child: SingleChildScrollView(
                                    physics: const ClampingScrollPhysics(),
                                    child: RecordingFounderPromptsCard(
                                      templateId: templateId,
                                      isRecording: true,
                                      elapsedSeconds: elapsed,
                                      compactLayout: compact,
                                      overlayLayout: true,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: _RecordingFooterControls(
                      state: state,
                      isRecording: isRecording,
                      tokens: t,
                      l10n: l10n,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.maxMinutes(kMaxRecordingDurationSeconds ~/ 60),
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
}

class _RecordingHero extends StatelessWidget {
  const _RecordingHero({
    required this.elapsed,
    required this.isRecording,
    required this.compact,
    required this.tokens,
    required this.theme,
    required this.l10n,
  });

  final int elapsed;
  final bool isRecording;
  final bool compact;
  final AppTokens tokens;
  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AudioNoteDurationFormatter.mmSs(elapsed),
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: compact ? 44 : 56,
            fontWeight: FontWeight.w800,
            letterSpacing: compact ? -1.0 : -1.4,
          ),
        ),
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
        Text(
          isRecording ? l10n.recording : l10n.readyToCapture,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isRecording
                ? tokens.primary
                : tokens.onSurfaceVariant.withValues(alpha: 0.75),
          ),
        ),
        SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xxl),
        RecordingWaveformSketch(
          color: tokens.primary,
          isAnimating: isRecording,
        ),
        SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xxl),
        Transform.scale(
          scale: compact ? 0.88 : 1.0,
          child: RecordingMicActionButton(
            color: tokens.primary,
            iconColor: tokens.onPrimaryButton,
            icon: isRecording ? Icons.stop_rounded : Icons.mic_rounded,
            onPressed: () {
              if (isRecording) {
                context.read<RecordingBloc>().add(
                      const RecordingEvent.stopPressed(),
                    );
              } else {
                context.read<RecordingBloc>().add(
                      const RecordingEvent.startPressed(),
                    );
              }
            },
          ),
        ),
      ],
    );
  }
}

class _RecordingFooterControls extends StatelessWidget {
  const _RecordingFooterControls({
    required this.state,
    required this.isRecording,
    required this.tokens,
    required this.l10n,
  });

  final RecordingState state;
  final bool isRecording;
  final AppTokens tokens;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return state.maybeWhen(
      readyToSave: (path, duration) => Row(
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
              child: Text(l10n.save),
            ),
          ),
        ],
      ),
      uploading: () => Column(
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
      failure: (message) => Text(
        message,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      orElse: () {
        if (!isRecording) return const SizedBox.shrink();
        return TextButton.icon(
          onPressed: () => context.read<RecordingBloc>().add(
                const RecordingEvent.cancelPressed(),
              ),
          icon: const Icon(Icons.close_rounded),
          label: Text(l10n.cancelRecording),
        );
      },
    );
  }
}
