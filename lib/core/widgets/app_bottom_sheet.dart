import 'package:flutter/material.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/obsidian_gradient_button.dart';

/// Modal bottom sheet for inline text editing.
///
/// Returns the trimmed input, or `null` if the user cancels or submits an
/// empty string. Uses the design-system [AppTokens.radiusXxl] hero radius,
/// the gradient primary CTA, and 48dp tap targets on every action.
Future<String?> showEditBottomSheet({
  required BuildContext context,
  required String title,
  String? initialValue,
  String hintText = 'Enter text',
  int maxLines = 6,
  int minLines = 3,
  String saveLabel = 'Save',
  String cancelLabel = 'Cancel',
}) async {
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _EditSheet(
      title: title,
      hintText: hintText,
      initialValue: initialValue ?? '',
      maxLines: maxLines,
      minLines: minLines,
      saveLabel: saveLabel,
      cancelLabel: cancelLabel,
    ),
  );

  final trimmed = result?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({
    required this.title,
    required this.hintText,
    required this.initialValue,
    required this.maxLines,
    required this.minLines,
    required this.saveLabel,
    required this.cancelLabel,
  });

  final String title;
  final String hintText;
  final String initialValue;
  final int maxLines;
  final int minLines;
  final String saveLabel;
  final String cancelLabel;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    // `AnimatedPadding` follows the keyboard rise/fall smoothly. The
    // sheet body keeps a fixed inner padding so the layout doesn't jitter
    // every time the autocorrect bar appears/disappears.
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: t.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusXxl),
          ),
          boxShadow: t.elevationLg,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
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
                    color: t.onSurfaceVariant.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(AppTokens.radiusXs),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(widget.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.base),
              TextField(
                controller: _controller,
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                autofocus: true,
                decoration: InputDecoration(hintText: widget.hintText),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppGradientButton(
                      onPressed: () => Navigator.pop(context),
                      label: widget.cancelLabel,
                      variant: AppButtonVariant.outlined,
                      expand: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppGradientButton(
                      onPressed: () =>
                          Navigator.pop(context, _controller.text.trim()),
                      label: widget.saveLabel,
                      expand: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
