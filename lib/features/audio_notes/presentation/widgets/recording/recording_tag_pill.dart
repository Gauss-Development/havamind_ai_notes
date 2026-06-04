import 'package:flutter/material.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';

class RecordingTagPill extends StatelessWidget {
  const RecordingTagPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final bg = selected ? t.primary : background;
    final fg = selected ? t.onPrimaryButton : foreground;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusFull),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
