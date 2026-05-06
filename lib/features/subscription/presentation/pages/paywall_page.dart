import 'package:flutter/material.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/subscription/presentation/widgets/paywall_content.dart';

/// Full-screen paywall — used when user manually requests upgrade
/// (e.g. from the subscription status card).
class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;

    return Scaffold(
      backgroundColor: t.surface,
      appBar: AppBar(
        backgroundColor: t.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Close',
        ),
        title: const SizedBox.shrink(),
      ),
      body: const SafeArea(child: PaywallContent()),
    );
  }
}
