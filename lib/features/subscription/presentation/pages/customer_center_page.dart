import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/subscription/presentation/cubit/subscription_cubit.dart';

/// Full-screen host for RevenueCat [CustomerCenterView] with app chrome and
/// Obsidian styling. Replaces the default modal `presentCustomerCenter` flow.
class CustomerCenterPage extends StatelessWidget {
  const CustomerCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: t.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.sm,
              top + AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Material(
                  color: t.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(
                    ObsidianUiTokens.radiusFull,
                  ),
                  child: IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: t.onSurface,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscription & billing',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Plans, payments, and renewals',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: t.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _IntroPanel(t: t, theme: theme),
          ),

          const SizedBox(height: AppSpacing.md),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: t.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(
                    ObsidianUiTokens.radiusLg,
                  ),
                  border: Border.all(
                    color: t.outlineVariant.withValues(alpha: 0.14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomerCenterView(
                  shouldShowCloseButton: false,
                  onDismiss: () => Navigator.of(context).maybePop(),
                  onRestoreCompleted: (_) {
                    context.read<SubscriptionCubit>().loadStatus();
                  },
                  onPromotionalOfferSucceeded:
                      (customerInfo, transaction, offerId) {
                        context.read<SubscriptionCubit>().loadStatus();
                      },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPanel extends StatelessWidget {
  const _IntroPanel({required this.t, required this.theme});

  final ObsidianUiTokens t;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: t.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
        border: Border.all(color: t.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: t.primary, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Manage your plan, fix payment issues, or request help. '
              'Some changes are processed by the App Store or Google Play and may take a few minutes.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: t.onSurface,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
