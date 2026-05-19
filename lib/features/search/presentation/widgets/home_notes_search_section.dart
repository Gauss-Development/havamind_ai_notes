import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';

typedef OpenNoteById = Future<void> Function(String noteId);
typedef SearchNotesFn = Future<List<AudioNote>> Function(String query);

class HomeNotesSearchSection extends StatefulWidget {
  const HomeNotesSearchSection({
    super.key,
    required this.notesCount,
    required this.onSearch,
    required this.onOpenNote,
  });

  /// Total notes the user owns (may be `null` until the count resolves).
  /// Used only for the input placeholder.
  final int? notesCount;

  /// Called every time the (debounced, non-empty) query changes. Must
  /// return matching notes; the caller is responsible for ranking/limits.
  final SearchNotesFn onSearch;

  final OpenNoteById onOpenNote;

  @override
  State<HomeNotesSearchSection> createState() => _HomeNotesSearchSectionState();
}

class _HomeNotesSearchSectionState extends State<HomeNotesSearchSection> {
  static const int _suggestionsLimit = 5;
  static const Duration _debounceDuration = Duration(milliseconds: 280);

  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  Timer? _debounceTimer;
  String _query = '';

  // Async search state. `_results` stays null until the first response
  // for the active query lands; `_isSearching` flips on while we wait so
  // the suggestion panel can show a spinner instead of "no matches".
  List<AudioNote>? _results;
  bool _isSearching = false;
  String? _errorMessage;
  int _requestSeq = 0; // guards against out-of-order responses

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = _query.trim();
    final hasQuery = trimmedQuery.isNotEmpty;
    final allResults = _results ?? const <AudioNote>[];
    final matches = allResults.length <= _suggestionsLimit
        ? allResults
        : allResults.sublist(0, _suggestionsLimit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchBar(
          notesCount: widget.notesCount,
          controller: _searchController,
          focusNode: _searchFocusNode,
          onTapSearchBar: _requestSearchFocus,
          onTapOutside: _unfocusSearch,
          onChanged: _onQueryChanged,
          onClear: () {
            _searchController.clear();
            _onQueryChanged('');
            _requestSearchFocus();
          },
        ),
        if (hasQuery) ...[
          const SizedBox(height: AppSpacing.sm),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _SearchSuggestions(
              query: trimmedQuery,
              isLoading: _isSearching && _results == null,
              errorMessage: _errorMessage,
              results: matches,
              totalMatches: allResults.length,
              onOpenNote: widget.onOpenNote,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ] else
          const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  void _onQueryChanged(String value) {
    if (value == _query) return;
    setState(() => _query = value);

    _debounceTimer?.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      // Clearing the input shouldn't leave a stale spinner on screen.
      _requestSeq++;
      setState(() {
        _results = null;
        _isSearching = false;
        _errorMessage = null;
      });
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () => _runSearch(trimmed));
  }

  Future<void> _runSearch(String query) async {
    final seq = ++_requestSeq;
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });
    try {
      final list = await widget.onSearch(query);
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _results = list;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _errorMessage = e.toString();
        _isSearching = false;
        _results = null;
      });
    }
  }

  void _requestSearchFocus() {
    if (!_searchFocusNode.hasFocus) _searchFocusNode.requestFocus();
  }

  void _unfocusSearch() {
    if (_searchFocusNode.hasFocus) _searchFocusNode.unfocus();
  }
}

// ─── Search bar ──────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.notesCount,
    required this.controller,
    required this.focusNode,
    required this.onTapSearchBar,
    required this.onTapOutside,
    required this.onChanged,
    required this.onClear,
  });

  final int? notesCount;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTapSearchBar;
  final VoidCallback onTapOutside;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final barRadius = BorderRadius.circular(ObsidianUiTokens.radiusFull);
    final hintStyle = theme.textTheme.bodyMedium?.copyWith(
      color: t.onSurfaceVariant.withValues(alpha: 0.55),
    );

    // Listen locally to focus + controller so the parent section never has to
    // rebuild on focus or text changes. This keeps the (potentially large)
    // suggestions tree and the home page scroll view stable per keystroke.
    return ListenableBuilder(
      listenable: Listenable.merge([focusNode, controller]),
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final hasValue = controller.text.trim().isNotEmpty;
        final count = notesCount;
        final hint = (count == null || count == 0)
            ? 'Search your notes...'
            : 'Search $count notes...';

        return GestureDetector(
          onTap: onTapSearchBar,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            decoration: BoxDecoration(
              color: t.surfaceContainerLow,
              borderRadius: barRadius,
              border: Border.all(
                color: focused
                    ? t.primary.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: focused ? t.primary : t.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Semantics(
                    label: 'Search notes by title',
                    textField: true,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onTap: onTapSearchBar,
                      onChanged: onChanged,
                      onTapOutside: (_) => onTapOutside(),
                      textInputAction: TextInputAction.search,
                      cursorColor: t.primary,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: hint,
                        hintStyle: hintStyle,
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: hasValue
                      ? IconButton(
                          key: const ValueKey('clear_search'),
                          onPressed: onClear,
                          tooltip: 'Clear search',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: AppTapTarget.minSize,
                            minHeight: AppTapTarget.minSize,
                          ),
                          icon: Icon(
                            Icons.cancel_rounded,
                            size: 20,
                            color: t.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('no_clear')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Search suggestions ──────────────────────────────────────────────────────

class _SearchSuggestions extends StatelessWidget {
  const _SearchSuggestions({
    required this.query,
    required this.isLoading,
    required this.errorMessage,
    required this.results,
    required this.totalMatches,
    required this.onOpenNote,
  });

  final String query;
  final bool isLoading;
  final String? errorMessage;
  final List<AudioNote> results;
  final int totalMatches;
  final OpenNoteById onOpenNote;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: t.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
        border: Border.all(color: t.ghostBorder(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Results', style: theme.textTheme.titleSmall),
                const Spacer(),
                if (isLoading)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: t.primary,
                    ),
                  )
                else if (totalMatches > 0)
                  Text(
                    '$totalMatches found',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: t.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (errorMessage != null)
              _SuggestionsMessage(
                icon: Icons.error_outline_rounded,
                title: 'Search failed',
                subtitle: errorMessage!,
              )
            else if (isLoading && results.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (results.isEmpty)
              const _SuggestionsMessage(
                icon: Icons.search_off_rounded,
                title: 'No matches found',
                subtitle: 'Try a shorter phrase or check spelling.',
              )
            else
              Column(
                children: [
                  for (var i = 0; i < results.length; i++) ...[
                    _SearchSuggestionTile(
                      note: results[i],
                      query: query,
                      onOpenNote: onOpenNote,
                    ),
                    if (i < results.length - 1)
                      const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsMessage extends StatelessWidget {
  const _SuggestionsMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: t.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SearchSuggestionTile extends StatelessWidget {
  const _SearchSuggestionTile({
    required this.note,
    required this.query,
    required this.onOpenNote,
  });

  // One DateFormat per class load instead of one per tile build. Suggestion
  // tiles are rebuilt on every keystroke; cumulative cost matters here.
  static final _dateFmt = DateFormat.MMMd();

  final AudioNote note;
  final String query;
  final OpenNoteById onOpenNote;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final baseTitleStyle = theme.textTheme.titleSmall!;
    final matchStyle = baseTitleStyle.copyWith(
      color: t.primary,
      backgroundColor: t.primaryContainer.withValues(alpha: 0.35),
    );
    final dateStr = _dateFmt.format(note.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusSm),
        onTap: () => onOpenNote(note.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(ObsidianUiTokens.radiusSm),
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  size: 18,
                  color: t.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: baseTitleStyle,
                        children: _highlightTitleSpans(
                          title: note.title,
                          query: query,
                          matchStyle: matchStyle,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateStr · ${_statusLabel(note.status)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: t.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

List<TextSpan> _highlightTitleSpans({
  required String title,
  required String query,
  required TextStyle matchStyle,
}) {
  final q = query.trim();
  if (q.isEmpty) return [TextSpan(text: title)];

  final lowerTitle = title.toLowerCase();
  final lowerQ = q.toLowerCase();
  final idx = lowerTitle.indexOf(lowerQ);
  if (idx < 0) return [TextSpan(text: title)];

  final end = idx + q.length;
  return [
    TextSpan(text: title.substring(0, idx)),
    TextSpan(text: title.substring(idx, end), style: matchStyle),
    TextSpan(text: title.substring(end)),
  ];
}

String _statusLabel(AudioNoteStatus status) {
  switch (status) {
    case AudioNoteStatus.completed:
      return 'Ready';
    case AudioNoteStatus.failed:
      return 'Needs attention';
    case AudioNoteStatus.processingTranscription:
    case AudioNoteStatus.processingAnalysis:
    case AudioNoteStatus.uploaded:
      return 'Processing';
    case AudioNoteStatus.draft:
      return 'Draft';
  }
}
