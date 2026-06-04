import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';
import 'package:sample/features/audio_notes/presentation/utils/plan_export_formatter.dart';
import 'package:sample/l10n/generated/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

enum _PlanExportFormat { onePager, pitchBullets, emailIntro }

Future<void> showPlanExportSheet({
  required BuildContext context,
  required StartupAnalysis analysis,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PlanExportSheet(analysis: analysis),
  );
}

class _PlanExportSheet extends StatelessWidget {
  const _PlanExportSheet({required this.analysis});

  final StartupAnalysis analysis;

  String _textFor(_PlanExportFormat format) {
    switch (format) {
      case _PlanExportFormat.onePager:
        return PlanExportFormatter.onePager(analysis);
      case _PlanExportFormat.pitchBullets:
        return PlanExportFormatter.pitchBullets(analysis);
      case _PlanExportFormat.emailIntro:
        return PlanExportFormatter.emailIntro(analysis);
    }
  }

  String _titleFor(AppLocalizations l10n, _PlanExportFormat format) {
    switch (format) {
      case _PlanExportFormat.onePager:
        return l10n.exportOnePager;
      case _PlanExportFormat.pitchBullets:
        return l10n.exportPitchBullets;
      case _PlanExportFormat.emailIntro:
        return l10n.exportEmailIntro;
    }
  }

  String _subtitleFor(AppLocalizations l10n, _PlanExportFormat format) {
    switch (format) {
      case _PlanExportFormat.onePager:
        return l10n.exportOnePagerHint;
      case _PlanExportFormat.pitchBullets:
        return l10n.exportPitchBulletsHint;
      case _PlanExportFormat.emailIntro:
        return l10n.exportEmailIntroHint;
    }
  }

  Future<void> _copy(BuildContext context, _PlanExportFormat format) async {
    await Clipboard.setData(ClipboardData(text: _textFor(format)));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.copiedToClipboard)),
      );
    }
  }

  Future<void> _share(_PlanExportFormat format) async {
    await SharePlus.instance.share(ShareParams(text: _textFor(format)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final t = context.obsidian;

    return Container(
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
                borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusFull),
              ),
            ),
          ),
          Text(
            l10n.exportPlan,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.exportPlanSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: t.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final format in _PlanExportFormat.values) ...[
            _ExportFormatRow(
              title: _titleFor(l10n, format),
              subtitle: _subtitleFor(l10n, format),
              onCopy: () => _copy(context, format),
              onShare: () => _share(format),
              copyLabel: l10n.copyToClipboard,
              shareLabel: l10n.share,
            ),
            if (format != _PlanExportFormat.values.last)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ExportFormatRow extends StatelessWidget {
  const _ExportFormatRow({
    required this.title,
    required this.subtitle,
    required this.onCopy,
    required this.onShare,
    required this.copyLabel,
    required this.shareLabel,
  });

  final String title;
  final String subtitle;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final String copyLabel;
  final String shareLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.obsidian;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: t.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: t.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: copyLabel,
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 20),
          ),
          IconButton(
            tooltip: shareLabel,
            onPressed: onShare,
            icon: const Icon(Icons.share_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
