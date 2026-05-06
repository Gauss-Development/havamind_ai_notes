import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample/core/constants/audio_notes_constants.dart';
import 'package:sample/core/di/injection.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/audio_notes/presentation/bloc/recording_bloc.dart';
import 'package:sample/features/audio_notes/presentation/widgets/audio_note_duration_formatter.dart';
import 'package:sample/features/audio_notes/presentation/widgets/recording/recording_mic_action_button.dart';
import 'package:sample/features/audio_notes/presentation/widgets/recording/recording_waveform_sketch.dart';
import 'package:sample/features/subscription/presentation/widgets/paywall_sheet.dart';

class RecordingPage extends StatelessWidget {
  const RecordingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RecordingBloc>(),
      child: const _RecordingView(),
    );
  }
}

class _RecordingView extends StatelessWidget {
  const _RecordingView();

  @override
  Widget build(BuildContext context) {
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

        return Scaffold(
          backgroundColor: t.surface,
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(false),
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Close',
            ),
            title: Text('Voice Memo', style: theme.textTheme.titleMedium),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
              ),
              child: Column(
                children: [
                  // Hero block: timer + status + waveform + mic button.
                  // Vertically centered in the available space so the
                  // visual focus stays in the middle of the screen across
                  // all states.
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            AudioNoteDurationFormatter.mmSs(elapsed),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            isRecording ? 'RECORDING' : 'READY TO CAPTURE',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isRecording
                                  ? t.primary
                                  : t.onSurfaceVariant.withValues(alpha: 0.75),
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
                        ],
                      ),
                    ),
                  ),

                  // Footer block: state-dependent controls (cancel/save,
                  // uploading spinner, error, cancel-while-recording) and
                  // the max-duration hint. AnimatedSize keeps transitions
                  // smooth so the hero block above doesn't jump when
                  // controls appear/disappear.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: _RecordingFooterControls(
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
}

class _RecordingFooterControls extends StatelessWidget {
  const _RecordingFooterControls({
    required this.state,
    required this.isRecording,
    required this.tokens,
  });

  final RecordingState state;
  final bool isRecording;
  final AppTokens tokens;

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
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FilledButton(
              onPressed: () => context.read<RecordingBloc>().add(
                    const RecordingEvent.savePressed(),
                  ),
              child: const Text('Save'),
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
            'Transcribing & analyzing...',
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
          label: const Text('Cancel recording'),
        );
      },
    );
  }
}
