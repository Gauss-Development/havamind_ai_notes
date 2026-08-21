import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/obsidian_gradient_button.dart';
import 'package:sample/features/audio_notes/domain/entities/plan_version.dart';
import 'package:sample/features/audio_notes/domain/utils/plan_snapshot_diff.dart';
import 'package:sample/features/audio_notes/presentation/bloc/plan_version_history_cubit.dart';
import 'package:sample/features/audio_notes/presentation/utils/plan_snapshot_field_labels.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

class PlanVersionPreviewPage extends StatelessWidget {
  const PlanVersionPreviewPage({
    super.key,
    required this.version,
    this.previousVersion,
  });

  final PlanVersion version;
  final PlanVersion? previousVersion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final t = context.obsidian;
    final dateFmt = DateFormat('MMM d, yyyy • h:mm a');
    final snapshot = version.planSnapshot;

    final sections = [
      _Section(l10n.planFieldStartupTitle, snapshot['startup_title']),
      _Section(l10n.planFieldSummary, snapshot['short_summary']),
      _Section(l10n.theProblem, snapshot['problem']),
      _Section(l10n.theSolution, snapshot['solution']),
      _Section(l10n.targetAudience, snapshot['target_audience']),
      _Section(l10n.businessModel, snapshot['business_model']),
      _Section(l10n.keyMetrics, snapshot['key_metrics']),
      _Section(l10n.advantages, snapshot['advantages']),
      _Section(l10n.risksAndGaps, snapshot['risks_gaps']),
    ];

    final marketScore =
        (snapshot['market_potential_score'] as num?)?.toInt() ?? 0;
    final techScore =
        (snapshot['technical_complexity_score'] as num?)?.toInt() ?? 0;

    final fieldDiff = diffPlanSnapshots(
      previous: previousVersion?.planSnapshot,
      current: snapshot,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.versionRound(version.roundNumber),
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
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
                  borderRadius: BorderRadius.circular(
                    ObsidianUiTokens.radiusMd,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.change_history_rounded,
                      size: 16,
                      color: t.primary,
                    ),
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
            if (!fieldDiff.isEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _SnapshotDiffSection(diff: fieldDiff, tokens: t),
            ],
            if (marketScore > 0 || techScore > 0) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _ScoreChip(
                      label: l10n.marketPotential,
                      value: marketScore,
                      color: t.primary,
                      tokens: t,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ScoreChip(
                      label: l10n.technicalComplexity,
                      value: techScore,
                      color: t.secondary,
                      tokens: t,
                    ),
                  ),
                ],
              ),
            ],
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
            const SizedBox(height: AppSpacing.xl),
            BlocBuilder<PlanVersionHistoryCubit, PlanVersionHistoryState>(
              builder: (context, state) {
                return ObsidianGradientButton(
                  onPressed: state.isRestoring
                      ? null
                      : () => _confirmRestore(context),
                  icon: Icons.restore_rounded,
                  label: state.isRestoring
                      ? l10n.restoring
                      : l10n.makeCurrentVersion,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.versionRestoreTitle,
          style: theme.textTheme.titleLarge,
        ),
        content: Text(
          l10n.versionRestoreMessage(version.roundNumber),
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.restore),
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

class _SnapshotDiffSection extends StatelessWidget {
  const _SnapshotDiffSection({required this.diff, required this.tokens});

  final PlanSnapshotDiff diff;
  final ObsidianUiTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: tokens.surfaceContainer,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
        border: Border.all(color: tokens.ghostBorder(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.versionChangesTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final change in diff.changes) ...[
            _FieldChangeRow(change: change, tokens: tokens),
            if (change != diff.changes.last)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _FieldChangeRow extends StatelessWidget {
  const _FieldChangeRow({required this.change, required this.tokens});

  final PlanSnapshotFieldChange change;
  final ObsidianUiTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = planSnapshotFieldLabel(l10n, change.fieldKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: tokens.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (change.isNew)
          Text(
            '${l10n.versionFieldNew}: ${change.after}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.onSurfaceVariant,
              height: 1.4,
            ),
          )
        else ...[
          Text(
            '${l10n.versionFieldBefore}: ${change.before}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.onSurfaceVariant.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${l10n.versionFieldAfter}: ${change.after}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
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
            style: theme.textTheme.labelSmall?.copyWith(color: tokens.primary),
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
                    ObsidianUiTokens.radiusFull,
                  ),
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
