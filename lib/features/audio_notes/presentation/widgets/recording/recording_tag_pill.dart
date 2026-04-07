import 'package:flutter/material.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';

class RecordingTagPill extends StatelessWidget {
  const RecordingTagPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
        ),
      ),
    );
  }
}
