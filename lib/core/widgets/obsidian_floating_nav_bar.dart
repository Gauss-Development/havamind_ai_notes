import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';

class ObsidianNavItem {
  const ObsidianNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

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
  Widget build(BuildContext context) {
    final t = context.obsidian;

    return CurvedNavigationBar(
      key: navigationKey,
      index: currentIndex,
      items: List.generate(items.length, (i) {
        final item = items[i];
        final selected = i == currentIndex;
        return Icon(
          selected ? item.activeIcon : item.icon,
          size: 26,
          color: selected ? t.onPrimaryButton : t.onSurfaceVariant,
        );
      }),
      color: t.surfaceContainerLowest,
      buttonBackgroundColor: t.primary,
      backgroundColor: Colors.transparent,
      animationCurve: Curves.easeInOutCubic,
      animationDuration: const Duration(milliseconds: 400),
      height: kObsidianNavBarHeight,
      onTap: onTap,
    );
  }
}
