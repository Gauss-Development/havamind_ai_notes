/// Ranks items by matching a query against title and optional extra text fields.
///
/// Scoring tiers (highest wins):
///   - 400+ exact title match
///   - 300+ title starts with query
///   - 200+ word in title starts with query
///   - 100+ query appears anywhere in title
///   - 50+  query appears in extra text (summary, transcript, etc.)
class RankItemsByTitleUseCase {
  const RankItemsByTitleUseCase();

  List<T> call<T>({
    required List<T> items,
    required String query,
    required String Function(T item) titleOf,
    required DateTime Function(T item) createdAtOf,
    List<String> Function(T item)? extraTextOf,
    int? limit,
  }) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return <T>[];
    }

    final scored = items
        .map(
          (item) => _ScoredItem<T>(
            item: item,
            score: _scoreItem(
              title: titleOf(item),
              query: normalizedQuery,
              extraTexts: extraTextOf?.call(item),
            ),
          ),
        )
        .where((entry) => entry.score > 0)
        .toList();

    scored.sort((a, b) {
      final scoreSort = b.score.compareTo(a.score);
      if (scoreSort != 0) return scoreSort;

      final dateSort = createdAtOf(b.item).compareTo(createdAtOf(a.item));
      if (dateSort != 0) return dateSort;

      return titleOf(a.item)
          .toLowerCase()
          .compareTo(titleOf(b.item).toLowerCase());
    });

    final ranked = scored.map((entry) => entry.item).toList(growable: false);
    if (limit == null || limit >= ranked.length) return ranked;
    return ranked.take(limit).toList(growable: false);
  }

  int _scoreItem({
    required String title,
    required String query,
    List<String>? extraTexts,
  }) {
    final titleScore = _scoreTitleMatch(title, query);
    if (titleScore > 0) return titleScore;

    if (extraTexts != null) {
      for (final text in extraTexts) {
        if (_normalize(text).contains(query)) {
          return 50 + query.length;
        }
      }
    }

    return 0;
  }

  int _scoreTitleMatch(String title, String normalizedQuery) {
    final normalizedTitle = _normalize(title);
    if (normalizedTitle.isEmpty) return 0;

    if (normalizedTitle == normalizedQuery) {
      return 400 + normalizedQuery.length;
    }

    if (normalizedTitle.startsWith(normalizedQuery)) {
      return 300 + normalizedQuery.length;
    }

    final words = normalizedTitle
        .split(RegExp(r'[^a-z0-9а-яё]+'))
        .where((word) => word.isNotEmpty);
    if (words.any((word) => word.startsWith(normalizedQuery)) ||
        normalizedTitle.contains(' $normalizedQuery')) {
      return 200 + normalizedQuery.length;
    }

    if (normalizedTitle.contains(normalizedQuery)) {
      return 100 + normalizedQuery.length;
    }

    return 0;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}

class _ScoredItem<T> {
  const _ScoredItem({required this.item, required this.score});

  final T item;
  final int score;
}
