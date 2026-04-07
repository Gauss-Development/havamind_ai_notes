import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample/core/di/injection.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/app_theme_cubit.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/auth/domain/entities/user_profile.dart';
import 'package:sample/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sample/features/subscription/presentation/cubit/subscription_cubit.dart';
import 'package:sample/features/subscription/presentation/widgets/subscription_status_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => getIt<SubscriptionCubit>()..loadStatus(),
      child: Scaffold(
        backgroundColor: t.surface,
        appBar: AppBar(
          title: Text('Profile', style: theme.textTheme.headlineLarge),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _UserHeader(profile: profile),
                const SizedBox(height: AppSpacing.xxl),
                const _SectionLabel(text: 'SUBSCRIPTION'),
                const SizedBox(height: AppSpacing.md),
                const SubscriptionStatusCard(),
                const SizedBox(height: AppSpacing.xxl),
                const _SectionLabel(text: 'PREFERENCES'),
                const SizedBox(height: AppSpacing.md),
                const _PreferencesCard(),
                const SizedBox(height: AppSpacing.xxl),
                const _LogOutButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── User header ─────────────────────────────────────────────────────────────

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: t.surfaceContainerHigh,
          backgroundImage: profile.avatarUrl != null
              ? NetworkImage(profile.avatarUrl!)
              : null,
          child: profile.avatarUrl == null
              ? Text(
                  _initials(profile),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: t.primary,
                  ),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          profile.displayName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          profile.email,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: t.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _initials(UserProfile p) {
    final name = p.fullName ?? p.email;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ─── Section label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.obsidian.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── Preferences card ────────────────────────────────────────────────────────

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
        border: Border.all(color: t.ghostBorder(0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _AppearanceRow(),
          _divider(t),
          _NotificationsRow(),
          _divider(t),
          _LanguageRow(),
        ],
      ),
    );
  }

  Widget _divider(ObsidianUiTokens t) {
    return Divider(
      height: 1,
      thickness: 1,
      color: t.outlineVariant.withValues(alpha: 0.1),
    );
  }
}

class _AppearanceRow extends StatelessWidget {
  const _AppearanceRow();

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;

    return BlocBuilder<AppThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final isLight = mode == ThemeMode.light ||
            (mode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.light);

        return _PreferenceRow(
          icon: Icons.palette_rounded,
          iconBg: t.primaryContainer,
          iconColor: t.primary,
          title: 'Appearance',
          subtitle: isLight ? 'Light theme' : 'Dark theme',
          trailing: _ThemePillToggle(isLight: isLight),
        );
      },
    );
  }
}

class _ThemePillToggle extends StatelessWidget {
  const _ThemePillToggle({required this.isLight});

  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusFull),
        border: Border.all(color: t.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillButton(
            label: 'Light',
            selected: isLight,
            onTap: () => context
                .read<AppThemeCubit>()
                .setThemeMode(ThemeMode.light),
          ),
          _PillButton(
            label: 'Dark',
            selected: !isLight,
            onTap: () => context
                .read<AppThemeCubit>()
                .setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? t.surfaceContainerLowest : Colors.transparent,
          borderRadius:
              BorderRadius.circular(ObsidianUiTokens.radiusFull),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: selected ? t.primary : t.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _NotificationsRow extends StatefulWidget {
  const _NotificationsRow();

  @override
  State<_NotificationsRow> createState() => _NotificationsRowState();
}

class _NotificationsRowState extends State<_NotificationsRow> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    return _PreferenceRow(
      icon: Icons.notifications_rounded,
      iconBg: t.primaryContainer,
      iconColor: t.primary,
      title: 'Notifications',
      subtitle: _enabled ? 'Smart alerts only' : 'Disabled',
      trailing: Switch(
        value: _enabled,
        onChanged: (v) => setState(() => _enabled = v),
        activeThumbColor: Colors.white,
        activeTrackColor: t.primary,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: t.outlineVariant,
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: _PreferenceRow(
          icon: Icons.translate_rounded,
          iconBg: t.primaryContainer,
          iconColor: t.primary,
          title: 'Language',
          subtitle: 'English (US)',
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: t.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.base,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// ─── Log Out ─────────────────────────────────────────────────────────────────

class _LogOutButton extends StatelessWidget {
  const _LogOutButton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.read<AuthBloc>().add(
          const AuthEvent.signOutPressed(),
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('Log Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.error,
          side: BorderSide(color: colorScheme.error.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ObsidianUiTokens.radiusMd),
          ),
          textStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
