import 'package:flutter/material.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/presentation/utils/audio_note_status_ui.dart';

/// Note row used in lists (Recents, Favorites, Search results).
///
/// Surface: `surfaceContainerLowest` with `radiusLg` rounding and a 1px
/// brand-tinted ghost border. Status is communicated through both color
/// (semantic — see [audioNoteStatusColor]) and shape (spinner / check /
/// alert), satisfying "never rely on color alone".
class AppNoteListTile extends StatelessWidget {
  const AppNoteListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.status,
    required this.index,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final AudioNoteStatus status;
  final int index;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);
    final shape = BorderRadius.circular(AppTokens.radiusLg);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: shape,
        splashFactory: InkRipple.splashFactory,
        splashColor: t.primary.withValues(alpha: 0.10),
        highlightColor: t.primary.withValues(alpha: 0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: t.surfaceContainerLowest,
            borderRadius: shape,
            border: Border.all(color: t.ghostBorder(0.14)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppTapTarget.minSize),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: t.onSurfaceVariant,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusIndicator(status: status),
                  if (trailing != null) ...[
                    const SizedBox(width: 4),
                    trailing!,
                  ],
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: t.onSurfaceVariant.withValues(alpha: 0.45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status});

  final AudioNoteStatus status;

  @override
  Widget build(BuildContext context) {
    final color = audioNoteStatusColor(context, status);

    if (status.isPendingPipeline) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }

    if (status == AudioNoteStatus.completed) {
      return Icon(Icons.check_circle_outline_rounded, size: 18, color: color);
    }

    if (status == AudioNoteStatus.failed) {
      return Icon(Icons.error_outline_rounded, size: 18, color: color);
    }

    return const SizedBox.shrink();
  }
}

// ── Backwards-compatible alias ────────────────────────────────────────────

/// Alias for [AppNoteListTile]. Prefer the new name in new code.
class ObsidianNoteListTile extends StatelessWidget {
  const ObsidianNoteListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.status,
    required this.index,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final AudioNoteStatus status;
  final int index;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => AppNoteListTile(
    title: title,
    subtitle: subtitle,
    onTap: onTap,
    status: status,
    index: index,
    trailing: trailing,
  );
}
