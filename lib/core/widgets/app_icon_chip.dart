import 'package:flutter/material.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';

/// Compact tappable chip with an icon + label.
///
/// Used for inline filters, quick toggles, status badges, and meta
/// rows under titles. Three semantic tones map to design-system colors:
///
///   - [AppIconChipTone.neutral] — `surfaceContainerHigh` + onSurface text
///   - [AppIconChipTone.brand]   — primary tint
///   - [AppIconChipTone.accent]  — tertiary (cyan) tint
///   - [AppIconChipTone.success] — secondary (teal) tint
///   - [AppIconChipTone.warning] — warning amber
///
/// All variants enforce a 32dp minimum height (visual chip standard);
/// when interactive, the chip is wrapped in a 48dp hit-test area via
/// [Semantics] / [InkWell] padding so it still meets touch targets.
enum AppIconChipTone { neutral, brand, accent, success, warning }

class AppIconChip extends StatelessWidget {
  const AppIconChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = AppIconChipTone.neutral,
    this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final AppIconChipTone tone;
  final VoidCallback? onTap;

  /// Renders the chip in a "filled" selected state regardless of tone.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);
    final shape = BorderRadius.circular(ObsidianUiTokens.radiusFull);
    final palette = _palette(t);

    final bg = selected ? palette.fg.withValues(alpha: 0.18) : palette.bg;
    final fg = palette.fg;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    final chip = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 32),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: shape,
          border: Border.all(color: fg.withValues(alpha: 0.20)),
        ),
        child: content,
      ),
    );

    if (onTap == null) return chip;

    return Semantics(
      button: true,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTapTarget.minSize),
        child: Material(
          color: Colors.transparent,
          borderRadius: shape,
          child: InkWell(
            onTap: onTap,
            borderRadius: shape,
            splashFactory: InkRipple.splashFactory,
            splashColor: fg.withValues(alpha: 0.18),
            highlightColor: fg.withValues(alpha: 0.08),
            child: chip,
          ),
        ),
      ),
    );
  }

  ({Color bg, Color fg}) _palette(ObsidianUiTokens t) {
    switch (tone) {
      case AppIconChipTone.neutral:
        return (bg: t.surfaceContainerHigh, fg: t.onSurface);
      case AppIconChipTone.brand:
        return (bg: t.primary.withValues(alpha: 0.14), fg: t.primary);
      case AppIconChipTone.accent:
        return (bg: t.tertiary.withValues(alpha: 0.14), fg: t.tertiary);
      case AppIconChipTone.success:
        return (bg: t.secondary.withValues(alpha: 0.14), fg: t.secondary);
      case AppIconChipTone.warning:
        return (bg: t.warning.withValues(alpha: 0.14), fg: t.warning);
    }
  }
}
