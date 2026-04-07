import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/subscription/domain/entities/subscription_status.dart';

enum SubscriptionSheetAction { manageSubscription, changePlan, customerCenter }

Future<SubscriptionSheetAction?> showSubscriptionDetailSheet({
  required BuildContext context,
  required SubscriptionStatus status,
}) {
  return showModalBottomSheet<SubscriptionSheetAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SubscriptionDetailSheet(status: status),
  );
}

class _SubscriptionDetailSheet extends StatelessWidget {
  const _SubscriptionDetailSheet({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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

          // ── Header ──
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [t.primary, t.primary.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Havamind Voice Pro',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${status.planDisplayName} plan',
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

          // ── Billing issue warning ──
          if (status.hasBillingIssue) ...[
            _WarningBanner(
              icon: Icons.warning_amber_rounded,
              text: 'There is a billing issue with your subscription. '
                  'Please update your payment method to avoid interruption.',
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.base),
          ],

          // ── Cancelled notice ──
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

          // ── Trial notice ──
          if (status.isTrial) ...[
            _WarningBanner(
              icon: Icons.star_outline_rounded,
              text: 'You are currently on a free trial. '
                  '${status.expirationDate != null ? 'Trial ends ${_formatDateLong(status.expirationDate!)}.' : ''}',
              color: t.secondary,
            ),
            const SizedBox(height: AppSpacing.base),
          ],

          // ── Details card ──
          Container(
            decoration: BoxDecoration(
              color: t.surfaceContainerLow,
              borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
            ),
            child: Column(
              children: [
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
                  const _DetailRow(label: 'Period', value: 'Introductory offer'),
                if (status.isSandbox)
                  _DetailRow(
                    label: 'Environment',
                    value: 'Sandbox (testing)',
                    valueColor: t.warning,
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Actions ──
          if (!status.isLifetime) ...[
            _ActionTile(
              icon: Icons.swap_horiz_rounded,
              label: 'Change Plan',
              subtitle: 'Switch between monthly and yearly',
              onTap: () => Navigator.pop(context, SubscriptionSheetAction.changePlan),
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
          const SizedBox(height: AppSpacing.base),
        ],
      ),
    );
  }

  String _formatDateLong(DateTime date) {
    return DateFormat.yMMMd().format(date.toLocal());
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

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

// ── Warning banner ────────────────────────────────────────────────────────────

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

// ── Detail row ────────────────────────────────────────────────────────────────

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
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? t.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action tile ───────────────────────────────────────────────────────────────

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
