import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sample/core/di/injection.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/audio_notes/domain/entities/plan_version.dart';
import 'package:sample/features/audio_notes/presentation/bloc/plan_version_history_cubit.dart';
import 'package:sample/features/audio_notes/presentation/pages/plan_version_preview_page.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

class PlanVersionHistoryPage extends StatelessWidget {
  const PlanVersionHistoryPage({
    super.key,
    required this.planId,
    required this.noteId,
  });

  final String planId;
  final String noteId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PlanVersionHistoryCubit>()..load(planId),
      child: _VersionHistoryView(noteId: noteId, planId: planId),
    );
  }
}

class _VersionHistoryView extends StatelessWidget {
  const _VersionHistoryView({required this.noteId, required this.planId});

  final String noteId;
  final String planId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final t = context.obsidian;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.versionHistory, style: theme.textTheme.titleMedium),
        centerTitle: true,
      ),
      body: BlocConsumer<PlanVersionHistoryCubit, PlanVersionHistoryState>(
        listener: (context, state) {
          if (state.restoredRound != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.versionRestoredFromRound(state.restoredRound!),
                ),
              ),
            );
            Navigator.of(context).pop(true);
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.versions.isEmpty) {
            return Center(
              child: Text(
                l10n.noVersionHistory,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: t.onSurfaceVariant,
                ),
              ),
            );
          }

          final versions = state.versions;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.base,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            itemCount: versions.length,
            itemBuilder: (context, index) {
              final version = versions[index];
              final isLatest = index == versions.length - 1;
              return _VersionTimelineItem(
                version: version,
                isLatest: isLatest,
                isLast: index == versions.length - 1,
                onTap: () => _openPreview(
                  context,
                  version: version,
                  previousVersion: index > 0 ? versions[index - 1] : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openPreview(
    BuildContext context, {
    required PlanVersion version,
    PlanVersion? previousVersion,
  }) async {
    final cubit = context.read<PlanVersionHistoryCubit>();
    final restored = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: PlanVersionPreviewPage(
            version: version,
            previousVersion: previousVersion,
          ),
        ),
      ),
    );
    if (restored == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }
}

class _VersionTimelineItem extends StatelessWidget {
  const _VersionTimelineItem({
    required this.version,
    required this.isLatest,
    required this.isLast,
    required this.onTap,
  });

  final PlanVersion version;
  final bool isLatest;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.obsidian;
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d, h:mm a');

    final transcriptExcerpt = version.transcription != null
        ? (version.transcription!.length > 80
            ? '${version.transcription!.substring(0, 80)}...'
            : version.transcription!)
        : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLatest ? t.primary : t.surfaceContainerLow,
                    border: Border.all(
                      color: isLatest ? t.primary : t.outlineVariant,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: t.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Content card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.base),
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: t.surfaceContainerLowest,
                    borderRadius:
                        BorderRadius.circular(ObsidianUiTokens.radiusMd),
                    border: Border.all(
                      color: isLatest
                          ? t.primary.withValues(alpha: 0.3)
                          : t.ghostBorder(0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.versionRound(version.roundNumber),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color:
                                  isLatest ? t.primary : null,
                            ),
                          ),
                          if (isLatest) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: t.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                    ObsidianUiTokens.radiusXs),
                              ),
                              child: Text(
                                l10n.versionCurrent,
                                style:
                                    theme.textTheme.labelSmall?.copyWith(
                                  color: t.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            dateFmt.format(version.createdAt.toLocal()),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: t.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (version.diffSummary != null &&
                          version.diffSummary!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          version.diffSummary!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (transcriptExcerpt != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          transcriptExcerpt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: t.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: t.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
