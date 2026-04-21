import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/subscription/domain/entities/subscription_status.dart';
import 'package:sample/features/subscription/domain/entities/usage_info.dart';

enum SubscriptionSheetAction { manageSubscription, changePlan, customerCenter }

Future<SubscriptionSheetAction?> showSubscriptionDetailSheet({
  required BuildContext context,
  required SubscriptionStatus status,
  UsageInfo? usageInfo,
  String? accountDisplayName,
  String? accountEmail,
  DateTime? memberSince,
}) {
  return showModalBottomSheet<SubscriptionSheetAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SubscriptionDetailSheet(
      status: status,
      usageInfo: usageInfo,
      accountDisplayName: accountDisplayName,
      accountEmail: accountEmail,
      memberSince: memberSince,
    ),
  );
}

class _SubscriptionDetailSheet extends StatelessWidget {
  const _SubscriptionDetailSheet({
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
    final bottom = MediaQuery.paddingOf(context).bottom;
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

    final primaryLabel = accountDisplayName?.trim();
    final emailLabel = accountEmail?.trim();
    final hasAccountBlock = (primaryLabel != null && primaryLabel.isNotEmpty) ||
        (emailLabel != null && emailLabel.isNotEmpty) ||
        memberSince != null;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.onSurfaceVariant.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: tierGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tierIcon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.marketingProductName,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${status.planDisplayName} billing',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: t.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            if (hasAccountBlock) ...[
              _SectionTitle(text: 'Your account'),
              Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: t.surfaceContainerLow,
                  borderRadius:
                      BorderRadius.circular(ObsidianUiTokens.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (primaryLabel != null && primaryLabel.isNotEmpty)
                      Text(
                        primaryLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (emailLabel != null &&
                        emailLabel.isNotEmpty &&
                        emailLabel != primaryLabel) ...[
                      if (primaryLabel != null && primaryLabel.isNotEmpty)
                        const SizedBox(height: 4),
                      Text(
                        emailLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: t.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (memberSince != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Member since ${_formatMonthYear(memberSince!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: t.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            if (usageInfo != null) ...[
              _SectionTitle(text: 'Recording quota'),
              Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: t.surfaceContainerLow,
                  borderRadius:
                      BorderRadius.circular(ObsidianUiTokens.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${usageInfo!.usedMinutes} / ${usageInfo!.limitMinutes} min',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${usageInfo!.remainingMinutes} min left',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: usageInfo!.isExhausted
                                ? theme.colorScheme.error
                                : t.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: usageInfo!.usageRatio.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor:
                            t.outlineVariant.withValues(alpha: 0.2),
                        color: usageInfo!.isExhausted
                            ? theme.colorScheme.error
                            : t.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Counts transcribed audio for the current billing period (${_periodRange(usageInfo!)}).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: t.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            if (status.hasBillingIssue) ...[
              _WarningBanner(
                icon: Icons.warning_amber_rounded,
                text: 'There is a billing issue with your subscription. '
                    'Please update your payment method to avoid interruption.',
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.base),
            ],

            if (status.isCancelled && status.expirationDate != null) ...[
              _WarningBanner(
                icon: Icons.info_outline_rounded,
                text: 'Your subscription has been cancelled. '
                    'You retain access until '
                    '${_formatDateLong(status.expirationDate!)}.',
                color: t.warning,
              ),
              const SizedBox(height: AppSpacing.base),
            ],

            if (status.isTrial) ...[
              _WarningBanner(
                icon: Icons.star_outline_rounded,
                text: 'You are currently on a free trial. '
                    '${status.expirationDate != null ? 'Trial ends ${_formatDateLong(status.expirationDate!)}.' : ''}',
                color: t.secondary,
              ),
              const SizedBox(height: AppSpacing.base),
            ],

            ..._subscriptionDetailSection(t),

            const SizedBox(height: AppSpacing.xl),

            if (!status.isLifetime) ...[
              _ActionTile(
                icon: Icons.swap_horiz_rounded,
                label: 'Change Plan',
                subtitle: 'Switch between monthly and yearly',
                onTap: () =>
                    Navigator.pop(context, SubscriptionSheetAction.changePlan),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            _ActionTile(
              icon: Icons.manage_accounts_rounded,
              label: 'Manage Subscription',
              subtitle: status.isCancelled
                  ? 'Resubscribe or update payment'
                  : 'Cancel, update payment, or get help',
              onTap: () =>
                  Navigator.pop(context, SubscriptionSheetAction.customerCenter),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _subscriptionDetailSection(ObsidianUiTokens t) {
    final rows = <Widget>[
      if (status.expirationDate != null && !status.isLifetime)
        _DetailRow(
          label: status.willRenew ? 'Next renewal' : 'Expires',
          value: _formatDateLong(status.expirationDate!),
        ),
      if (status.isLifetime)
        const _DetailRow(label: 'Duration', value: 'Forever'),
      if (status.originalPurchaseDate != null)
        _DetailRow(
          label: 'Subscribed since',
          value: _formatDateLong(status.originalPurchaseDate!),
        ),
      if (status.store != SubscriptionStore.unknown)
        _DetailRow(
          label: 'Purchased via',
          value: status.storeDisplayName,
        ),
      if (status.isTrial)
        const _DetailRow(label: 'Period', value: 'Free trial'),
      if (status.isIntroOffer)
        const _DetailRow(
          label: 'Period',
          value: 'Introductory offer',
        ),
      if (status.isSandbox)
        _DetailRow(
          label: 'Environment',
          value: 'Sandbox (testing)',
          valueColor: t.warning,
        ),
    ];
    if (rows.isEmpty) return const [];
    return [
      _SectionTitle(text: 'Subscription'),
      _DetailCard(t: t, children: rows),
    ];
  }

  String _formatDateLong(DateTime date) {
    return DateFormat.yMMMd().format(date.toLocal());
  }

  String _formatMonthYear(DateTime date) {
    return DateFormat.yMMMM().format(date.toLocal());
  }

  String _periodRange(UsageInfo u) {
    final a = DateFormat.MMMd().format(u.periodStart.toLocal());
    final b = DateFormat.MMMd().format(u.periodEnd.toLocal());
    return '$a – $b';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 0.85,
          fontWeight: FontWeight.w700,
          color: t.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.t,
    required this.children,
  });

  final ObsidianUiTokens t;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(
          Divider(
            height: 1,
            thickness: 1,
            color: t.outlineVariant.withValues(alpha: 0.12),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: t.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

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
    if (status.hasBillingIssue) return ('Billing Issue', theme.colorScheme.error);
    if (status.isTrial) return ('Trial', t.secondary);
    if (status.isCancelled) return ('Cancelled', t.warning);
    return ('Active', t.primary);
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: t.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: t.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? t.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    return Material(
      color: t.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: t.surfaceContainerHigh,
                  borderRadius:
                      BorderRadius.circular(ObsidianUiTokens.radiusSm),
                ),
                child: Icon(icon, size: 20, color: t.onSurfaceVariant),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: t.onSurfaceVariant,
                      ),
                    ),
                  ],
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
