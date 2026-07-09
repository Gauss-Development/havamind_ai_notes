import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/obsidian_gradient_button.dart';
import 'package:sample/features/auth/domain/entities/email_password_params.dart';
import 'package:sample/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

/// Single auth screen: sign-in and sign-up live on one page and switch via
/// an animated segmented toggle. Content is centered and width-constrained,
/// entrance is staggered, and every transition honors reduce-motion.
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.errorMessage,
    this.emailConfirmationSent = false,
    this.isSubmitting = false,
  });

  final String? errorMessage;
  final bool emailConfirmationSent;
  final bool isSubmitting;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  static const double _maxContentWidth = 420;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _isSignUp = false;
  var _obscurePassword = true;

  /// One-shot staggered entrance for the whole screen.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// Continuous subtle "breathing" of the brand mark.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  var _motionConfigured = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      // Reduce-motion: land on the final layout, no pulse.
      _entrance.value = 1;
    } else {
      _entrance.forward();
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitEmailPassword() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final params = EmailPasswordParams(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    final bloc = context.read<AuthBloc>();
    if (_isSignUp) {
      bloc.add(AuthEvent.signUpWithEmailPasswordPressed(params));
    } else {
      bloc.add(AuthEvent.signInWithEmailPasswordPressed(params));
    }
  }

  void _setMode({required bool signUp}) {
    if (_isSignUp == signUp) return;
    setState(() => _isSignUp = signUp);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.appTokens;
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).height < 700;

    final bannerMessage = widget.emailConfirmationSent
        ? l10n.checkEmailToConfirm
        : widget.errorMessage;
    final showBanner = bannerMessage != null && bannerMessage.isNotEmpty;
    final bannerIsInfo = widget.emailConfirmationSent;
    final loading = widget.isSubmitting;

    return Scaffold(
      backgroundColor: t.surface,
      body: Stack(
        children: [
          // Soft radial brand backdrop behind the hero area.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 420,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: t.heroBackdropGradient,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  child: AutofillGroup(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Reveal(
                          animation: _entrance,
                          interval: const Interval(0, 0.45,
                              curve: Curves.easeOutCubic),
                          child: Column(
                            children: [
                              _BrandMark(pulse: _pulse, tokens: t),
                              SizedBox(
                                height:
                                    compact ? AppSpacing.md : AppSpacing.lg,
                              ),
                              Text(
                                l10n.appTitle,
                                textAlign: TextAlign.center,
                                style:
                                    theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                l10n.signInSubtitle,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: t.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: showBanner
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.lg,
                                  ),
                                  child: _InfoBanner(
                                    message: bannerMessage,
                                    isInfo: bannerIsInfo,
                                    tokens: t,
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                        SizedBox(
                          height: compact ? AppSpacing.lg : AppSpacing.xxl,
                        ),
                        _Reveal(
                          animation: _entrance,
                          interval: const Interval(0.2, 0.65,
                              curve: Curves.easeOutCubic),
                          child: _AuthModeToggle(
                            isSignUp: _isSignUp,
                            enabled: !loading,
                            signInLabel: l10n.signInWithEmail,
                            signUpLabel: l10n.signUp,
                            tokens: t,
                            onChanged: (signUp) => _setMode(signUp: signUp),
                          ),
                        ),
                        SizedBox(
                          height: compact ? AppSpacing.lg : AppSpacing.xl,
                        ),
                        _Reveal(
                          animation: _entrance,
                          interval: const Interval(0.35, 0.8,
                              curve: Curves.easeOutCubic),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  enabled: !loading,
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: t.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: l10n.email,
                                    prefixIcon:
                                        const Icon(Icons.mail_outline_rounded),
                                  ),
                                  validator: (value) {
                                    final email = value?.trim() ?? '';
                                    if (email.isEmpty) {
                                      return l10n.emailRequired;
                                    }
                                    if (!email.contains('@')) {
                                      return l10n.invalidEmail;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.base),
                                TextFormField(
                                  controller: _passwordController,
                                  enabled: !loading,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) =>
                                      _submitEmailPassword(),
                                  autofillHints: [
                                    if (_isSignUp)
                                      AutofillHints.newPassword
                                    else
                                      AutofillHints.password,
                                  ],
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: t.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: l10n.password,
                                    prefixIcon:
                                        const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? l10n.showPassword
                                          : l10n.hidePassword,
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    final password = value ?? '';
                                    if (password.isEmpty) {
                                      return l10n.passwordRequired;
                                    }
                                    if (password.length < 6) {
                                      return l10n.passwordTooShort;
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: compact ? AppSpacing.lg : AppSpacing.xl,
                        ),
                        _Reveal(
                          animation: _entrance,
                          interval: const Interval(0.5, 1,
                              curve: Curves.easeOutCubic),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Cross-fade the CTA when the mode flips.
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child: AppGradientButton(
                                  key: ValueKey(_isSignUp),
                                  onPressed:
                                      loading ? null : _submitEmailPassword,
                                  isLoading: loading,
                                  expand: true,
                                  icon: _isSignUp
                                      ? Icons.person_add_rounded
                                      : Icons.login_rounded,
                                  label: _isSignUp
                                      ? l10n.signUp
                                      : l10n.signInWithEmail,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              // No-Divider rule: tonal text instead of lines.
                              Text(
                                l10n.orContinueWith,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: t.onSurfaceVariant,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _SocialIconButton(
                                    semanticLabel: l10n.signInWithGoogle,
                                    logo: const _GoogleLogo(size: 24),
                                    tokens: t,
                                    onPressed: loading
                                        ? null
                                        : () => context.read<AuthBloc>().add(
                                              const AuthEvent
                                                  .signInWithGooglePressed(),
                                            ),
                                  ),
                                  const SizedBox(width: AppSpacing.lg),
                                  _SocialIconButton(
                                    semanticLabel: l10n.signInWithApple,
                                    logo: Icon(
                                      Icons.apple_rounded,
                                      size: 30,
                                      color: t.onSurface,
                                    ),
                                    tokens: t,
                                    onPressed: loading
                                        ? null
                                        : () => context.read<AuthBloc>().add(
                                              const AuthEvent
                                                  .signInWithApplePressed(),
                                            ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient-ringed pulsing brand mark.
class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.pulse, required this.tokens});

  final Animation<double> pulse;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 1.05).animate(
        CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 84,
        height: 84,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: tokens.primaryGradient,
          boxShadow: tokens.vibrantGlow,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tokens.surface,
          ),
          child: Icon(Icons.mic_rounded, size: 38, color: tokens.primary),
        ),
      ),
    );
  }
}

/// Segmented sign-in / sign-up switch with a sliding gradient pill.
class _AuthModeToggle extends StatelessWidget {
  const _AuthModeToggle({
    required this.isSignUp,
    required this.enabled,
    required this.signInLabel,
    required this.signUpLabel,
    required this.tokens,
    required this.onChanged,
  });

  final bool isSignUp;
  final bool enabled;
  final String signInLabel;
  final String signUpLabel;
  final AppTokens tokens;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTapTarget.minSize + 4,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: tokens.surfaceContainer,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusFull),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment:
                isSignUp ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: tokens.primaryGradient,
                  borderRadius:
                      BorderRadius.circular(ObsidianUiTokens.radiusFull),
                  boxShadow: tokens.elevationMd,
                ),
              ),
            ),
          ),
          Row(
            children: [
              _ToggleSegment(
                label: signInLabel,
                selected: !isSignUp,
                enabled: enabled,
                tokens: tokens,
                onTap: () => onChanged(false),
              ),
              _ToggleSegment(
                label: signUpLabel,
                selected: isSignUp,
                enabled: enabled,
                tokens: tokens,
                onTap: () => onChanged(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final AppTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusFull),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              style: theme.textTheme.titleSmall!.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected
                    ? tokens.onPrimaryButton
                    : tokens.onSurfaceVariant,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.message,
    required this.isInfo,
    required this.tokens,
  });

  final String message;
  final bool isInfo;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isInfo
            ? tokens.primaryContainer
            : theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            isInfo
                ? Icons.mark_email_read_outlined
                : Icons.error_outline_rounded,
            size: 18,
            color: isInfo
                ? tokens.primary
                : theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isInfo
                    ? tokens.primary
                    : theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular icon-only social sign-in button. The provider name lives in the
/// tooltip and semantics label so screen readers still announce it.
class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({
    required this.semanticLabel,
    required this.logo,
    required this.tokens,
    required this.onPressed,
  });

  static const double _size = 60;

  final String semanticLabel;
  final Widget logo;
  final AppTokens tokens;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          opacity: disabled ? 0.5 : 1,
          child: Material(
            color: tokens.surfaceContainerLowest,
            shape: CircleBorder(
              side: BorderSide(color: tokens.ghostBorder(0.4), width: 1.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: _size,
                height: _size,
                child: Center(child: logo),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The four-color Google "G", drawn to stay crisp at any size without a
/// bundled asset.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);
  static const _blue = Color(0xFF4285F4);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.22;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    double deg(double d) => d * 3.1415926535 / 180;

    // Ring segments, clockwise from 3 o'clock. The gap at -45°..0° is the
    // G's opening; the bar below closes it visually.
    canvas.drawArc(rect, deg(0), deg(50), false, paint..color = _blue);
    canvas.drawArc(rect, deg(50), deg(100), false, paint..color = _green);
    canvas.drawArc(rect, deg(150), deg(60), false, paint..color = _yellow);
    canvas.drawArc(rect, deg(210), deg(105), false, paint..color = _red);

    // Horizontal bar of the G.
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - stroke / 2,
        radius + stroke / 2,
        stroke,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}

/// Fade + slide reveal driven by a slice of the shared entrance animation.
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.animation,
    required this.interval,
    required this.child,
  });

  final Animation<double> animation;
  final Interval interval;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: interval);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
