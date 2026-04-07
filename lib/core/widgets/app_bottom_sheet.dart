import 'package:flutter/material.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';

/// Shows a modal bottom sheet with a text field for editing a value.
///
/// Returns the trimmed new value, or `null` if cancelled / empty.
Future<String?> showEditBottomSheet({
  required BuildContext context,
  required String title,
  String? initialValue,
  String hintText = 'Enter text',
  int maxLines = 6,
  int minLines = 3,
}) async {
  final controller = TextEditingController(text: initialValue ?? '');
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      final t = ctx.obsidian;
      final theme = Theme.of(ctx);
      final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;

      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
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
            const SizedBox(height: AppSpacing.base),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.base),
            TextField(
              controller: controller,
              maxLines: maxLines,
              minLines: minLines,
              autofocus: true,
              decoration: InputDecoration(hintText: hintText),
            ),
            const SizedBox(height: AppSpacing.base),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pop(ctx, controller.text.trim()),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  final trimmed = result?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
