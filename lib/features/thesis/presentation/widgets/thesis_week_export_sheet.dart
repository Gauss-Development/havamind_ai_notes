import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:sample/core/di/injection.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/obsidian_gradient_button.dart';
import 'package:sample/features/thesis/presentation/cubit/thesis_week_export_cubit.dart';
import 'package:sample/features/thesis/presentation/utils/weekly_thesis_export_formatter.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

Future<void> showThesisWeekExportSheet({required BuildContext context}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => BlocProvider(
      create: (_) => getIt<ThesisWeekExportCubit>()..load(),
      child: const ThesisWeekExportSheet(),
    ),
  );
}

class ThesisWeekExportSheet extends StatelessWidget {
  const ThesisWeekExportSheet({super.key});

  WeeklyExportLabels _labels(AppLocalizations l10n, Locale locale) {
    final dateFmt = DateFormat.MMMd(locale.toString());
    return WeeklyExportLabels(
      highlightsTitle: l10n.investorUpdatePromptHighlightsTitle,
      metricsTitle: l10n.investorUpdatePromptMetricsTitle,
      askTitle: l10n.investorUpdatePromptAskTitle,
      untitledNote: l10n.planReadinessUntitledNote,
      noMetrics: l10n.thesisCollectWeekNoMetrics,
      noAsk: l10n.thesisCollectWeekNoAsk,
      debriefsThisWeek: l10n.thesisCollectWeekDebriefCount,
      weekOf: l10n.thesisCollectWeekRange,
      formatDate: (date) => dateFmt.format(date.toLocal()),
    );
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.copiedToClipboard),
        ),
      );
    }
  }

  Future<void> _share(BuildContext context, String text) async {
    final result = await SharePlus.instance.share(ShareParams(text: text));
    if (!context.mounted) return;
    // dismissed = closed the sheet. unavailable = OS cannot say whether
    // a target was picked; the founder still left via Share, not Copy.
    if (result.status != ShareResultStatus.dismissed) {
      await context.read<ThesisWeekExportCubit>().recordShare();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final t = context.obsidian;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      decoration: BoxDecoration(
        color: t.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ObsidianUiTokens.radiusXxl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.base),
              decoration: BoxDecoration(
                color: t.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(
                  ObsidianUiTokens.radiusFull,
                ),
              ),
            ),
          ),
          Text(
            l10n.thesisCollectWeekTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          BlocBuilder<ThesisWeekExportCubit, ThesisWeekExportState>(
            builder: (context, state) {
              return switch (state) {
                ThesisWeekExportInitial() ||
                ThesisWeekExportLoading() => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                ThesisWeekExportEmpty() => _EmptyWeek(l10n: l10n),
                ThesisWeekExportError(:final failure) => _WeekError(
                  message: failure.message,
                  onRetry: () => context.read<ThesisWeekExportCubit>().load(),
                ),
                ThesisWeekExportReady(:final export) => _ReadyWeek(
                  letter: WeeklyThesisExportFormatter.letter(
                    export,
                    _labels(l10n, Localizations.localeOf(context)),
                  ),
                  onCopy: (text) => _copy(context, text),
                  onShare: (text) => _share(context, text),
                ),
              };
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyWeek extends StatelessWidget {
  const _EmptyWeek({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.obsidian;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.thesisCollectWeekEmpty,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.thesisCollectWeekEmptyHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: t.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekError extends StatelessWidget {
  const _WeekError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final t = context.obsidian;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.thesisLoadError,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: t.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppGradientButton(
            onPressed: onRetry,
            label: l10n.thesisRetry,
            variant: AppButtonVariant.outlined,
          ),
        ],
      ),
    );
  }
}

class _ReadyWeek extends StatelessWidget {
  const _ReadyWeek({
    required this.letter,
    required this.onCopy,
    required this.onShare,
  });

  final String letter;
  final Future<void> Function(String text) onCopy;
  final Future<void> Function(String text) onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final t = context.obsidian;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.thesisCollectWeekSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: t.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.42,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.surfaceContainerLow,
              borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: SelectableText(
                letter,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppGradientButton(
                onPressed: () => onCopy(letter),
                label: l10n.copyToClipboard,
                icon: Icons.copy_rounded,
                variant: AppButtonVariant.outlined,
                expand: true,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppGradientButton(
                onPressed: () => onShare(letter),
                label: l10n.share,
                icon: Icons.share_rounded,
                expand: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
