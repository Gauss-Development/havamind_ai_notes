import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/subscription/domain/entities/subscription_status.dart';
import 'package:sample/features/subscription/domain/entities/usage_info.dart';
import 'package:sample/features/subscription/presentation/cubit/subscription_cubit.dart';
import 'package:sample/features/subscription/presentation/cubit/subscription_state.dart';
import 'package:sample/features/subscription/presentation/widgets/subscription_detail_sheet.dart';
import 'package:sample/features/subscription/presentation/widgets/usage_circular_indicator.dart';

class SubscriptionStatusCard extends StatelessWidget {
  const SubscriptionStatusCard({
    super.key,
    this.accountDisplayName,
    this.accountEmail,
    this.memberSince,
  });

  /// Shown in the subscription detail sheet (not raw user / product ids).
  final String? accountDisplayName;
  final String? accountEmail;
  final DateTime? memberSince;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionCubit, SubscriptionState>(
      listenWhen: (prev, curr) =>
          curr is SubscriptionError ||
          (prev is SubscriptionLoading && curr is SubscriptionLoaded),
      listener: (context, state) {
        if (state is SubscriptionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is SubscriptionLoading) {
          return const _CardShell(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (state is SubscriptionLoaded) {
          return state.isPro
              ? _ProActiveCard(
                  status: state.status,
                  usageInfo: state.usageInfo,
                  accountDisplayName: accountDisplayName,
                  accountEmail: accountEmail,
                  memberSince: memberSince,
                )
              : _FreeCard(usageInfo: state.usageInfo);
        }

        if (state is SubscriptionError) {
          return _ErrorCard(message: state.message);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ── Card shell ────────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
        border: Border.all(color: t.ghostBorder(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// ── Pro active card ───────────────────────────────────────────────────────────

class _ProActiveCard extends StatelessWidget {
  const _ProActiveCard({
    required this.status,
    this.usageInfo,
    this.accountDisplayName,
    this.accountEmail,
    this.memberSince,
  });

  final SubscriptionStatus status;
  final UsageInfo? usageInfo;
  final String? accountDisplayName;
  final String? accountEmail;
  final DateTime? memberSince;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final tierGradient = status.tier == SubscriptionTier.basic
        ? LinearGradient(
            colors: [
              t.secondary,
              t.secondary.withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [t.primary, t.primary.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final tierIcon = status.tier == SubscriptionTier.basic
        ? Icons.record_voice_over_rounded
        : Icons.workspace_premium_rounded;

    return _CardShell(
      child: Column(
        children: [
          // ── Main info ──
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: tierGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tierIcon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.marketingProductName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${status.planDisplayName} plan',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: t.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
          ),

          // ── Usage indicator ──
          if (usageInfo != null) ...[
            _divider(t),
            UsageCircularIndicator(usageInfo: usageInfo!),
          ],

          // ── Billing issue / cancelled banner ──
          if (status.hasBillingIssue)
            _InlineBanner(
              icon: Icons.warning_amber_rounded,
              text: 'Billing issue — update your payment method',
              color: theme.colorScheme.error,
            ),
          if (status.isCancelled && !status.hasBillingIssue)
            _InlineBanner(
              icon: Icons.info_outline_rounded,
              text: status.expirationDate != null
                  ? 'Access until ${DateFormat.yMMMd().format(status.expirationDate!.toLocal())}'
                  : 'Subscription cancelled',
              color: t.warning,
            ),
          if (status.isTrial && !status.hasBillingIssue && !status.isCancelled)
            _InlineBanner(
              icon: Icons.star_outline_rounded,
              text: status.expirationDate != null
                  ? 'Trial ends ${DateFormat.yMMMd().format(status.expirationDate!.toLocal())}'
                  : 'Free trial active',
              color: t.secondary,
            ),

          // ── Renewal / expiry info ──
          if (!status.isLifetime &&
              !status.isCancelled &&
              !status.hasBillingIssue &&
              !status.isTrial &&
              status.expirationDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.autorenew_rounded,
                    size: 16,
                    color: t.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Renews ${DateFormat.yMMMd().format(status.expirationDate!.toLocal())}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: t.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          _divider(t),

          // ── Actions ──
          _ActionRow(
            icon: Icons.info_outline_rounded,
            label: 'Subscription Details',
            onTap: () => _openDetails(context),
          ),
          _divider(t),
          _ActionRow(
            icon: Icons.settings_rounded,
            label: status.isCancelled
                ? 'Resubscribe or Get Help'
                : 'Manage Subscription',
            onTap: () {
              context.read<SubscriptionCubit>().showCustomerCenter(context);
            },
          ),
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

  Future<void> _openDetails(BuildContext context) async {
    final cubit = context.read<SubscriptionCubit>();
    final action = await showSubscriptionDetailSheet(
      context: context,
      status: status,
      usageInfo: usageInfo,
      accountDisplayName: accountDisplayName,
      accountEmail: accountEmail,
      memberSince: memberSince,
    );
    if (!context.mounted) return;
    if (action == null) return;
    switch (action) {
      case SubscriptionSheetAction.changePlan:
        cubit.showPaywall();
      case SubscriptionSheetAction.customerCenter:
      case SubscriptionSheetAction.manageSubscription:
        cubit.showCustomerCenter(context);
    }
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    final (label, color) = _resolve(t, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusFull),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  (String, Color) _resolve(ObsidianUiTokens t, ThemeData theme) {
    if (status.hasBillingIssue) {
      return ('Billing Issue', theme.colorScheme.error);
    }
    if (status.isTrial) return ('Trial', t.secondary);
    if (status.isCancelled) return ('Cancelled', t.warning);
    return ('Active', t.primary);
  }
}

// ── Inline banner ─────────────────────────────────────────────────────────────

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusSm),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action row ────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.base,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: t.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: t.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: t.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Free user card ────────────────────────────────────────────────────────────

class _FreeCard extends StatelessWidget {
  const _FreeCard({this.usageInfo});

  final UsageInfo? usageInfo;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    return _CardShell(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: t.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: t.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Havamind Voice Free',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Upgrade for more recording time',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: t.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (usageInfo != null) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: t.outlineVariant.withValues(alpha: 0.1),
            ),
            UsageCircularIndicator(usageInfo: usageInfo!),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: () {
                    context.read<SubscriptionCubit>().showPaywall();
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ObsidianUiTokens.radiusMd,
                      ),
                    ),
                  ),
                  child: const Text('Upgrade to Pro'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () {
                    context.read<SubscriptionCubit>().restore();
                  },
                  child: Text(
                    'Restore Purchases',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: t.onSurfaceVariant,
                    ),
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

// ── Error card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colorScheme.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: t.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<SubscriptionCubit>().loadStatus();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
