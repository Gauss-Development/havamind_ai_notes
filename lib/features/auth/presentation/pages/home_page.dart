import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';
import 'package:sample/features/auth/presentation/bloc/auth_bloc.dart';

/// Obsidian-style dark shell (Concepts) — colors from design reference.
abstract final class _C {
  static const Color primary = Color(0xFFC0C1FF);
  static const Color secondary = Color(0xFF4FDBC8);
  static const Color background = Color(0xFF0B1326);
  static const Color surface = Color(0xFF131B2E);
  static const Color surfaceVariant = Color(0xFF1D253A);
  static const Color onSurface = Color(0xFFDAE2FD);
  static const Color onSurfaceVariant = Color(0xFF918FA1);
  static const Color outline = Color(0x14FFFFFF);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _tabs = ['Index', 'Market', 'Technical', 'Monetization'];
  int _selectedTab = 0;

  static const _demoAvatar =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCquzU3f7IUAUEZZzvIX3JcsuHY1dg_uqFeWwmxHfuZfwp-I8-32_-A068s3JKCjRvXYpUrzcncsi3RCsCHj-jIDqi8YenCeumvCdnYC7W3t3r81z6WnAcmrMmsy19yPTigtfDXDYp6VgTfJiLQ95qwcXH0YsEFMeosINukLit4YNINcvBbOohm3x1nD3qGtuzU2kTxHhZE0JNS_d6Z9o3dSWoVC9m0dBkU_60RLU85MNtfydTyvSivT30DnCrYBeDMoqcWNOsbtO8';

  static const _heroImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD17dcJ2BeEJZjptmapGStIFwWkHgv_82McE0tpFUirza55plrT_3cC6ZhCNV4h3YBrmncvbvJZpa_-M8TrYb2mS_8u0l-1Af1YDNktlwjkNPj-0_Ono_4Kcsw54DIO4-SyMh_E_oM5r7zmZSm79nSxU-spbIZHduUnXir-8pHr7tJ6P38K_EoJIQyDSSXv83MCGRe2b_s7YwC1zO4AeQFAPD-lTmAVFFho6T1SDhFeVyRPtyR84v_DLAJnYf5cihFaSDbCf531NPw';

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    const headerBarH = 56.0;
    const tabStripH = 40.0;
    final pinnedH = top + headerBarH + tabStripH;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _C.background,
      ),
      child: Scaffold(
        backgroundColor: _C.background,
        extendBody: true,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: 64 + bottomInset),
          child: Material(
            color: _C.primary,
            borderRadius: BorderRadius.circular(16),
            elevation: 8,
            shadowColor: _C.primary.withValues(alpha: 0.35),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Create'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 56,
                height: 56,
                child: Icon(Icons.add, color: _C.background, size: 30),
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: _BottomNav(bottomInset: bottomInset),
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: pinnedH)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _IntelligenceCard(profile: widget.profile),
                      const SizedBox(height: 16),
                      _SectionLabel(
                        title: 'Featured Concept',
                        badge: 'High Conviction',
                      ),
                      const SizedBox(height: 8),
                      _FeaturedConceptCard(heroUrl: _heroImage),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RECENT NODES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: _C.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'VIEW ALL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _C.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _NodeCard(
                              icon: Icons.device_hub_outlined,
                              iconBg: const Color(0x336366F1),
                              iconColor: const Color(0xFF818CF8),
                              title: 'Spatial Vault',
                              subtitle:
                                  'Force-directed research gravity visualization.',
                              idLabel: 'ID: 0284',
                              timeLabel: '2D AGO',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NodeCard(
                              icon: Icons.auto_awesome_outlined,
                              iconBg: const Color(0x3322C55E),
                              iconColor: const Color(0xFF4ADE80),
                              title: 'AI Exec Inbox',
                              subtitle: 'Autonomous meeting negotiation logic.',
                              idLabel: 'ID: 0285',
                              timeLabel: '5D AGO',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 120 + bottomInset),
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _C.background.withValues(alpha: 0.82),
                      border: const Border(
                        bottom: BorderSide(color: _C.outline),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: top),
                        SizedBox(
                          height: headerBarH,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  color: _C.surfaceVariant,
                                  onSelected: (v) {
                                    if (v == 'signout') {
                                      context.read<AuthBloc>().add(
                                        const AuthEvent.signOutPressed(),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'signout',
                                      child: Text('Выйти'),
                                    ),
                                  ],
                                  child: _Avatar(
                                    url: widget.profile.avatarUrl,
                                    fallback: widget.profile.displayName,
                                    demoUrl: _demoAvatar,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Concepts',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: _C.onSurface,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {},
                                  style: IconButton.styleFrom(
                                    foregroundColor: _C.onSurfaceVariant,
                                  ),
                                  icon: const Icon(Icons.search, size: 22),
                                ),
                                IconButton(
                                  onPressed: () {},
                                  style: IconButton.styleFrom(
                                    foregroundColor: _C.primary,
                                  ),
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: tabStripH,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            itemCount: _tabs.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 4),
                            itemBuilder: (context, i) {
                              final selected = i == _selectedTab;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedTab = i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? _C.primary
                                        : _C.surfaceVariant,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _tabs[i],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: selected
                                          ? _C.background
                                          : _C.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final loading = state.maybeWhen(
                  loading: () => true,
                  orElse: () => false,
                );
                if (!loading) return const SizedBox.shrink();
                return const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: _C.surface,
                    color: _C.primary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.fallback,
    required this.demoUrl,
  });

  final String? url;
  final String fallback;
  final String demoUrl;

  @override
  Widget build(BuildContext context) {
    final effective = (url != null && url!.isNotEmpty) ? url! : demoUrl;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _C.primary.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        effective,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => CircleAvatar(
          backgroundColor: _C.surfaceVariant,
          child: Text(
            fallback.isNotEmpty ? fallback[0].toUpperCase() : '?',
            style: const TextStyle(
              color: _C.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _IntelligenceCard extends StatelessWidget {
  const _IntelligenceCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _C.surfaceVariant.withValues(alpha: 0.5),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _C.primary.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.auto_awesome, color: _C.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INTELLIGENCE SYNC',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: _C.primary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome back, ${profile.displayName}. Your workspace is ready for the next voice capture.',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: _C.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.badge});

  final String title;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: _C.onSurfaceVariant,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _C.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _C.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedConceptCard extends StatelessWidget {
  const _FeaturedConceptCard({required this.heroUrl});

  final String heroUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _C.surfaceVariant.withValues(alpha: 0.5),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 160,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0.4,
                    0,
                  ]),
                  child: Image.network(
                    heroUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: _C.surface),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        _C.surface.withValues(alpha: 0.1),
                        _C.surface,
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: Text(
                    'Decentralized GPU Orchestration',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.5,
                      color: _C.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Middleware layer for renting idle residential GPU capacity using ZK-verification.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: _C.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'MARKET',
                        labelColor: _C.primary,
                        value: '4:1 Supply Gap',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        label: 'TECH',
                        labelColor: _C.secondary,
                        value: 'LibP2P/ZK',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        label: 'STATUS',
                        labelColor: Color(0x66FFFFFF),
                        value: 'V4 Review',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _C.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Validate Concept',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.labelColor,
    required this.value,
  });

  final String label;
  final Color labelColor;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              height: 1.2,
              color: _C.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.idLabel,
    required this.timeLabel,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String idLabel;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _C.surfaceVariant.withValues(alpha: 0.5),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: iconBg,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: _C.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.35,
              color: _C.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x0DFFFFFF))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  idLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                Text(
                  timeLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(
            color: _C.background.withValues(alpha: 0.9),
            border: const Border(top: BorderSide(color: _C.outline)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.grid_view_outlined,
                    label: 'Dash',
                    selected: false,
                    onTap: () {},
                  ),
                  _NavItem(
                    icon: Icons.blur_on_outlined,
                    label: 'Record',
                    onTap: () {},
                  ),
                  _NavItem(
                    icon: Icons.lightbulb,
                    label: 'Concepts',
                    selected: true,
                    onTap: () {},
                  ),
                  _NavItem(
                    icon: Icons.layers_outlined,
                    label: 'Validation',
                    onTap: () {},
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? _C.primary
        : _C.onSurfaceVariant.withValues(alpha: 0.6);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
