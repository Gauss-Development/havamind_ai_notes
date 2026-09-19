import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sample/core/config/environment_config.dart';
import 'package:sample/core/constants/audio_notes_constants.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/subscription/domain/entities/subscription_status.dart';
import 'package:sample/features/subscription/presentation/cubit/subscription_cubit.dart';
import 'package:sample/features/subscription/presentation/cubit/subscription_state.dart';
import 'package:sample/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared paywall body. Hosted inside [PaywallPage] (full-screen) or
/// inside [showPaywallSheet] (bottom sheet). Reads the active
/// [SubscriptionCubit] from the surrounding [BlocProvider].
class PaywallContent extends StatefulWidget {
  const PaywallContent({
    super.key,
    this.headline,
    this.subhead,
    this.compact = false,
    this.scrollController,
  });

  /// Override the default hero title (e.g. "You've hit your limit").
  final String? headline;

  /// Override the default hero subtitle.
  final String? subhead;

  /// Bottom-sheet variant — smaller hero, denser spacing.
  final bool compact;

  /// Optional external controller (e.g. from DraggableScrollableSheet).
  /// When supplied, this widget uses it instead of creating its own —
  /// avoids nested-scroll issues that block drag-to-expand.
  final ScrollController? scrollController;

  @override
  State<PaywallContent> createState() => _PaywallContentState();
}

class _PaywallContentState extends State<PaywallContent> {
  Offerings? _offerings;
  Object? _loadError;
  bool _loading = true;

  _BillingPeriod _billing = _BillingPeriod.annual;
  _PaywallTier _selectedTier = _PaywallTier.pro;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final offerings = await context.read<SubscriptionCubit>().loadOfferings();
    if (!mounted) return;
    setState(() {
      _offerings = offerings;
      _loading = false;
      if (offerings == null) {
        _loadError = 'Could not load plans. Please try again.';
      }
      // Default selected period: annual if available, else monthly.
      final hasAnnual = _packagesFor(
        offerings,
        _BillingPeriod.annual,
      ).isNotEmpty;
      _billing = hasAnnual ? _BillingPeriod.annual : _BillingPeriod.monthly;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;

    if (_loading) {
      return SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator(color: t.primary)),
      );
    }
    if (_loadError != null) {
      return _ErrorState(
        message: _loadError!.toString(),
        onRetry: () {
          setState(() {
            _loading = true;
            _loadError = null;
          });
          _load();
        },
      );
    }

    final monthlyPkgs = _packagesFor(_offerings, _BillingPeriod.monthly);
    final annualPkgs = _packagesFor(_offerings, _BillingPeriod.annual);
    final hasBoth = monthlyPkgs.isNotEmpty && annualPkgs.isNotEmpty;

    final visiblePkgs =
        _billing == _BillingPeriod.annual && annualPkgs.isNotEmpty
        ? annualPkgs
        : monthlyPkgs;

    final basicPkg = _packageForTier(visiblePkgs, _PaywallTier.basic);
    final proPkg = _packageForTier(visiblePkgs, _PaywallTier.pro);

    final state = context.watch<SubscriptionCubit>().state;
    final currentTier = state is SubscriptionLoaded
        ? state.status.tier
        : SubscriptionTier.free;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        widget.compact ? AppSpacing.md : AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            title: widget.headline ?? l10n.paywallTitle,
            subtitle: widget.subhead ?? l10n.paywallSubtitle,
            compact: widget.compact,
          ),
          SizedBox(height: widget.compact ? AppSpacing.lg : AppSpacing.xl),
          const _ValuePropList(),
          const SizedBox(height: AppSpacing.xl),
          if (hasBoth) ...[
            _BillingToggle(
              value: _billing,
              annualSavings: _annualSavings(monthlyPkgs, annualPkgs),
              onChanged: (v) => setState(() => _billing = v),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _TierCard(
            tier: _PaywallTier.free,
            isSelected: false,
            isCurrent: currentTier == SubscriptionTier.free,
            package: null,
            billing: _billing,
            onTap: null,
          ),
          if (basicPkg != null) ...[
            const SizedBox(height: AppSpacing.md),
            _TierCard(
              tier: _PaywallTier.basic,
              isSelected: _selectedTier == _PaywallTier.basic,
              isCurrent: currentTier == SubscriptionTier.basic,
              package: basicPkg,
              billing: _billing,
              onTap: () => setState(() => _selectedTier = _PaywallTier.basic),
            ),
          ],
          if (proPkg != null) ...[
            const SizedBox(height: AppSpacing.md),
            _TierCard(
              tier: _PaywallTier.pro,
              isSelected: _selectedTier == _PaywallTier.pro,
              isCurrent: currentTier == SubscriptionTier.pro,
              package: proPkg,
              billing: _billing,
              onTap: () => setState(() => _selectedTier = _PaywallTier.pro),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _ContinueButton(
            package: _selectedTier == _PaywallTier.basic ? basicPkg : proPkg,
            isPurchasing: _purchasing,
            onPurchase: _onContinue,
          ),
          const SizedBox(height: AppSpacing.md),
          _FooterLinks(onRestore: _onRestore),
        ],
      ),
    );
  }

  Future<void> _onContinue(Package package) async {
    // Synchronous guard before the first `await` — without this, two quick
    // taps can both pass the `_purchasing == false` check (the flag is only
    // observed after `setState` schedules a rebuild) and fire parallel
    // purchases in the cubit.
    if (_purchasing) return;
    _purchasing = true;
    setState(() {});
    final outcome = await context.read<SubscriptionCubit>().purchase(package);
    if (!mounted) return;
    setState(() => _purchasing = false);

    switch (outcome) {
      case PurchaseSuccess():
        Navigator.of(context).maybePop();
      case PurchaseCancelled():
        // Silent — user dismissed Apple/Google sheet.
        break;
      case PurchaseError(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _onRestore() async {
    setState(() => _purchasing = true);
    await context.read<SubscriptionCubit>().restore();
    if (!mounted) return;
    setState(() => _purchasing = false);
    final state = context.read<SubscriptionCubit>().state;
    if (!mounted) return;
    if (state is SubscriptionLoaded && state.status.isActive) {
      Navigator.of(context).maybePop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active purchases to restore.')),
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  List<Package> _packagesFor(Offerings? offerings, _BillingPeriod period) {
    final current = offerings?.current;
    if (current == null) return const [];
    return current.availablePackages
        .where((p) => _periodOf(p) == period)
        .toList();
  }

  /// Billing period of a package, classified by the store product rather than
  /// `Package.packageType`. A two-tier offering (Basic + Pro, each monthly and
  /// annual) cannot use the reserved `$rc_monthly`/`$rc_annual` identifiers —
  /// RevenueCat allows only one package per duration in an offering, so the
  /// extra tier is forced onto a custom identifier and reports
  /// `packageType == custom`. We therefore read the reserved types when present
  /// (single-tier offerings) and otherwise fall back to the product-id keyword
  /// convention used by `_inferPeriod` in SubscriptionRepositoryImpl.
  _BillingPeriod? _periodOf(Package p) {
    switch (p.packageType) {
      case PackageType.monthly:
        return _BillingPeriod.monthly;
      case PackageType.annual:
        return _BillingPeriod.annual;
      default:
        break;
    }
    final id = p.storeProduct.identifier.toLowerCase();
    if (id.contains('year') || id.contains('annual')) {
      return _BillingPeriod.annual;
    }
    if (id.contains('month')) return _BillingPeriod.monthly;
    return null;
  }

  Package? _packageForTier(List<Package> packages, _PaywallTier tier) {
    if (packages.isEmpty) return null;
    // Prefer match by product ID keyword.
    for (final p in packages) {
      final id = p.storeProduct.identifier.toLowerCase();
      if (tier == _PaywallTier.pro && id.contains('pro')) return p;
      if (tier == _PaywallTier.basic && id.contains('basic')) return p;
    }
    // Single-tier offerings (Play/App Store production) have one package per
    // period. Map it to Pro so Subscribe is bound to a real package. Cheap vs
    // expensive is only a Basic/Pro split when both products exist.
    if (packages.length == 1) {
      return tier == _PaywallTier.pro ? packages.first : null;
    }
    final sorted = [...packages]
      ..sort((a, b) => a.storeProduct.price.compareTo(b.storeProduct.price));
    if (tier == _PaywallTier.basic) return sorted.first;
    if (tier == _PaywallTier.pro) return sorted.last;
    return null;
  }

  /// Returns "Save 30%" if annual cheaper than 12× monthly, else null.
  String? _annualSavings(List<Package> monthly, List<Package> annual) {
    if (monthly.isEmpty || annual.isEmpty) return null;
    // Compare for the same tier (Pro by default, fall back to first).
    final m = _packageForTier(monthly, _PaywallTier.pro) ?? monthly.first;
    final a = _packageForTier(annual, _PaywallTier.pro) ?? annual.first;
    final monthlyTotal = m.storeProduct.price * 12;
    if (monthlyTotal <= 0) return null;
    final saved = (1 - (a.storeProduct.price / monthlyTotal)) * 100;
    if (saved < 5) return null;
    return 'Save ${saved.round()}%';
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: compact ? AppSpacing.lg : AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.primary.withValues(alpha: 0.18),
            t.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: t.primary.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusFull),
            ),
            child: Text(
              'HAVA MIND PRO',
              style: theme.textTheme.labelSmall?.copyWith(
                color: t.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: t.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValuePropList extends StatelessWidget {
  const _ValuePropList();

  List<(IconData, String, String)> _items(AppLocalizations l10n) => [
    (
      Icons.auto_awesome_rounded,
      l10n.paywallValueThesisTitle,
      l10n.paywallValueThesisBody,
    ),
    (
      Icons.phone_callback_rounded,
      l10n.paywallValueDebriefTitle,
      l10n.paywallValueDebriefBody,
    ),
    (
      Icons.forum_outlined,
      l10n.paywallValueNextTitle,
      l10n.paywallValueNextBody,
    ),
    (
      Icons.mail_outline_rounded,
      l10n.paywallValueArtifactTitle,
      l10n.paywallValueArtifactBody,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final items = _items(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.paywallEverythingYouGet,
          style: theme.textTheme.titleSmall?.copyWith(
            color: t.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final (icon, headline, body) in items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: t.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(
                    ObsidianUiTokens.radiusMd,
                  ),
                ),
                child: Icon(icon, color: t.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: t.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({
    required this.value,
    required this.onChanged,
    this.annualSavings,
  });

  final _BillingPeriod value;
  final ValueChanged<_BillingPeriod> onChanged;
  final String? annualSavings;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);

    Widget option(_BillingPeriod period, String label, {String? trailing}) {
      final selected = period == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(period),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: selected ? t.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXl),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: selected ? t.onPrimaryButton : t.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? t.onPrimaryButton.withValues(alpha: 0.20)
                          : t.secondary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(
                        ObsidianUiTokens.radiusFull,
                      ),
                    ),
                    child: Text(
                      trailing,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: selected ? t.onPrimaryButton : t.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXl),
      ),
      child: Row(
        children: [
          option(_BillingPeriod.monthly, 'Monthly'),
          option(_BillingPeriod.annual, 'Annual', trailing: annualSavings),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.isSelected,
    required this.isCurrent,
    required this.package,
    required this.billing,
    required this.onTap,
  });

  final _PaywallTier tier;
  final bool isSelected;
  final bool isCurrent;
  final Package? package;
  final _BillingPeriod billing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);
    final spec = _tierSpec(tier, AppLocalizations.of(context)!);

    final disabled = onTap == null;
    final bgColor = isSelected
        ? t.primary.withValues(alpha: 0.10)
        : t.surfaceContainer;
    final glow = isSelected
        ? <BoxShadow>[
            BoxShadow(
              color: t.primary.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: Offset.zero,
            ),
          ]
        : <BoxShadow>[];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXl),
          boxShadow: glow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        spec.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: disabled ? t.onSurfaceVariant : t.onSurface,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: t.onSurfaceVariant.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(
                              ObsidianUiTokens.radiusFull,
                            ),
                          ),
                          child: Text(
                            'CURRENT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: t.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _PriceLabel(
                  package: package,
                  billing: billing,
                  isFree: tier == _PaywallTier.free,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              spec.tagline,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: t.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final feature in spec.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: isSelected ? t.primary : t.secondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        feature,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: t.onSurface,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PriceLabel extends StatelessWidget {
  const _PriceLabel({
    required this.package,
    required this.billing,
    required this.isFree,
  });

  final Package? package;
  final _BillingPeriod billing;
  final bool isFree;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);

    if (isFree) {
      return Text(
        'Free',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: t.onSurfaceVariant,
        ),
      );
    }

    if (package == null) {
      return Text(
        '—',
        style: theme.textTheme.titleLarge?.copyWith(color: t.onSurfaceVariant),
      );
    }

    final price = package!.storeProduct.priceString;
    final perLabel = billing == _BillingPeriod.annual ? '/ year' : '/ month';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          price,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          perLabel,
          style: theme.textTheme.bodySmall?.copyWith(color: t.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.package,
    required this.isPurchasing,
    required this.onPurchase,
  });

  final Package? package;
  final bool isPurchasing;
  final Future<void> Function(Package) onPurchase;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);

    final enabled = package != null && !isPurchasing;
    final price = package?.storeProduct.priceString;
    final label = price == null ? 'Continue' : 'Start with $price';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXl),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: t.primary.withValues(alpha: 0.32),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [],
      ),
      child: FilledButton(
        onPressed: enabled ? () => onPurchase(package!) : null,
        style: FilledButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: t.onPrimaryButton,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXl),
          ),
          textStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        child: isPurchasing
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: t.onPrimaryButton,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks({required this.onRestore});

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);

    final cfg = EnvironmentConfig.instance;
    final privacy = cfg.privacyPolicyUrl.trim();
    final terms = cfg.termsOfServiceUrl.trim();

    return Column(
      children: [
        TextButton(
          onPressed: onRestore,
          child: Text(
            'Restore purchases',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: t.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Subscription auto-renews. Cancel anytime in your account settings.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: t.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        if (privacy.isNotEmpty || terms.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (privacy.isNotEmpty)
                _LegalTextLink(label: 'Privacy Policy', url: privacy),
              if (privacy.isNotEmpty && terms.isNotEmpty)
                Text(
                  '  ·  ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: t.onSurfaceVariant,
                  ),
                ),
              if (terms.isNotEmpty)
                _LegalTextLink(label: 'Terms of Use', url: terms),
            ],
          ),
        ],
      ],
    );
  }
}

class _LegalTextLink extends StatelessWidget {
  const _LegalTextLink({required this.label, required this.url});

  final String label;
  final String url;

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _open,
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: t.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: t.onSurfaceVariant, size: 36),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: t.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tier specs
// ─────────────────────────────────────────────────────────────────────────

enum _BillingPeriod { monthly, annual }

enum _PaywallTier { free, basic, pro }

class _TierSpec {
  const _TierSpec({
    required this.name,
    required this.tagline,
    required this.features,
  });

  final String name;
  final String tagline;
  final List<String> features;
}

_TierSpec _tierSpec(_PaywallTier tier, AppLocalizations l10n) {
  switch (tier) {
    case _PaywallTier.free:
      return _TierSpec(
        name: l10n.paywallTierFree,
        tagline: l10n.paywallTagFree,
        features: [
          l10n.paywallMinutesPerMonth(kFreeMonthlyLimitSeconds ~/ 60),
          l10n.paywallFeatureThesisDebriefs,
          l10n.paywallFeatureWeeklyArtifact,
        ],
      );
    case _PaywallTier.basic:
      return _TierSpec(
        name: l10n.paywallTierBasic,
        tagline: l10n.paywallTagBasic,
        features: [
          l10n.paywallMinutesPerMonth(kBasicMonthlyLimitSeconds ~/ 60),
          l10n.paywallFeatureThesisFromDebriefs,
          l10n.paywallFeatureSearchTags,
        ],
      );
    case _PaywallTier.pro:
      return _TierSpec(
        name: l10n.paywallTierPro,
        tagline: l10n.paywallTagPro,
        features: [
          l10n.paywallMinutesPerMonth(kProMonthlyLimitSeconds ~/ 60),
          l10n.paywallFeatureEverythingBasic,
          l10n.paywallFeatureThesisVersions,
          l10n.paywallFeatureArtifactAndScript,
        ],
      );
  }
}
