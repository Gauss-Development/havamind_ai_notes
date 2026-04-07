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
          success: (_) => Navigator.of(context).pop(true),
          orElse: () {},
        );
      },
      builder: (context, state) {
        final t = context.obsidian;
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
            ),
            title: Text('Voice Memo', style: theme.textTheme.titleMedium),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                Text(
                  AudioNoteDurationFormatter.mmSs(elapsed),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isRecording ? 'RECORDING' : 'READY TO CAPTURE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isRecording
                        ? t.primary
                        : t.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxxl,
                  ),
                  child: RecordingWaveformSketch(
                    color: t.primary,
                    isAnimating: isRecording,
                  ),
                ),
                const Spacer(flex: 2),
                _RecordingControls(
                  state: state,
                  isRecording: isRecording,
                  tokens: t,
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  'Max ${kMaxRecordingDurationSeconds ~/ 60} minutes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: t.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecordingControls extends StatelessWidget {
  const _RecordingControls({
    required this.state,
    required this.isRecording,
    required this.tokens,
  });

  final RecordingState state;
  final bool isRecording;
  final ObsidianUiTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        RecordingMicActionButton(
          color: tokens.primary,
          iconColor: Colors.white,
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
        const SizedBox(height: AppSpacing.xl),
        state.maybeWhen(
          readyToSave: (path, duration) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
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
          ),
          uploading: () => Column(
            children: [
              CircularProgressIndicator(color: tokens.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Transcribing & analyzing...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.onSurfaceVariant,
                ),
              ),
            ],
          ),
          failure: (message) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        if (isRecording) ...[
          const SizedBox(height: AppSpacing.base),
          TextButton.icon(
            onPressed: () => context.read<RecordingBloc>().add(
              const RecordingEvent.cancelPressed(),
            ),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Cancel recording'),
          ),
        ],
      ],
    );
  }
}
