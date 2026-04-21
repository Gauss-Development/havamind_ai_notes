import 'package:flutter/material.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';

/// Soft brand backdrop for hero surfaces — login, recording stage,
/// empty states, founder card.
///
/// Paints [AppTokens.heroBackdropGradient] (a radial indigo→violet→cyan
/// blob) behind the child without intercepting hit-testing. Decorative
/// only — the child remains the visual subject.
class AppHeroBackdrop extends StatelessWidget {
  const AppHeroBackdrop({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;

  /// Where the radial blob is anchored. Defaults to top-center.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: t.heroBackdropGradient),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// ── Backwards-compatible alias ────────────────────────────────────────────

/// Alias for [AppHeroBackdrop]. Prefer the new name in new code.
class FounderBackdrop extends StatelessWidget {
  const FounderBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AppHeroBackdrop(child: child);
}
