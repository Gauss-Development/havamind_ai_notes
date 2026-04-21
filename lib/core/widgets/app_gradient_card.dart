import 'package:flutter/material.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';

/// Hero card painted with a brand gradient surface and soft glow.
///
/// Used for the highest-emphasis content blocks on a screen — promo
/// banners, primary stat cards, the "now recording" surface. Lower
/// emphasis blocks should stay on plain `surfaceContainer*` colors.
///
/// Two flavors:
///   - [AppGradientCard.primary]  — indigo → violet (`primaryGradient`).
///   - [AppGradientCard.accent]   — cyan → indigo (`accentGradient`).
class AppGradientCard extends StatelessWidget {
  const AppGradientCard({
    super.key,
    required this.child,
    this.onTap,
    this.gradient,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = EdgeInsets.zero,
  }) : _useAccent = false;

  const AppGradientCard.accent({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = EdgeInsets.zero,
  })  : gradient = null,
        _useAccent = true;

  final Widget child;
  final VoidCallback? onTap;

  /// Optional override. If null, uses [AppTokens.primaryGradient] (or
  /// [AppTokens.accentGradient] when constructed via [AppGradientCard.accent]).
  final Gradient? gradient;
  final EdgeInsets padding;
  final EdgeInsets margin;

  final bool _useAccent;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final shape = BorderRadius.circular(ObsidianUiTokens.radiusXl);
    final resolved = gradient ??
        (_useAccent ? t.accentGradient : t.primaryGradient);

    final card = DecoratedBox(
      decoration: BoxDecoration(
        gradient: resolved,
        borderRadius: shape,
        boxShadow: t.vibrantGlow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: shape,
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          splashFactory: InkRipple.splashFactory,
          splashColor: Colors.white.withValues(alpha: 0.16),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (margin == EdgeInsets.zero) return card;
    return Padding(padding: margin, child: card);
  }
}
