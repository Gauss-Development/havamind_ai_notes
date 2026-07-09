import 'package:flutter/material.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';

/// Single nav-bar destination.
class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating bottom navigation bar.
///
/// A fully-rounded "pill" that hovers above the system gesture bar / home
/// indicator (via [appSystemBottomInset]). The active destination is marked
/// by a primary-tinted highlight that slides between slots, while icons
/// cross-fade between their outlined and filled variants. Custom-drawn so it
/// has no hard corners and no external package dependency.
class AppFloatingNavBar extends StatelessWidget {
  const AppFloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const Duration _slideDuration = Duration(milliseconds: 340);
  static const Curve _slideCurve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final bottomInset = appSystemBottomInset(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        bottomInset + AppSpacing.sm,
      ),
      child: RepaintBoundary(
        child: Container(
          height: kAppNavBarHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: t.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusFull),
            boxShadow: t.elevationLg,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final count = items.length;
              final slotWidth = constraints.maxWidth / count;

              return Stack(
                children: [
                  // Sliding highlight behind the active destination.
                  AnimatedPositioned(
                    duration: _slideDuration,
                    curve: _slideCurve,
                    top: 0,
                    bottom: 0,
                    left: slotWidth * currentIndex,
                    width: slotWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.primary,
                          borderRadius: BorderRadius.circular(
                            ObsidianUiTokens.radiusFull,
                          ),
                          boxShadow: t.elevationMd,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(count, (i) {
                      return Expanded(
                        child: _NavButton(
                          item: items[i],
                          selected: i == currentIndex,
                          tokens: t,
                          onTap: () => onTap(i),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.tokens,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final AppTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedScale(
            scale: selected ? 1.0 : 0.9,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                key: ValueKey(selected),
                size: 26,
                color:
                    selected ? tokens.onPrimaryButton : tokens.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Backwards-compatible aliases ─────────────────────────────────────────

/// Alias for [AppNavItem]. Prefer the new name in new code.
class ObsidianNavItem extends AppNavItem {
  const ObsidianNavItem({
    required super.icon,
    required super.activeIcon,
    required super.label,
  });
}

/// Alias for [AppFloatingNavBar]. Prefer the new name in new code.
class ObsidianFloatingNavBar extends StatelessWidget {
  const ObsidianFloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<ObsidianNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => AppFloatingNavBar(
        items: items,
        currentIndex: currentIndex,
        onTap: onTap,
      );
}
