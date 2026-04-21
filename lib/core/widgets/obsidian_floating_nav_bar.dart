import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
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
/// Renders a [CurvedNavigationBar] over an ambient brand glow drawn from
/// [AppTokens.elevationLg]. Tap targets sit on the bar's full height
/// ([kAppNavBarHeight] = 64dp), comfortably above the 48dp minimum.
class AppFloatingNavBar extends StatelessWidget {
  const AppFloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.navigationKey,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final GlobalKey<CurvedNavigationBarState>? navigationKey;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: false,
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(boxShadow: t.elevationLg),
          child: CurvedNavigationBar(
            key: navigationKey,
            index: currentIndex,
            items: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              return Semantics(
                selected: selected,
                label: item.label,
                button: true,
                child: Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 26,
                  color: selected ? t.onPrimaryButton : t.onSurfaceVariant,
                ),
              );
            }),
            color: t.surfaceContainerLowest,
            buttonBackgroundColor: t.primary,
            backgroundColor: Colors.transparent,
            animationCurve: Curves.easeInOutCubic,
            animationDuration: const Duration(milliseconds: 380),
            height: kAppNavBarHeight,
            onTap: onTap,
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

/// Alias for [AppFloatingNavBar].
class ObsidianFloatingNavBar extends StatelessWidget {
  const ObsidianFloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.navigationKey,
  });

  final List<ObsidianNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final GlobalKey<CurvedNavigationBarState>? navigationKey;

  @override
  Widget build(BuildContext context) => AppFloatingNavBar(
        items: items,
        currentIndex: currentIndex,
        onTap: onTap,
        navigationKey: navigationKey,
      );
}
