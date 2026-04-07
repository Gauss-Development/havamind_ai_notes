import 'package:flutter/material.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';

class RecordingAutoTranscriptionCard extends StatelessWidget {
  const RecordingAutoTranscriptionCard({super.key, required this.tokens});

  final ObsidianUiTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: tokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tokens.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, color: tokens.primary, size: 21),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-Transcription',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  'Enabled: English (US)',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: true,
            onChanged: null,
            activeThumbColor: Colors.white,
            activeTrackColor: tokens.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: tokens.outlineVariant,
          ),
        ],
      ),
    );
  }
}
