import 'package:flutter/material.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';

/// Visual variants for [AppGradientButton].
enum AppButtonVariant {
  /// Indigo → violet gradient. Default primary CTA.
  gradient,

  /// Solid [AppTokens.primary]. Use when stacked next to a gradient button.
  filled,

  /// Transparent fill with brand-colored border. Secondary CTA.
  outlined,
}

/// Primary CTA used across the app.
///
/// Defaults to the [AppButtonVariant.gradient] variant — the indigo→violet
/// hero treatment from the design system. Disabled and loading states are
/// rendered explicitly; the widget never relies on hover-only feedback.
///
/// Always renders at >= 48dp height to satisfy [AppTapTarget].
class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.variant = AppButtonVariant.gradient,
    this.expand = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final AppButtonVariant variant;

  /// When true, stretches to the parent's full width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final disabled = onPressed == null || isLoading;

    final textStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: variant == AppButtonVariant.outlined
              ? t.primary
              : t.onPrimaryButton,
        );

    final child = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
      foreground: textStyle?.color ?? t.onPrimaryButton,
      expand: expand,
    );

    final button = AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      opacity: disabled ? 0.5 : 1,
      child: switch (variant) {
        AppButtonVariant.gradient => _GradientSurface(
            tokens: t,
            disabled: disabled,
            onPressed: disabled ? null : onPressed,
            textStyle: textStyle,
            expand: expand,
            child: child,
          ),
        AppButtonVariant.filled => FilledButton(
            onPressed: disabled ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: t.primary,
              foregroundColor: t.onPrimaryButton,
              disabledBackgroundColor: t.primary.withValues(alpha: 0.5),
              disabledForegroundColor:
                  t.onPrimaryButton.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              minimumSize: const Size(0, AppTapTarget.minSize),
              shape: const StadiumBorder(),
              textStyle: textStyle,
            ),
            child: child,
          ),
        AppButtonVariant.outlined => OutlinedButton(
            onPressed: disabled ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: t.primary,
              side: BorderSide(color: t.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              minimumSize: const Size(0, AppTapTarget.minSize),
              shape: const StadiumBorder(),
              textStyle: textStyle,
            ),
            child: child,
          ),
      },
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _GradientSurface extends StatelessWidget {
  const _GradientSurface({
    required this.tokens,
    required this.disabled,
    required this.onPressed,
    required this.textStyle,
    required this.expand,
    required this.child,
  });

  final AppTokens tokens;
  final bool disabled;
  final VoidCallback? onPressed;
  final TextStyle? textStyle;
  final bool expand;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shape = const StadiumBorder();
    final body = DefaultTextStyle.merge(
      style: textStyle,
      child: IconTheme.merge(
        data: IconThemeData(color: textStyle?.color),
        child: child,
      ),
    );
    return Material(
      color: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: ShapeDecoration(
          gradient: tokens.primaryGradient,
          shape: shape,
          shadows: disabled ? const [] : tokens.vibrantGlow,
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: shape,
          splashColor: tokens.onPrimaryButton.withValues(alpha: 0.18),
          highlightColor: tokens.onPrimaryButton.withValues(alpha: 0.08),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppTapTarget.minSize),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: expand
                  ? body
                  : Center(
                      child: body,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.foreground,
    required this.expand,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color foreground;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      label,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foreground,
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        if (expand)
          Expanded(child: labelWidget)
        else
          labelWidget,
      ],
    );
  }
}

/// Gradient extended FAB. Uses [AppTokens.primaryGradient] + glow.
class AppGradientFab extends StatelessWidget {
  const AppGradientFab({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
    );
    return Material(
      color: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: ShapeDecoration(
          gradient: t.primaryGradient,
          shape: shape,
          shadows: t.vibrantGlow,
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: shape,
          splashColor: t.onPrimaryButton.withValues(alpha: 0.18),
          highlightColor: t.onPrimaryButton.withValues(alpha: 0.08),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppTapTarget.minSize),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: t.onPrimaryButton),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: t.onPrimaryButton,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Backwards-compatible aliases ─────────────────────────────────────────
//
// Existing screens import the `Obsidian*` names. Keep them exported so the
// component-library refactor is non-breaking; Step 5 migrates callsites.

/// Alias for [AppGradientButton]. Prefer the new name in new code.
class ObsidianGradientButton extends StatelessWidget {
  const ObsidianGradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => AppGradientButton(
        onPressed: onPressed,
        label: label,
        icon: icon,
        isLoading: isLoading,
      );
}

/// Alias for [AppGradientFab].
class ObsidianGradientFab extends StatelessWidget {
  const ObsidianGradientFab({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) =>
      AppGradientFab(onPressed: onPressed, icon: icon, label: label);
}
