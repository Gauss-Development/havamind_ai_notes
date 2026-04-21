/// Ranks items by matching a query against title and optional extra text fields.
///
/// Scoring tiers (highest wins):
///   - 400+ exact title match
///   - 300+ title starts with query
///   - 200+ word in title starts with query
///   - 100+ query appears anywhere in title
///   - 50+  query appears in extra text (summary, transcript, etc.)
///
/// Performance contract: each item is normalized exactly once. Callers that
/// rebuild on every keystroke should additionally memoize the result (the use
/// case itself is stateless and does not cache across calls).
class RankItemsByTitleUseCase {
  const RankItemsByTitleUseCase();

  static final RegExp _wordSeparator = RegExp(r'[^a-z0-9а-яё]+');

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

    final scored = <_ScoredItem<T>>[];
    for (final item in items) {
      final normalizedTitle = _normalize(titleOf(item));
      final titleScore = _scoreTitleMatch(normalizedTitle, normalizedQuery);

      var score = titleScore;
      if (score == 0 && extraTextOf != null) {
        final extras = extraTextOf(item);
        for (final text in extras) {
          if (_normalize(text).contains(normalizedQuery)) {
            score = 50 + normalizedQuery.length;
            break;
          }
        }
      }

      if (score > 0) {
        scored.add(
          _ScoredItem<T>(
            item: item,
            score: score,
            normalizedTitle: normalizedTitle,
          ),
        );
      }
    }

    scored.sort((a, b) {
      final scoreSort = b.score.compareTo(a.score);
      if (scoreSort != 0) return scoreSort;

      final dateSort = createdAtOf(b.item).compareTo(createdAtOf(a.item));
      if (dateSort != 0) return dateSort;

      return a.normalizedTitle.compareTo(b.normalizedTitle);
    });

    final effectiveLimit = (limit == null || limit >= scored.length)
        ? scored.length
        : limit;

    final ranked = List<T>.generate(
      effectiveLimit,
      (i) => scored[i].item,
      growable: false,
    );
    return ranked;
  }

  int _scoreTitleMatch(String normalizedTitle, String normalizedQuery) {
    if (normalizedTitle.isEmpty) return 0;

    if (normalizedTitle == normalizedQuery) {
      return 400 + normalizedQuery.length;
    }

    if (normalizedTitle.startsWith(normalizedQuery)) {
      return 300 + normalizedQuery.length;
    }

    // Word-prefix match: cheaper to scan once than to allocate the split list,
    // but split() avoids a custom state machine and is already O(n) over the
    // string. The regex is hoisted so it isn't recompiled per item.
    if (normalizedTitle.contains(' $normalizedQuery')) {
      return 200 + normalizedQuery.length;
    }
    final words = normalizedTitle.split(_wordSeparator);
    for (final word in words) {
      if (word.isNotEmpty && word.startsWith(normalizedQuery)) {
        return 200 + normalizedQuery.length;
      }
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
  const _ScoredItem({
    required this.item,
    required this.score,
    required this.normalizedTitle,
  });

  final T item;
  final int score;
  final String normalizedTitle;
}
