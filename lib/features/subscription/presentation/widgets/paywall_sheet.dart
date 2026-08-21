import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/subscription/presentation/cubit/subscription_cubit.dart';
import 'package:sample/features/subscription/presentation/widgets/paywall_content.dart';

/// Shows the paywall as a draggable bottom sheet. Use this when a user
/// hits a usage limit mid-flow — feels less interruptive than a full
/// page navigation.
///
/// The caller must have a [SubscriptionCubit] available in the widget
/// tree (it's provided globally in this app).
Future<void> showPaywallSheet(
  BuildContext context, {
  bool limitReached = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (sheetContext) {
      return BlocProvider.value(
        value: context.read<SubscriptionCubit>(),
        child: _PaywallSheetBody(limitReached: limitReached),
      );
    },
  );
}

class _PaywallSheetBody extends StatelessWidget {
  const _PaywallSheetBody({required this.limitReached});

  final bool limitReached;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(ObsidianUiTokens.radiusXxl),
            ),
          ),
          child: Column(
            children: [
              // Drag handle.
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.onSurfaceVariant.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(
                    ObsidianUiTokens.radiusFull,
                  ),
                ),
              ),
              // Close button row.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: t.onSurfaceVariant,
                      ),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PaywallContent(
                  compact: true,
                  scrollController: scrollController,
                  headline: limitReached
                      ? 'You\'ve used all your minutes'
                      : null,
                  subhead: limitReached
                      ? 'Upgrade to keep capturing ideas without interruption.'
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
