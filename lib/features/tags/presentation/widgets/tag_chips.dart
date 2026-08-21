import 'package:flutter/material.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/tags/domain/entities/note_tag.dart';

/// Displays a horizontal list of tag chips with optional selection.
class TagChips extends StatelessWidget {
  const TagChips({
    super.key,
    required this.tags,
    this.selectedIds = const {},
    this.onToggle,
    this.onAdd,
  });

  final List<NoteTag> tags;
  final Set<String> selectedIds;
  final void Function(String tagId)? onToggle;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (onAdd != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ActionChip(
                avatar: Icon(Icons.add, size: 16, color: t.primary),
                label: Text(
                  'Add tag',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: t.primary,
                  ),
                ),
                backgroundColor: t.primaryContainer,
                side: BorderSide.none,
                onPressed: onAdd,
              ),
            ),
          for (final tag in tags)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(tag.name),
                selected: selectedIds.contains(tag.id),
                onSelected: onToggle != null ? (_) => onToggle!(tag.id) : null,
                selectedColor: t.primaryContainer,
                checkmarkColor: t.primary,
                backgroundColor: t.surfaceContainerLowest,
                side: BorderSide(color: t.ghostBorder(0.12)),
                labelStyle: theme.textTheme.labelMedium,
              ),
            ),
        ],
      ),
    );
  }
}
