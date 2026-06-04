/// Removes `ts_headline` markup (`<b>`, etc.) from Postgres search snippets.
String stripTsHeadlineHtml(String input) {
  return input
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .trim();
}

/// Builds a short excerpt around the first case-insensitive [query] match.
String? buildTranscriptExcerpt({
  required String transcript,
  required String query,
  int radius = 40,
}) {
  final trimmedQuery = query.trim();
  if (trimmedQuery.isEmpty || transcript.isEmpty) {
    return null;
  }

  final lowerTranscript = transcript.toLowerCase();
  final lowerQuery = trimmedQuery.toLowerCase();
  final index = lowerTranscript.indexOf(lowerQuery);
  if (index < 0) {
    return null;
  }

  final start = (index - radius).clamp(0, transcript.length);
  final end = (index + trimmedQuery.length + radius).clamp(0, transcript.length);
  final slice = transcript.substring(start, end).trim();

  final prefix = start > 0 ? '…' : '';
  final suffix = end < transcript.length ? '…' : '';
  return '$prefix$slice$suffix';
}
