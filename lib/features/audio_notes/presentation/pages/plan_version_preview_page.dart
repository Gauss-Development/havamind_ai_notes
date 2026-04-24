import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/obsidian_gradient_button.dart';
import 'package:sample/features/audio_notes/domain/entities/plan_version.dart';
import 'package:sample/features/audio_notes/presentation/bloc/plan_version_history_cubit.dart';

class PlanVersionPreviewPage extends StatelessWidget {
  const PlanVersionPreviewPage({super.key, required this.version});

  final PlanVersion version;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.obsidian;
    final dateFmt = DateFormat('MMM d, yyyy • h:mm a');
    final snapshot = version.planSnapshot;

    final sections = [
      _Section('STARTUP TITLE', snapshot['startup_title']),
      _Section('SUMMARY', snapshot['short_summary']),
      _Section('THE PROBLEM', snapshot['problem']),
      _Section('THE SOLUTION', snapshot['solution']),
      _Section('TARGET AUDIENCE', snapshot['target_audience']),
      _Section('BUSINESS MODEL', snapshot['business_model']),
      _Section('KEY METRICS', snapshot['key_metrics']),
      _Section('ADVANTAGES', snapshot['advantages']),
      _Section('RISKS & GAPS', snapshot['risks_gaps']),
    ];

    final marketScore =
        (snapshot['market_potential_score'] as num?)?.toInt() ?? 0;
    final techScore =
        (snapshot['technical_complexity_score'] as num?)?.toInt() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Round ${version.roundNumber}',
          style: theme.textTheme.titleMedium,
        ),
        centerTitle: true,
      ),
      body: BlocListener<PlanVersionHistoryCubit, PlanVersionHistoryState>(
        listener: (context, state) {
          if (state.restoredRound != null) {
            Navigator.of(context).pop(true);
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.base,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            // Header
            Text(
              dateFmt.format(version.createdAt.toLocal()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: t.onSurfaceVariant,
              ),
            ),
            if (version.diffSummary != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: t.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(ObsidianUiTokens.radiusMd),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.change_history_rounded,
                        size: 16, color: t.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        version.diffSummary!,
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

            // Scores
            if (marketScore > 0 || techScore > 0) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _ScoreChip(
                      label: 'Market',
                      value: marketScore,
                      color: t.primary,
                      tokens: t,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ScoreChip(
                      label: 'Complexity',
                      value: techScore,
                      color: t.secondary,
                      tokens: t,
                    ),
                  ),
                ],
              ),
            ],

            // Plan sections
            const SizedBox(height: AppSpacing.lg),
            for (final section in sections)
              if (section.value != null && section.value!.isNotEmpty) ...[
                _ReadOnlySection(
                  label: section.label,
                  value: section.value!,
                  tokens: t,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

            // Restore button
            const SizedBox(height: AppSpacing.xl),
            BlocBuilder<PlanVersionHistoryCubit,
                PlanVersionHistoryState>(
              builder: (context, state) {
                return ObsidianGradientButton(
                  onPressed: state.isRestoring
                      ? null
                      : () => _confirmRestore(context),
                  icon: Icons.restore_rounded,
                  label: state.isRestoring
                      ? 'Restoring...'
                      : 'Make this the current version',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restore version?', style: theme.textTheme.titleLarge),
        content: Text(
          'This will create a new version based on round ${version.roundNumber}. '
          'No history will be lost.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<PlanVersionHistoryCubit>().restore(version.id);
    }
  }
}

class _Section {
  const _Section(this.label, this.value);
  final String label;
  final String? value;
}

class _ReadOnlySection extends StatelessWidget {
  const _ReadOnlySection({
    required this.label,
    required this.value,
    required this.tokens,
  });

  final String label;
  final String value;
  final ObsidianUiTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: tokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
        border: Border.all(color: tokens.ghostBorder(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tokens.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: tokens.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.value,
    required this.color,
    required this.tokens,
  });

  final String label;
  final int value;
  final Color color;
  final ObsidianUiTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: tokens.surfaceContainer,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tokens.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                      ObsidianUiTokens.radiusFull),
                  child: LinearProgressIndicator(
                    value: value / 100,
                    minHeight: 6,
                    color: color,
                    backgroundColor: tokens.surfaceContainerLow,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$value%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
